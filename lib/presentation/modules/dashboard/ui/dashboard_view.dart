import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/base/bloc_base/bloc_event_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../blocs/dashboard/dashboard_bloc.dart';
import '../controller/dashboard_controller.dart';
import 'widgets/balance_card.dart';
import 'widgets/quick_action_bar.dart';
import 'widgets/recent_transactions_list.dart';
import 'widgets/spend_meter.dart';

class DashboardView extends WidgetView<DashboardView, DashboardControllerState> {
  const DashboardView(super.ctr, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SpendWise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Real-time SMS & Khata',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: ctr.onSmsSimulator,
            icon: const Icon(Icons.science_outlined, color: AppColors.warningAmber),
            tooltip: 'SMS Simulator',
          ),
          IconButton(
            onPressed: ctr.onSyncSms,
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sync SMS',
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, BlocEventState<DashboardData>>(
        bloc: ctr.bloc,
        builder: (context, state) {
          if (state.isLoading && state.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = state.data;
          if (data == null) {
            return Center(
              child: Text(state.message ?? 'No data available'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ctr.bloc.add(LoadDashboardDataEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Filter Selector Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          context: context,
                          label: 'This Month',
                          icon: Icons.calendar_today_rounded,
                          isSelected: data.activeFilter == DashboardDateFilter.thisMonth,
                          onTap: () => ctr.onDateFilterChanged(DashboardDateFilter.thisMonth),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context: context,
                          label: 'Last Month',
                          icon: Icons.history_rounded,
                          isSelected: data.activeFilter == DashboardDateFilter.lastMonth,
                          onTap: () => ctr.onDateFilterChanged(DashboardDateFilter.lastMonth),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context: context,
                          label: 'All Time',
                          icon: Icons.all_inclusive_rounded,
                          isSelected: data.activeFilter == DashboardDateFilter.allTime,
                          onTap: () => ctr.onDateFilterChanged(DashboardDateFilter.allTime),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          context: context,
                          label: data.activeFilter == DashboardDateFilter.custom
                              ? data.filterLabel
                              : 'Custom 📅',
                          icon: Icons.date_range_rounded,
                          isSelected: data.activeFilter == DashboardDateFilter.custom,
                          onTap: () => ctr.onDateFilterChanged(DashboardDateFilter.custom),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. Hero Balance Card
                  BalanceCard(
                    totalBalance: data.totalBalance,
                    totalIncome: data.totalIncome,
                    totalExpense: data.totalExpense,
                    filterLabel: data.filterLabel,
                  ),
                  const SizedBox(height: 20),

                  // 2. Quick Action Pills
                  QuickActionBar(
                    onSyncSms: ctr.onSyncSms,
                    onAddExpense: ctr.onAddExpense,
                    onAddKhata: ctr.onAddKhata,
                    onExportPdf: ctr.onExportPdf,
                    onSmsSimulator: ctr.onSmsSimulator,
                  ),
                  const SizedBox(height: 24),

                  // 3. Monthly Spend Meter
                  SpendMeter(
                    todaySpend: data.todaySpend,
                    totalExpense: data.totalExpense,
                    monthlyBudget: data.monthlyBudget,
                  ),
                  const SizedBox(height: 24),

                  // 4. Recent Transactions List
                  RecentTransactionsList(
                    transactions: data.recentTransactions,
                    onTransactionTap: ctr.onTransactionTap,
                    onViewAll: ctr.onViewAllTransactions,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
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
          color: isSelected
              ? AppColors.primary
              : AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.darkBorder.withValues(alpha: 0.6),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
}
