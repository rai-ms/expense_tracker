part of 'dashboard_bloc.dart';

enum DashboardDateFilter {
  thisMonth,
  lastMonth,
  allTime,
  custom,
}

/// Base class for all Dashboard events
abstract class DashboardEvent extends BlocEvent {
  const DashboardEvent();
}

/// Event to load dashboard stats and transactions with date filtering
class LoadDashboardDataEvent extends DashboardEvent {
  final DashboardDateFilter filter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const LoadDashboardDataEvent({
    this.filter = DashboardDateFilter.thisMonth,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  List<Object?> get props => [filter, customStartDate, customEndDate];
}

/// Event to trigger SMS inbox sync
class SyncSmsEvent extends DashboardEvent {
  final DateTime? fromDate;
  final DateTime? toDate;
  final int limit;

  const SyncSmsEvent({
    this.fromDate,
    this.toDate,
    this.limit = 500,
  });

  @override
  List<Object?> get props => [fromDate, toDate, limit];
}

/// Event to quickly add a transaction from dashboard
class AddQuickTransactionEvent extends DashboardEvent {
  final TransactionEntity transaction;
  const AddQuickTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Event to update and persist monthly budget
class UpdateMonthlyBudgetEvent extends DashboardEvent {
  final double newBudget;
  const UpdateMonthlyBudgetEvent(this.newBudget);

  @override
  List<Object?> get props => [newBudget];
}
