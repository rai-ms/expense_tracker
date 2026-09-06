import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/base/bloc_base/bloc_event_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../blocs/transactions/transactions_bloc.dart';
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
      body: BlocBuilder<TransactionsBloc, BlocEventState<TransactionsData>>(
        bloc: ctr.bloc,
        builder: (context, state) {
          final data = state.data;
          final txns = data?.transactions ?? [];

          return Column(
            children: [
              // Search & Filter Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

              // Filter Chips: All, Expense, Income
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', data?.selectedType ?? 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expenses', 'debit', data?.selectedType ?? 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Income', 'credit', data?.selectedType ?? 'all'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Transactions List
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
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        onPressed: ctr.onAddNewTransaction,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current) {
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
