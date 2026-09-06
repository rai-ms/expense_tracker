part of 'dashboard_bloc.dart';

/// State data class holding all computed metrics for Dashboard
class DashboardData {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double todaySpend;
  final double monthlyBudget;
  final List<TransactionEntity> recentTransactions;
  final Map<String, double> categoryBreakdown;
  final DashboardDateFilter activeFilter;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String filterLabel;

  const DashboardData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.todaySpend,
    required this.monthlyBudget,
    required this.recentTransactions,
    required this.categoryBreakdown,
    this.activeFilter = DashboardDateFilter.thisMonth,
    this.filterStartDate,
    this.filterEndDate,
    this.filterLabel = 'This Month',
  });

  DashboardData copyWith({
    double? totalBalance,
    double? totalIncome,
    double? totalExpense,
    double? todaySpend,
    double? monthlyBudget,
    List<TransactionEntity>? recentTransactions,
    Map<String, double>? categoryBreakdown,
    DashboardDateFilter? activeFilter,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? filterLabel,
  }) {
    return DashboardData(
      totalBalance: totalBalance ?? this.totalBalance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      todaySpend: todaySpend ?? this.todaySpend,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      activeFilter: activeFilter ?? this.activeFilter,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
      filterLabel: filterLabel ?? this.filterLabel,
    );
  }
}
