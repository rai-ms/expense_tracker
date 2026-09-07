import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/di/injection.dart';
import '../../../../../core/services/event_bus/app_events.dart';
import '../../../../../core/services/receipt_service/receipt_service.dart';
import '../../../../../core/services/sms_parser_service/ignored_rule_service.dart';
import '../../../../../data/models/transaction_entity.dart';
import '../../../../../domain/repositories/i_transaction_repository.dart';
import '../../../../widgets/receipt_lightbox_modal.dart';
import 'change_category_modal.dart';
import 'move_to_khata_modal.dart';
import '../../../khata/ui/widgets/split_bill_modal.dart';

class TransactionDetailModal extends StatefulWidget {
  final TransactionEntity transaction;
  final VoidCallback onDelete;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  State<TransactionDetailModal> createState() => _TransactionDetailModalState();
}

class _TransactionDetailModalState extends State<TransactionDetailModal> {
  String? _receiptPath;

  @override
  void initState() {
    super.initState();
    _receiptPath = widget.transaction.receiptPath;
  }

  Future<void> _attachReceipt(ImageSource source) async {
    final receiptService = sl<ReceiptService>();
    final path = await receiptService.pickAndSaveReceipt(source: source);
    if (path != null && mounted) {
      widget.transaction.receiptPath = path;
      sl<ITransactionRepository>().updateTransaction(widget.transaction);
      AppEvents.notifyDataChanged();
      setState(() {
        _receiptPath = path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt attached successfully 📎')),
      );
    }
  }

  Future<void> _removeReceipt() async {
    final receiptService = sl<ReceiptService>();
    await receiptService.deleteReceipt(_receiptPath);
    widget.transaction.receiptPath = null;
    sl<ITransactionRepository>().updateTransaction(widget.transaction);
    AppEvents.notifyDataChanged();
    if (mounted) {
      setState(() {
        _receiptPath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt removed')),
      );
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach Bill / Receipt Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                title: const Text('Take Photo with Camera'),
                subtitle: const Text('Snap paper bill or restaurant slip'),
                onTap: () {
                  Navigator.pop(ctx);
                  _attachReceipt(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  child: Icon(Icons.photo_library_rounded, color: Colors.white),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Upload bill photo or screenshot'),
                onTap: () {
                  Navigator.pop(ctx);
                  _attachReceipt(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');
    final isDebit = transaction.isDebit;

    final catMeta = AppConstants.getCategory(transaction.category);
    final catColor = catMeta['color'] as Color;
    final catIcon = catMeta['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),

            // Ignored notification banner
            if (transaction.isIgnored) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_off_outlined, color: AppColors.warningAmber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Marked as Notification Only (Ignored from expenses & balance)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warningAmber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                InkWell(
                  onTap: () => ChangeCategoryModal.show(
                    context: context,
                    transaction: transaction,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: catColor.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Icon(catIcon, color: catColor, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant ?? (isDebit ? 'Expense' : 'Income'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => ChangeCategoryModal.show(
                          context: context,
                          transaction: transaction,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                transaction.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: catColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit_rounded, size: 12, color: catColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  (isDebit ? '- ' : '+ ') + currency.format(transaction.amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDebit ? AppColors.debitRed : AppColors.creditGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: 16),

            // Details List
            _buildInfoRow('Date & Time', dateFormat.format(transaction.dateTime)),
            if (transaction.platform != null)
              _buildInfoRow('Platform / Bank', transaction.platform!),
            if (transaction.transactionId != null)
              _buildInfoRow('Transaction ID / UTR', transaction.transactionId!),
            if (transaction.accountOrCard != null)
              _buildInfoRow('Account / Card ending', '**${transaction.accountOrCard}'),
            if (transaction.balanceAfter != null)
              _buildInfoRow('Available Balance', currency.format(transaction.balanceAfter!)),
            if (transaction.isAutomated)
              _buildInfoRow('Source', 'Auto-synced via Bank SMS'),

            if (transaction.rawSms != null && transaction.rawSms!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Original SMS Message:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction.rawSms!,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark, height: 1.4),
                ),
              ),
            ],

            // Receipt Attachment Section
            if (_receiptPath != null && _receiptPath!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ReceiptLightboxModal.show(
                          context: context,
                          receiptPath: _receiptPath!,
                          title: transaction.merchant ?? transaction.notes ?? 'Receipt',
                          onDelete: _removeReceipt,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_receiptPath!),
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: 52,
                            height: 52,
                            color: Colors.white10,
                            child: const Icon(Icons.broken_image_rounded, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          ReceiptLightboxModal.show(
                            context: context,
                            receiptPath: _receiptPath!,
                            title: transaction.merchant ?? transaction.notes ?? 'Receipt',
                            onDelete: _removeReceipt,
                          );
                        },
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Receipt Attached 📎',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pinch-to-zoom & share photo',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.primaryLight),
                      tooltip: 'Share',
                      onPressed: () {
                        sl<ReceiptService>().shareReceipt(_receiptPath!, caption: transaction.merchant);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.debitRed),
                      tooltip: 'Remove',
                      onPressed: _removeReceipt,
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: const Text('Attach Receipt / Bill Photo 📸'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: AppColors.darkBorder),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Row 1: Move to Khata & Change Category
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Theme.of(context).cardTheme.color,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        builder: (_) => MoveToKhataModal(transaction: transaction),
                      );
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text('Move to Khata'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.khataBook,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ChangeCategoryModal.show(
                      context: context,
                      transaction: transaction,
                    ),
                    icon: const Icon(Icons.category_rounded, size: 18),
                    label: const Text('Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (transaction.isDebit) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    SplitBillModal.show(
                      context: context,
                      initialAmount: transaction.amount,
                      initialTitle: transaction.merchant ?? transaction.notes ?? 'Expense',
                      initialCategory: transaction.category,
                      existingTransactionId: transaction.id,
                    );
                  },
                  icon: const Icon(Icons.call_split_rounded, size: 18),
                  label: const Text('Split this Bill with Friends'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Action: Mark as Notification / Ignore SMS
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final repo = sl<ITransactionRepository>();
                  final ignoredService = sl<IgnoredRuleService>();
                  final newStatus = !transaction.isIgnored;

                  repo.toggleIgnoredStatus(transaction.id, newStatus);
                  if (newStatus && transaction.merchant != null && transaction.merchant!.isNotEmpty) {
                    await ignoredService.addIgnoredKeyword(transaction.merchant!);
                  }

                  AppEvents.notifyDataChanged();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          newStatus
                              ? 'Marked as notification only (Ignored from calculations)'
                              : 'Restored to active transactions',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: Icon(
                  transaction.isIgnored
                      ? Icons.check_circle_outline_rounded
                      : Icons.notifications_off_outlined,
                  size: 18,
                  color: transaction.isIgnored ? AppColors.creditGreen : AppColors.warningAmber,
                ),
                label: Text(
                  transaction.isIgnored
                      ? 'Unmark (Restore to Active Transactions)'
                      : 'Mark as Notification Only (Ignore SMS)',
                  style: TextStyle(
                    color: transaction.isIgnored ? AppColors.creditGreen : AppColors.warningAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: transaction.isIgnored ? AppColors.creditGreen : AppColors.warningAmber,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Delete Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.debitRed, size: 18),
                label: const Text('Delete Transaction', style: TextStyle(color: AppColors.debitRed)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.debitRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
