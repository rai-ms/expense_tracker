import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/pdf_export_service/pdf_export_service.dart';
import '../../../../../data/models/khata_contact_entity.dart';
import '../../../../widgets/receipt_lightbox_modal.dart';

class KhataDetailModal extends StatelessWidget {
  final KhataContactEntity contact;
  final VoidCallback onAddEntry;
  final VoidCallback onSettleAll;
  final Function(KhataContactEntity, double) onSendWhatsApp;

  const KhataDetailModal({
    super.key,
    required this.contact,
    required this.onAddEntry,
    required this.onSettleAll,
    required this.onSendWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy');
    final netBalance = contact.netBalance;

    final entries = contact.entries.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact Header & Balance
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(contact.avatarColorValue),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (contact.phoneNumber != null)
                      Text(
                        contact.phoneNumber!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final pdf = await PdfExportService.generateKhataStatement(contact: contact);
                  await PdfExportService.printOrSharePdf(pdf, '${contact.name}_khata_statement');
                },
                icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.bills),
                tooltip: 'Export PDF Statement',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Balance Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: netBalance > 0
                  ? AppColors.creditGreen.withValues(alpha: 0.12)
                  : netBalance < 0
                      ? AppColors.debitRed.withValues(alpha: 0.12)
                      : AppColors.darkSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: netBalance > 0
                    ? AppColors.creditGreen.withValues(alpha: 0.3)
                    : netBalance < 0
                        ? AppColors.debitRed.withValues(alpha: 0.3)
                        : AppColors.darkBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      netBalance > 0
                          ? 'You will receive (Aapko milenge)'
                          : netBalance < 0
                              ? 'You will give (Aapko dene hain)'
                              : 'All Settled',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(netBalance.abs()),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: netBalance > 0
                            ? AppColors.creditGreen
                            : netBalance < 0
                                ? AppColors.debitRed
                                : AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
                if (netBalance > 0)
                  ElevatedButton.icon(
                    onPressed: () => onSendWhatsApp(contact, netBalance),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.creditGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  )
                else if (netBalance != 0)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onSettleAll();
                    },
                    child: const Text('Settle Account'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Entries List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ledger History (${entries.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onAddEntry();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Entry'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Entries
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text('No transactions with this contact yet', style: TextStyle(color: AppColors.textSecondaryDark)),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isGave = entry.isGave;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isGave
                                    ? AppColors.debitRed.withValues(alpha: 0.15)
                                    : AppColors.creditGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isGave ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: isGave ? AppColors.debitRed : AppColors.creditGreen,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isGave ? 'You Gave (Maine Diye)' : 'You Got (Mujhe Mile)',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  if (entry.notes != null)
                                    Text(
                                      entry.notes!,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                                    ),
                                  Text(
                                    dateFormat.format(entry.dateTime),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiaryDark),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  (isGave ? '- ' : '+ ') + currency.format(entry.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isGave ? AppColors.debitRed : AppColors.creditGreen,
                                  ),
                                ),
                                if (entry.hasReceipt) ...[
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      ReceiptLightboxModal.show(
                                        context: context,
                                        receiptPath: entry.receiptPath!,
                                        title: '${contact.name} (${currency.format(entry.amount)})',
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.attach_file_rounded, size: 12, color: AppColors.primary),
                                          SizedBox(width: 2),
                                          Text(
                                            'Bill',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
