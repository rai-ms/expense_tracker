import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/base/logger/app_logger.dart';
import '../../../../core/services/di/injection.dart';
import '../../../../core/services/event_bus/app_events.dart';
import '../../../../core/services/pdf_export_service/pdf_export_service.dart';
import '../../../../data/models/khata_contact_entity.dart';
import '../../../../data/models/khata_entry_entity.dart';
import '../../../../domain/repositories/i_khata_repository.dart';
import '../../khata/ui/widgets/add_entry_modal.dart';
import '../ui/khata_detail_view.dart';

class KhataDetailController extends StatefulWidget {
  final int contactId;

  const KhataDetailController({
    super.key,
    required this.contactId,
  });

  @override
  State<KhataDetailController> createState() => KhataDetailControllerState();
}

class KhataDetailControllerState extends State<KhataDetailController>
    with _KhataDetailMixin {
  late final IKhataRepository _khataRepo;
  KhataContactEntity? contact;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _khataRepo = sl<IKhataRepository>();
    loadContact();
    AppEvents.syncNotifier.addListener(_onSyncData);
  }

  @override
  void dispose() {
    AppEvents.syncNotifier.removeListener(_onSyncData);
    super.dispose();
  }

  void _onSyncData() {
    if (mounted) {
      loadContact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KhataDetailView(this);
  }
}

mixin _KhataDetailMixin on State<KhataDetailController> {
  KhataDetailControllerState get _state => this as KhataDetailControllerState;

  void loadContact() {
    setState(() {
      _state.contact = _state._khataRepo.getContactById(widget.contactId);
      _state.isLoading = false;
    });
  }

  void onAddGaveEntry() {
    if (_state.contact == null) return;
    _showAddEntryModal(initialType: 'gave');
  }

  void onAddGotEntry() {
    if (_state.contact == null) return;
    _showAddEntryModal(initialType: 'got');
  }

  void _showAddEntryModal({required String initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddEntryModal(
        contact: _state.contact!,
        initialType: initialType,
        onSave: (entry) {
          _state._khataRepo.addEntry(_state.contact!.id, entry);
          AppEvents.notifyDataChanged();
          loadContact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                initialType == 'gave'
                    ? 'Entry added: You Gave ₹${entry.amount.toStringAsFixed(0)}'
                    : 'Entry added: You Got ₹${entry.amount.toStringAsFixed(0)}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void onSettleAccount() {
    if (_state.contact == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle Account?'),
        content: Text(
          'Mark all outstanding transactions with ${_state.contact!.name} as settled?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _state._khataRepo.settleAllEntriesForContact(_state.contact!.id);
              AppEvents.notifyDataChanged();
              loadContact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All entries settled with ${_state.contact!.name}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Settle All'),
          ),
        ],
      ),
    );
  }

  void onDeleteEntry(KhataEntryEntity entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
          'Delete transaction of ₹${entry.amount.toStringAsFixed(0)} on ${entry.dateTime.day}/${entry.dateTime.month}/${entry.dateTime.year}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _state._khataRepo.deleteEntry(entry.id);
              AppEvents.notifyDataChanged();
              loadContact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entry deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void onDeleteContact() {
    if (_state.contact == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete ${_state.contact!.name} and all associated ledger entries?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _state._khataRepo.deleteContact(_state.contact!.id);
              AppEvents.notifyDataChanged();
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_state.contact!.name} deleted from Khata'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> onSendWhatsApp(double amount) async {
    if (_state.contact == null) return;
    final contact = _state.contact!;
    final phone = contact.phoneNumber?.replaceAll(RegExp(r'\D'), '') ?? '';
    final message =
        'Namaste ${contact.name}, this is a gentle reminder regarding the pending balance of ₹${amount.toStringAsFixed(0)} on our Khata ledger. Please settle at your earliest convenience.';

    final encodedMessage = Uri.encodeComponent(message);
    final urlString = phone.isNotEmpty
        ? 'https://wa.me/$phone?text=$encodedMessage'
        : 'https://wa.me/?text=$encodedMessage';

    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Log.w('Could not launch WhatsApp URL: $urlString');
      }
    } catch (e) {
      Log.e('Failed to open WhatsApp: $e');
    }
  }

  Future<void> onExportPdf() async {
    if (_state.contact == null) return;
    try {
      final pdf = await PdfExportService.generateKhataStatement(contact: _state.contact!);
      await PdfExportService.printOrSharePdf(pdf, '${_state.contact!.name}_khata_statement');
    } catch (e) {
      Log.e('PDF export failed: $e');
    }
  }
}
