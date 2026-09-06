import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/sms_sync_service/sms_sync_service.dart';
import '../controller/sms_simulator_controller.dart';

class SmsSimulatorView
    extends WidgetView<SmsSimulatorView, SmsSimulatorControllerState> {
  const SmsSimulatorView(super.ctr, {super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final parsed = ctr.liveParsedResult;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Smart SMS Simulator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: ctr.injectAllSampleTransactions,
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            label: const Text('Load Demo Data'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paste any Bank / UPI SMS below or pick a preset template to test real-time parsing accuracy!',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimaryDark, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sample Template Pills
            const Text(
              'Quick Indian Bank / UPI Templates:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: SmsSyncService.sampleSmsTemplates.map((template) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(template['title']!),
                      onPressed: () => ctr.selectTemplate(template),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Sender Field
            TextField(
              controller: ctr.senderController,
              decoration: const InputDecoration(
                labelText: 'SMS Sender Header (e.g. HDFCBK, SBIN, PHONEPE)',
              ),
            ),
            const SizedBox(height: 16),

            // SMS Body Input
            TextField(
              controller: ctr.smsInputController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'SMS Message Text',
                hintText: 'Paste raw bank/UPI SMS here...',
              ),
            ),
            const SizedBox(height: 24),

            // Live Parsing Card
            const Text(
              'Real-Time Parser Output:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (parsed == null || !parsed.isValidTransaction)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: const Center(
                  child: Text(
                    'No financial transaction detected in text above.',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
                  ),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: parsed.type == 'debit' ? AppColors.debitRed : AppColors.creditGreen,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: parsed.type == 'debit'
                                    ? AppColors.debitRed.withValues(alpha: 0.15)
                                    : AppColors.creditGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                parsed.type.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: parsed.type == 'debit' ? AppColors.debitRed : AppColors.creditGreen,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.darkSurfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                parsed.category,
                                style: const TextStyle(fontSize: 11, color: AppColors.textPrimaryDark),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          currency.format(parsed.amount),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: parsed.type == 'debit' ? AppColors.debitRed : AppColors.creditGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.darkBorder),
                    const SizedBox(height: 8),
                    _buildParsedRow('Merchant / Payee', parsed.merchant ?? '-'),
                    _buildParsedRow('Platform / Bank', parsed.platform ?? '-'),
                    _buildParsedRow('Transaction ID / UTR', parsed.transactionId ?? '-'),
                    _buildParsedRow('Account / Card ending', parsed.accountOrCard != null ? '**${parsed.accountOrCard}' : '-'),
                    if (parsed.balanceAfter != null)
                      _buildParsedRow('Extracted Available Balance', currency.format(parsed.balanceAfter!)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: ctr.addParsedTransactionToDb,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Parsed Transaction to Database'),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
