import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/services/budget_service/budget_service.dart';

/// Interactive Dashboard section displaying Category Spend Meters and budget progress
class CategorySpendMetersSection extends StatelessWidget {
  final List<CategoryBudgetStatus> budgetStatuses;
  final Map<String, double> categoryBreakdown;
  final VoidCallback onManageBudgets;

  const CategorySpendMetersSection({
    super.key,
    required this.budgetStatuses,
    required this.categoryBreakdown,
    required this.onManageBudgets,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final warningCount = budgetStatuses.where((s) => s.isWarning || s.isExceeded).length;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder, width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: AppColors.primaryLight, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Category Budgets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (warningCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.debitRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$warningCount alert${warningCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: onManageBudgets,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        budgetStatuses.isEmpty ? 'Set Limits' : 'Manage',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primaryLight),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (budgetStatuses.isNotEmpty) ...[
            // List of configured category budgets
            ...budgetStatuses.take(4).map((status) {
              final catMeta = AppConstants.getCategory(status.category);
              final catIcon = catMeta['icon'] as IconData? ?? Icons.category_rounded;
              final catColor = catMeta['color'] as Color? ?? AppColors.primary;

              Color meterColor;
              String statusText;
              if (status.level == BudgetAlertLevel.exceeded) {
                meterColor = AppColors.debitRed;
                statusText = '🚨 Over by ${currency.format(status.overspendAmount)}';
              } else if (status.level == BudgetAlertLevel.warning) {
                meterColor = AppColors.warningAmber;
                statusText = '⚠️ ${status.percentage}% (${currency.format(status.remainingAmount)} left)';
              } else {
                meterColor = AppColors.creditGreen;
                statusText = '${status.percentage}% (${currency.format(status.remainingAmount)} left)';
              }

              return InkWell(
                onTap: onManageBudgets,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status.isExceeded
                        ? AppColors.debitRed.withValues(alpha: 0.08)
                        : isDark
                            ? AppColors.darkSurfaceVariant.withValues(alpha: 0.4)
                            : AppColors.lightSurfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: status.isExceeded
                          ? AppColors.debitRed.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(catIcon, color: catColor, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.category,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currency.format(status.spentAmount)} of ${currency.format(status.budgetAmount)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: meterColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: status.progress,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(meterColor),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (budgetStatuses.length > 4) ...[
              Center(
                child: TextButton(
                  onPressed: onManageBudgets,
                  child: Text(
                    'View all ${budgetStatuses.length} category budgets →',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Empty state: Guide user to set category budgets
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant.withValues(alpha: 0.3)
                    : AppColors.lightSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Category Budgets Set Yet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set monthly spending limits for Food, Shopping, Fuel, etc. SpendWise will track consumption and trigger alerts at 80% and 100%!',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onManageBudgets,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Set Category Spending Limits'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
