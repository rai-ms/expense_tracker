import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';

import '../../../../../core/localization/app_localizations.dart';

class SpendMeter extends StatelessWidget {
  final double todaySpend;
  final double totalExpense;
  final double monthlyBudget;
  final VoidCallback? onEditBudget;
  final VoidCallback? onManageCategoryBudgets;
  final int warningOrExceededCount;

  const SpendMeter({
    super.key,
    required this.todaySpend,
    required this.totalExpense,
    required this.monthlyBudget,
    this.onEditBudget,
    this.onManageCategoryBudgets,
    this.warningOrExceededCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final progress = (totalExpense / monthlyBudget).clamp(0.0, 1.0);
    final percentage = ((totalExpense / monthlyBudget) * 100).toInt();

    final Color meterColor = percentage > 90
        ? AppColors.debitRed
        : percentage > 70
            ? AppColors.warningAmber
            : AppColors.creditGreen;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: meterColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.speed_rounded, color: meterColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('monthly_budget'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onEditBudget != null) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onEditBudget,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: onEditBudget,
                borderRadius: BorderRadius.circular(8),
                child: Text(
                  '$percentage% used',
                  style: TextStyle(
                    color: meterColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.darkSurfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(meterColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${context.tr('expense')}: ${currency.format(totalExpense)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              Text(
                '${context.tr('monthly_budget')}: ${currency.format(monthlyBudget)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('today_spend'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                ),
                Text(
                  currency.format(todaySpend),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (onManageCategoryBudgets != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onManageCategoryBudgets,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: warningOrExceededCount > 0
                      ? AppColors.debitRed.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: warningOrExceededCount > 0
                        ? AppColors.debitRed.withValues(alpha: 0.3)
                        : AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          warningOrExceededCount > 0 ? Icons.warning_amber_rounded : Icons.pie_chart_outline_rounded,
                          size: 16,
                          color: warningOrExceededCount > 0 ? AppColors.debitRed : AppColors.primaryLight,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Category Budgets',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: warningOrExceededCount > 0 ? AppColors.debitRed : AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (warningOrExceededCount > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.debitRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$warningOrExceededCount alert${warningOrExceededCount > 1 ? 's' : ''}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondaryDark),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
