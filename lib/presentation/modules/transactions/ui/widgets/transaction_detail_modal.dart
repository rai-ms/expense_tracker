import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../data/models/transaction_entity.dart';
import 'move_to_khata_modal.dart';

class TransactionDetailModal extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback onDelete;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(catIcon, color: catColor, size: 28),
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
                    const SizedBox(height: 2),
                    Text(
                      transaction.category,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryDark,
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

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.debitRed, size: 18),
                  label: const Text('Delete', style: TextStyle(color: AppColors.debitRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.debitRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
