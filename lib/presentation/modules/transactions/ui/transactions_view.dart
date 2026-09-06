import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/base/bloc_base/bloc_event_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../bloc/transactions_bloc.dart';
import '../controller/transactions_controller.dart';

class TransactionsView
    extends WidgetView<TransactionsView, TransactionsControllerState> {
  const TransactionsView(super.ctr, {super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr('all_transactions'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: ctr.onOpenManageCategories,
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
          ),
          IconButton(
            onPressed: ctr.onAddNewTransaction,
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: context.tr('add_expense'),
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
            final criteria = data?.criteria ?? const TransactionFilterCriteria();
            final activeFilterCount = criteria.activeFilterCount;

            return Column(
              children: [
                // 1. Search Bar + E-Commerce Style Filter Trigger Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: TextField(
                          controller: ctr.searchController,
                          onChanged: ctr.onSearchChanged,
                          decoration: InputDecoration(
                            hintText: context.tr('search_transactions'),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: ctr.searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      ctr.searchController.clear();
                                      ctr.onSearchChanged('');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // E-Commerce Style Filter Button with Badge
                      InkWell(
                        onTap: ctr.onOpenFilterModal,
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: activeFilterCount > 0
                                ? AppColors.primary
                                : Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: activeFilterCount > 0
                                  ? AppColors.primaryLight
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: 1.2,
                            ),
                            boxShadow: activeFilterCount > 0
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
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
                                Icons.tune_rounded,
                                size: 18,
                                color: activeFilterCount > 0 ? Colors.white : AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                activeFilterCount > 0 ? 'Filters ($activeFilterCount)' : 'Filter',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: activeFilterCount > 0
                                      ? Colors.white
                                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Active Filter Pills Strip (If any filters applied)
                if (activeFilterCount > 0)
                  Container(
                    height: 36,
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Clear All Pill
                        InkWell(
                          onTap: ctr.onClearAllFilters,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.debitRed.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.debitRed.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close_rounded, size: 14, color: AppColors.debitRed),
                                SizedBox(width: 4),
                                Text(
                                  'Clear All',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.debitRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Date Filter Pill
                        if (criteria.dateFilter != TransactionDateFilter.thisMonth) ...[
                          _buildActiveFilterTag(
                            label: data?.dateFilterLabel ?? 'Date Range',
                            icon: Icons.calendar_month_outlined,
                            onRemove: () => ctr.onRemoveFilterTag('date'),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Type Filter Pills
                        ...criteria.types.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildActiveFilterTag(
                              label: t == 'debit'
                                  ? 'Expense'
                                  : t == 'credit'
                                      ? 'Income'
                                      : 'Notifications',
                              icon: t == 'debit'
                                  ? Icons.arrow_upward_rounded
                                  : t == 'credit'
                                      ? Icons.arrow_downward_rounded
                                      : Icons.notifications_off_outlined,
                              onRemove: () => ctr.onRemoveFilterTag('type', t),
                            ),
                          ),
                        ),

                        // Category Filter Pills
                        ...criteria.categories.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildActiveFilterTag(
                              label: cat,
                              icon: Icons.category_outlined,
                              onRemove: () => ctr.onRemoveFilterTag('category', cat),
                            ),
                          ),
                        ),

                        // Platform Filter Pills
                        ...criteria.platforms.map(
                          (plat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildActiveFilterTag(
                              label: plat,
                              icon: Icons.account_balance_wallet_outlined,
                              onRemove: () => ctr.onRemoveFilterTag('platform', plat),
                            ),
                          ),
                        ),

                        // Amount Filter Pill
                        if (criteria.minAmount != null || criteria.maxAmount != null) ...[
                          _buildActiveFilterTag(
                            label: _formatAmountRange(criteria.minAmount, criteria.maxAmount),
                            icon: Icons.currency_rupee_rounded,
                            onRemove: () => ctr.onRemoveFilterTag('amount'),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Sort Filter Pill
                        if (criteria.sortBy != TransactionSortBy.dateNewest) ...[
                          _buildActiveFilterTag(
                            label: _formatSortLabel(criteria.sortBy),
                            icon: Icons.sort_rounded,
                            onRemove: () => ctr.onRemoveFilterTag('sort'),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Strict Match Rule Pill (if not default flexible)
                        if (criteria.matchMode == FilterMatchMode.strict) ...[
                          _buildActiveFilterTag(
                            label: 'Strict (Match All)',
                            icon: Icons.tune_rounded,
                            onRemove: () => ctr.onRemoveFilterTag('mode'),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),

                // 3. Filter Metrics Summary Strip
                if (data != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.6)
                            : AppColors.lightBorder,
                      ),
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
                                    Icons.filter_alt_off_rounded,
                                    size: 56,
                                    color: AppColors.textTertiaryDark.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No transactions match selected filters',
                                    style: TextStyle(
                                      color: AppColors.textSecondaryDark,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: ctr.onClearAllFilters,
                                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                                    label: const Text('Reset All Filters'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                          color: isDark
                                              ? AppColors.darkBorder.withValues(alpha: 0.6)
                                              : AppColors.lightBorder,
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
                                                  color: txn.isIgnored
                                                      ? AppColors.textTertiaryDark
                                                      : isDebit
                                                          ? AppColors.debitRed
                                                          : AppColors.creditGreen,
                                                  decoration: txn.isIgnored
                                                      ? TextDecoration.lineThrough
                                                      : null,
                                                ),
                                              ),
                                              if (txn.isIgnored)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 2),
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.warningAmber.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Notification Only',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: AppColors.warningAmber,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              else if (txn.platform != null)
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

  Widget _buildActiveFilterTag({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _formatAmountRange(double? min, double? max) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    if (min != null && max != null) {
      return '${currency.format(min)} - ${currency.format(max)}';
    } else if (min != null) {
      return '> ${currency.format(min)}';
    } else if (max != null) {
      return '< ${currency.format(max)}';
    }
    return 'Amount';
  }

  String _formatSortLabel(TransactionSortBy sort) {
    switch (sort) {
      case TransactionSortBy.dateNewest:
        return 'Date: Newest';
      case TransactionSortBy.dateOldest:
        return 'Date: Oldest';
      case TransactionSortBy.amountHighToLow:
        return 'Amount: High to Low';
      case TransactionSortBy.amountLowToHigh:
        return 'Amount: Low to High';
    }
  }
}
