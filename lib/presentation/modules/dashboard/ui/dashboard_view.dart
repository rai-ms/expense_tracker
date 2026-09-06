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
                  // 1. Hero Balance Card
                  BalanceCard(
                    totalBalance: data.totalBalance,
                    totalIncome: data.totalIncome,
                    totalExpense: data.totalExpense,
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
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_dashboard',
        onPressed: ctr.onAddExpense,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction'),
      ),
    );
  }
}
