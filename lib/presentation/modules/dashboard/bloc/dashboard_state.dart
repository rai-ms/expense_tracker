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
  final Map<String, double> categoryBudgets;
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
    this.categoryBudgets = const {},
    this.activeFilter = DashboardDateFilter.thisMonth,
    this.filterStartDate,
    this.filterEndDate,
    this.filterLabel = 'This Month',
  });

  /// Computed budget statuses for each category that has a budget set
  List<CategoryBudgetStatus> get budgetStatuses {
    if (categoryBudgets.isEmpty) return const [];
    final budgetService = sl.isRegistered<BudgetService>() ? sl<BudgetService>() : null;
    final List<CategoryBudgetStatus> list = [];

    categoryBudgets.forEach((category, budget) {
      final spent = categoryBreakdown[category] ?? 0.0;
      if (budgetService != null) {
        list.add(budgetService.calculateStatus(
          category: category,
          budgetAmount: budget,
          spentAmount: spent,
        ));
      } else {
        final ratio = budget > 0 ? (spent / budget) : 0.0;
        list.add(CategoryBudgetStatus(
          category: category,
          budgetAmount: budget,
          spentAmount: spent,
          progress: ratio.clamp(0.0, 1.0),
          rawProgress: ratio,
          percentage: (ratio * 100).round(),
          level: ratio >= 1.0
              ? BudgetAlertLevel.exceeded
              : ratio >= 0.75
                  ? BudgetAlertLevel.warning
                  : BudgetAlertLevel.normal,
        ));
      }
    });

    // Sort by highest percentage used first
    list.sort((a, b) => b.rawProgress.compareTo(a.rawProgress));
    return list;
  }

  /// Categories that have either exceeded 100% or are in warning >= 75%
  List<CategoryBudgetStatus> get warningOrExceededBudgets =>
      budgetStatuses.where((s) => s.isWarning || s.isExceeded).toList();

  /// Total budget allocated across all categories
  double get totalAllocatedCategoryBudget =>
      categoryBudgets.values.fold(0.0, (prev, amt) => prev + amt);

  DashboardData copyWith({
    double? totalBalance,
    double? totalIncome,
    double? totalExpense,
    double? todaySpend,
    double? monthlyBudget,
    List<TransactionEntity>? recentTransactions,
    Map<String, double>? categoryBreakdown,
    Map<String, double>? categoryBudgets,
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
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      activeFilter: activeFilter ?? this.activeFilter,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
      filterLabel: filterLabel ?? this.filterLabel,
    );
  }
}
