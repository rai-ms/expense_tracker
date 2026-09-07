import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

import '../../../../../core/localization/app_localizations.dart';

class QuickActionBar extends StatelessWidget {
  final VoidCallback onSyncSms;
  final VoidCallback onAddExpense;
  final VoidCallback? onSplitBill;
  final VoidCallback onAddKhata;
  final VoidCallback onExportPdf;
  final VoidCallback onSmsSimulator;

  const QuickActionBar({
    super.key,
    required this.onSyncSms,
    required this.onAddExpense,
    this.onSplitBill,
    required this.onAddKhata,
    required this.onExportPdf,
    required this.onSmsSimulator,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildActionPill(
            icon: Icons.sync_rounded,
            label: context.tr('sync_sms'),
            color: AppColors.primary,
            onTap: onSyncSms,
          ),
          const SizedBox(width: 10),
          _buildActionPill(
            icon: Icons.add_circle_outline_rounded,
            label: context.tr('add_expense'),
            color: AppColors.debitRed,
            onTap: onAddExpense,
          ),
          if (onSplitBill != null) ...[
            const SizedBox(width: 10),
            _buildActionPill(
              icon: Icons.call_split_rounded,
              label: 'Split Bill',
              color: AppColors.secondary,
              onTap: onSplitBill!,
            ),
          ],
          const SizedBox(width: 10),
          _buildActionPill(
            icon: Icons.menu_book_rounded,
            label: context.tr('khata'),
            color: AppColors.creditGreen,
            onTap: onAddKhata,
          ),
          const SizedBox(width: 10),
          _buildActionPill(
            icon: Icons.picture_as_pdf_rounded,
            label: context.tr('export_pdf'),
            color: AppColors.bills,
            onTap: onExportPdf,
          ),
          const SizedBox(width: 10),
          _buildActionPill(
            icon: Icons.sms_outlined,
            label: 'SMS Simulator',
            color: AppColors.warningAmber,
            onTap: onSmsSimulator,
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
