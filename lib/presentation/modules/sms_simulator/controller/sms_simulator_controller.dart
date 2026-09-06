import 'package:flutter/material.dart';

import '../../../../core/services/di/injection.dart';
import '../../../../core/services/event_bus/app_events.dart';
import '../../../../core/services/sms_parser_service/sms_parser_service.dart';
import '../../../../core/services/sms_sync_service/sms_sync_service.dart';
import '../../../../data/models/transaction_entity.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../ui/sms_simulator_view.dart';

class SmsSimulatorController extends StatefulWidget {
  const SmsSimulatorController({super.key});

  @override
  State<SmsSimulatorController> createState() => SmsSimulatorControllerState();
}

class SmsSimulatorControllerState extends State<SmsSimulatorController>
    with _SmsSimulatorMixin {
  final TextEditingController smsInputController = TextEditingController();
  final TextEditingController senderController = TextEditingController(text: 'HDFCBK');

  ParsedSmsResult? liveParsedResult;

  @override
  void initState() {
    super.initState();
    smsInputController.addListener(_onTextChanged);
    _loadSample(SmsSyncService.sampleSmsTemplates.first);
  }

  @override
  void dispose() {
    smsInputController.removeListener(_onTextChanged);
    smsInputController.dispose();
    senderController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = smsInputController.text;
    if (text.trim().isNotEmpty) {
      setState(() {
        liveParsedResult = SmsParserService.parse(
          text,
          senderAddress: senderController.text,
        );
      });
    } else {
      setState(() {
        liveParsedResult = null;
      });
    }
  }

  void _loadSample(Map<String, String> sample) {
    senderController.text = sample['sender'] ?? 'BANK';
    smsInputController.text = sample['body'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SmsSimulatorView(this);
  }
}

mixin _SmsSimulatorMixin on State<SmsSimulatorController> {
  SmsSimulatorControllerState get _state => this as SmsSimulatorControllerState;

  void selectTemplate(Map<String, String> template) {
    _state._loadSample(template);
  }

  void addParsedTransactionToDb() {
    final parsed = _state.liveParsedResult;
    if (parsed == null || !parsed.isValidTransaction) return;

    final repo = sl<ITransactionRepository>();
    final txn = TransactionEntity(
      uid: parsed.uid,
      amount: parsed.amount,
      type: parsed.type,
      category: parsed.category,
      merchant: parsed.merchant,
      platform: parsed.platform,
      transactionId: parsed.transactionId,
      accountOrCard: parsed.accountOrCard,
      date: parsed.date.millisecondsSinceEpoch,
      rawSms: parsed.rawSms,
      balanceAfter: parsed.balanceAfter,
      isAutomated: true,
    );

    repo.addTransaction(txn);
    AppEvents.notifyDataChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved ₹${parsed.amount} (${parsed.merchant ?? parsed.category}) to transactions!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void injectAllSampleTransactions() {
    final repo = sl<ITransactionRepository>();
    int count = 0;
    for (final sample in SmsSyncService.sampleSmsTemplates) {
      final parsed = SmsParserService.parse(
        sample['body']!,
        senderAddress: sample['sender'],
      );
      if (parsed.isValidTransaction) {
        final txn = TransactionEntity(
          uid: parsed.uid,
          amount: parsed.amount,
          type: parsed.type,
          category: parsed.category,
          merchant: parsed.merchant,
          platform: parsed.platform,
          transactionId: parsed.transactionId,
          accountOrCard: parsed.accountOrCard,
          date: parsed.date.millisecondsSinceEpoch,
          rawSms: parsed.rawSms,
          balanceAfter: parsed.balanceAfter,
          isAutomated: true,
        );
        repo.addTransaction(txn);
        count++;
      }
    }

    if (count > 0) {
      AppEvents.notifyDataChanged();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully loaded $count sample transactions! Check Dashboard & Analytics.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
