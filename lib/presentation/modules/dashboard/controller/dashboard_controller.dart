import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/di/injection.dart';
import '../../../../data/models/transaction_entity.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../../transactions/ui/widgets/add_transaction_modal.dart';
import '../../transactions/ui/widgets/transaction_detail_modal.dart';
import '../../../../core/services/event_bus/app_events.dart';
import '../../main_navigation/controller/main_navigation_controller.dart';
import '../ui/dashboard_view.dart';
import '../../khata/ui/widgets/split_bill_modal.dart';
import '../ui/widgets/adjust_budget_modal.dart';
import '../ui/widgets/category_budgets_modal.dart';
import '../ui/widgets/sync_sms_date_modal.dart';

class DashboardController extends StatefulWidget {
  const DashboardController({super.key});

  @override
  State<DashboardController> createState() => DashboardControllerState();
}

class DashboardControllerState extends State<DashboardController>
    with _DashboardMixin {
  late final DashboardBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = sl<DashboardBloc>();
    bloc.add(LoadDashboardDataEvent());
    bloc.add(const AutoSyncSmsEvent());
    AppEvents.syncNotifier.addListener(_onSyncData);
  }

  @override
  void dispose() {
    AppEvents.syncNotifier.removeListener(_onSyncData);
    bloc.close();
    super.dispose();
  }

  void _onSyncData() {
    if (mounted) {
      final currentData = bloc.state.data;
      bloc.add(
        LoadDashboardDataEvent(
          filter: currentData?.activeFilter ?? DashboardDateFilter.thisMonth,
          customStartDate: currentData?.filterStartDate,
          customEndDate: currentData?.filterEndDate,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardView(this);
  }
}

mixin _DashboardMixin on State<DashboardController> {
  DashboardControllerState get _state => this as DashboardControllerState;

  void onSyncSms() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SyncSmsDateModal(
        onSync: (fromDate, toDate, limit) {
          final dateFormat = DateFormat('dd MMM yyyy');
          _state.bloc.add(
            SyncSmsEvent(
              fromDate: fromDate,
              toDate: toDate,
              limit: limit,
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Syncing all SMS since ${dateFormat.format(fromDate)}...'),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  void onEditMonthlyBudget(double currentBudget) {
    AdjustBudgetModal.show(
      context: context,
      currentBudget: currentBudget,
      onBudgetSaved: (newBudget) {
        _state.bloc.add(UpdateMonthlyBudgetEvent(newBudget));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monthly budget updated to ₹${newBudget.toInt()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void onManageCategoryBudgets() {
    final data = _state.bloc.state.data;
    if (data == null) return;
    CategoryBudgetsModal.show(
      context: context,
      bloc: _state.bloc,
      data: data,
    );
  }

  void onAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddTransactionModal(
        onSave: (txn) {
          _state.bloc.add(AddQuickTransactionEvent(txn));
        },
      ),
    );
  }

  void onSplitBill() {
    SplitBillModal.show(context: context);
  }

  void onAddKhata() {
    if (MainNavigationControllerState.tabControllerNotifier != null) {
      MainNavigationControllerState.switchToTab(2);
    } else {
      context.push(AppRoutes.khata);
    }
  }

  void onExportPdf() {
    context.push(AppRoutes.exportPdf);
  }

  void onMyDocuments() {
    context.push(AppRoutes.documents);
  }

  void onSmsSimulator() {
    context.push(AppRoutes.smsSimulator).then((_) {
      AppEvents.notifyDataChanged();
    });
  }

  void onViewAllTransactions() {
    if (MainNavigationControllerState.tabControllerNotifier != null) {
      MainNavigationControllerState.switchToTab(1);
    } else {
      context.push(AppRoutes.transactions);
    }
  }

  void onDateFilterChanged(DashboardDateFilter filter) {
    if (filter == DashboardDateFilter.custom) {
      onSelectCustomDateRange();
    } else {
      _state.bloc.add(LoadDashboardDataEvent(filter: filter));
    }
  }

  Future<void> onSelectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
    );

    if (picked != null) {
      _state.bloc.add(
        LoadDashboardDataEvent(
          filter: DashboardDateFilter.custom,
          customStartDate: picked.start,
          customEndDate: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        ),
      );
    }
  }

  void onTransactionTap(TransactionEntity txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailModal(
        transaction: txn,
        onDelete: () {
          sl<ITransactionRepository>().deleteTransaction(txn.id);
          AppEvents.notifyDataChanged();
        },
      ),
    );
  }
}
