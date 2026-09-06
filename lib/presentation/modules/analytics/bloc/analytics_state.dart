part of 'analytics_bloc.dart';

/// State data class holding all aggregated analytics figures
class AnalyticsData {
  final AnalyticsTimeRange timeRange;
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> monthlySpendTrend;
  final Map<String, double> topMerchants;
  final DateTime startDate;
  final DateTime endDate;

  const AnalyticsData({
    required this.timeRange,
    required this.totalIncome,
    required this.totalExpense,
    required this.categoryBreakdown,
    required this.monthlySpendTrend,
    required this.topMerchants,
    required this.startDate,
    required this.endDate,
  });
}
