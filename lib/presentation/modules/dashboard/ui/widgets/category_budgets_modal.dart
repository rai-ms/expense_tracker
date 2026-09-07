import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/base/bloc_base/bloc_event_state.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../bloc/dashboard_bloc.dart';

/// Modal bottom sheet for viewing, setting, and managing per-category monthly spending budgets
class CategoryBudgetsModal extends StatefulWidget {
  final DashboardBloc bloc;
  final DashboardData data;

  const CategoryBudgetsModal({
    super.key,
    required this.bloc,
    required this.data,
  });

  static Future<void> show({
    required BuildContext context,
    required DashboardBloc bloc,
    required DashboardData data,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryBudgetsModal(bloc: bloc, data: data),
    );
  }

  @override
  State<CategoryBudgetsModal> createState() => _CategoryBudgetsModalState();
}

class _CategoryBudgetsModalState extends State<CategoryBudgetsModal> {
  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  void _openSetBudgetDialog(String category, double? currentBudget) {
    final controller = TextEditingController(
      text: (currentBudget != null && currentBudget > 0) ? currentBudget.toInt().toString() : '',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catMeta = AppConstants.getCategory(category);
    final catColor = catMeta['color'] as Color? ?? AppColors.primary;
    final catIcon = catMeta['icon'] as IconData? ?? Icons.category_rounded;

    const presets = [2000.0, 5000.0, 8000.0, 10000.0, 15000.0, 25000.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(catIcon, color: catColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentBudget != null ? 'Edit $category Budget' : 'Set $category Budget',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Alerts will notify you at 80% & 100% of this limit',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              decoration: const InputDecoration(
                                hintText: '5000',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Preset Chips
                    const Text(
                      'Quick Presets',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((amt) {
                        final isSelected = double.tryParse(controller.text) == amt;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              controller.text = amt.toInt().toString();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? catColor.withValues(alpha: 0.2)
                                  : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? catColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _currency.format(amt),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? catColor : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        if (currentBudget != null) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                widget.bloc.add(DeleteCategoryBudgetEvent(category));
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Removed budget for $category')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.debitRed,
                                side: const BorderSide(color: AppColors.debitRed),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Remove Limit', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              final amount = double.tryParse(text);
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid amount')),
                                );
                                return;
                              }
                              widget.bloc.add(SetCategoryBudgetEvent(category: category, amount: amount));
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Monthly budget for $category set to ${_currency.format(amount)}'),
                                  backgroundColor: AppColors.creditGreen,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: catColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Save Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allCategories = AppConstants.getAllCategories();

    return BlocBuilder<DashboardBloc, BlocEventState<DashboardData>>(
      bloc: widget.bloc,
      builder: (context, state) {
        final currentData = state.data ?? widget.data;
        final categoryBudgets = currentData.categoryBudgets;
        final categoryBreakdown = currentData.categoryBreakdown;
        final totalAllocated = currentData.totalAllocatedCategoryBudget;
        final monthlyBudget = currentData.monthlyBudget;
        final warningCount = currentData.warningOrExceededBudgets.length;

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 0.8,
              ),
            ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.speed_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category Budgets',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Monthly spending limits & overspend alerts',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Summary Overview Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: warningCount > 0
                        ? AppColors.debitRed.withValues(alpha: 0.3)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Allocated Limit',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currency.format(totalAllocated),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Overall Budget: ${_currency.format(monthlyBudget)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: warningCount > 0
                            ? AppColors.debitRed.withValues(alpha: 0.15)
                            : AppColors.creditGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            warningCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                            color: warningCount > 0 ? AppColors.debitRed : AppColors.creditGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            warningCount > 0 ? '$warningCount Alert${warningCount > 1 ? 's' : ''}' : 'On Track',
                            style: TextStyle(
                              color: warningCount > 0 ? AppColors.debitRed : AppColors.creditGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 1),

            // Category List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                itemCount: allCategories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cat = allCategories[index];
                  final catName = cat['name'] as String;
                  final catColor = cat['color'] as Color? ?? AppColors.primary;
                  final catIcon = cat['icon'] as IconData? ?? Icons.category_rounded;

                  final budget = categoryBudgets[catName];
                  final spent = categoryBreakdown[catName] ?? 0.0;

                  final hasBudget = budget != null && budget > 0;
                  final ratio = hasBudget ? (spent / budget) : 0.0;
                  final progress = ratio.clamp(0.0, 1.0);
                  final percent = (ratio * 100).round();

                  final Color barColor = percent >= 100
                      ? AppColors.debitRed
                      : percent >= 75
                          ? AppColors.warningAmber
                          : AppColors.creditGreen;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (hasBudget && percent >= 100)
                            ? AppColors.debitRed.withValues(alpha: 0.5)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: (hasBudget && percent >= 100) ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(catIcon, color: catColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    catName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasBudget
                                        ? '${_currency.format(spent)} of ${_currency.format(budget)}'
                                        : (spent > 0 ? 'Spent: ${_currency.format(spent)} (No limit)' : 'No limit set'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: hasBudget && percent >= 100 ? AppColors.debitRed : AppColors.textSecondaryDark,
                                      fontWeight: hasBudget && percent >= 100 ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasBudget) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: barColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$percent%',
                                  style: TextStyle(
                                    color: barColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            IconButton(
                              onPressed: () => _openSetBudgetDialog(catName, budget),
                              icon: Icon(
                                hasBudget ? Icons.edit_outlined : Icons.add_circle_outline_rounded,
                                color: hasBudget ? AppColors.primaryLight : AppColors.creditGreen,
                                size: 20,
                              ),
                              tooltip: hasBudget ? 'Edit Limit' : 'Set Limit',
                            ),
                          ],
                        ),
                        if (hasBudget) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(barColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                percent >= 100
                                    ? '🚨 Exceeded by ${_currency.format(spent - budget)}'
                                    : '${_currency.format((budget - spent).clamp(0.0, double.infinity))} remaining',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: barColor,
                                ),
                              ),
                              if (percent >= 80 && percent < 100)
                                const Text(
                                  'Near Limit ⚠️',
                                  style: TextStyle(fontSize: 11, color: AppColors.warningAmber, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}
