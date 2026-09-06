import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/base/bloc_base/bloc_event_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/transactions_bloc.dart';
import '../controller/transactions_controller.dart';

class TransactionsView
    extends WidgetView<TransactionsView, TransactionsControllerState> {
  const TransactionsView(super.ctr, {super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'All Transactions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: ctr.onAddNewTransaction,
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Transaction',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<TransactionsBloc, BlocEventState<TransactionsData>>(
          bloc: ctr.bloc,
          builder: (context, state) {
            final data = state.data;
            final txns = data?.transactions ?? [];
            final selectedDateFilter = data?.dateFilter ?? TransactionDateFilter.thisMonth;
            final selectedCategory = data?.selectedCategory;

            return Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: TextField(
                    controller: ctr.searchController,
                    onChanged: ctr.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search merchant, UTR, notes...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: ctr.searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                ctr.searchController.clear();
                                ctr.onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

                // 1. Date Period Filter Bar
                Container(
                  height: 38,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildDateChip(
                        context: context,
                        label: 'This Month',
                        icon: Icons.calendar_today_rounded,
                        isSelected: selectedDateFilter == TransactionDateFilter.thisMonth,
                        onTap: () => ctr.onDateFilterChanged(TransactionDateFilter.thisMonth),
                      ),
                      const SizedBox(width: 8),
                      _buildDateChip(
                        context: context,
                        label: 'Last Month',
                        icon: Icons.history_rounded,
                        isSelected: selectedDateFilter == TransactionDateFilter.lastMonth,
                        onTap: () => ctr.onDateFilterChanged(TransactionDateFilter.lastMonth),
                      ),
                      const SizedBox(width: 8),
                      _buildDateChip(
                        context: context,
                        label: 'All Time',
                        icon: Icons.all_inclusive_rounded,
                        isSelected: selectedDateFilter == TransactionDateFilter.allTime,
                        onTap: () => ctr.onDateFilterChanged(TransactionDateFilter.allTime),
                      ),
                      const SizedBox(width: 8),
                      _buildDateChip(
                        context: context,
                        label: selectedDateFilter == TransactionDateFilter.custom
                            ? (data?.dateFilterLabel ?? 'Custom 📅')
                            : 'Custom 📅',
                        icon: Icons.date_range_rounded,
                        isSelected: selectedDateFilter == TransactionDateFilter.custom,
                        onTap: () => ctr.onDateFilterChanged(TransactionDateFilter.custom),
                      ),
                    ],
                  ),
                ),

                // 2. Type & Category Quick Filters Bar
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Type: All
                      _buildTypeFilterChip('All', 'all', data?.selectedType ?? 'all'),
                      const SizedBox(width: 6),
                      // Type: Expenses
                      _buildTypeFilterChip('💸 Expenses', 'debit', data?.selectedType ?? 'all'),
                      const SizedBox(width: 6),
                      // Type: Income
                      _buildTypeFilterChip('💰 Income', 'credit', data?.selectedType ?? 'all'),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 24, color: AppColors.darkBorder),
                      const SizedBox(width: 12),

                      // Category: All
                      FilterChip(
                        label: const Text('All Categories'),
                        selected: selectedCategory == null || selectedCategory.isEmpty,
                        onSelected: (val) {
                          if (val) ctr.onCategoryFilterChanged(null);
                        },
                      ),
                      const SizedBox(width: 6),

                      // Category items with icons
                      ...AppConstants.categories.map((cat) {
                        final name = cat['name'] as String;
                        final icon = cat['icon'] as IconData;
                        final color = cat['color'] as Color;
                        final isSelected = selectedCategory == name;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            avatar: Icon(icon, color: color, size: 16),
                            label: Text(name),
                            selected: isSelected,
                            selectedColor: color.withValues(alpha: 0.2),
                            onSelected: (val) {
                              ctr.onCategoryFilterChanged(val ? name : null);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // 3. Filter Metrics Summary Strip
                if (data != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkBorder.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primaryLight),
                            const SizedBox(width: 6),
                            Text(
                              '${txns.length} txns (${data.dateFilterLabel})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Exp: ${currency.format(data.totalExpense)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.debitRed,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Inc: ${currency.format(data.totalIncome)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.creditGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // 4. Transactions List
                Expanded(
                  child: state.isLoading && txns.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : txns.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 56,
                                    color: AppColors.textTertiaryDark.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No matching transactions found',
                                    style: TextStyle(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: ctr.onResetFilters,
                                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                                    label: const Text('Reset All Filters'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              physics: const BouncingScrollPhysics(),
                              itemCount: txns.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final txn = txns[index];
                                final isDebit = txn.isDebit;
                                final catMeta = AppConstants.getCategory(txn.category);
                                final catIcon = catMeta['icon'] as IconData;
                                final catColor = catMeta['color'] as Color;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => ctr.onTransactionTap(txn),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardTheme.color,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.darkBorder.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: catColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Icon(catIcon, color: catColor, size: 22),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  txn.merchant ?? (isDebit ? 'Expense' : 'Income'),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  dateFormat.format(txn.dateTime),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textTertiaryDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                (isDebit ? '- ' : '+ ') + currency.format(txn.amount),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: isDebit ? AppColors.debitRed : AppColors.creditGreen,
                                                ),
                                              ),
                                              if (txn.platform != null)
                                                Text(
                                                  txn.platform!,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.textSecondaryDark,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: ctr.onAddNewTransaction,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildDateChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.darkBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, String value, String current) {
    final isSelected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) ctr.onTypeFilterChanged(value);
      },
    );
  }
}
