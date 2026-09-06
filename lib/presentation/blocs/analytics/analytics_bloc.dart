import '../../../core/base/bloc_base/base_bloc.dart';
import '../../../core/base/bloc_base/bloc_event.dart';
import '../../../domain/repositories/i_transaction_repository.dart';

// Analytics Events
abstract class AnalyticsEvent extends BlocEvent {
  const AnalyticsEvent();
}

enum AnalyticsTimeRange {
  thisWeek,
  thisMonth,
  last3Months,
  thisYear,
  allTime,
}

class LoadAnalyticsEvent extends AnalyticsEvent {
  final AnalyticsTimeRange timeRange;
  const LoadAnalyticsEvent({this.timeRange = AnalyticsTimeRange.thisMonth});

  @override
  List<Object?> get props => [timeRange];
}

// Analytics State Data
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

// Analytics BLoC
class AnalyticsBloc extends BaseBloc<AnalyticsEvent, AnalyticsData> {
  final ITransactionRepository _transactionRepository;

  AnalyticsBloc(this._transactionRepository) {
    on<LoadAnalyticsEvent>(_onLoadAnalytics);
  }

  void _onLoadAnalytics(
    LoadAnalyticsEvent event,
    dynamic emit,
  ) {
    emitLoading();
    try {
      final now = DateTime.now();
      late DateTime startDate;
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      switch (event.timeRange) {
        case AnalyticsTimeRange.thisWeek:
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case AnalyticsTimeRange.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case AnalyticsTimeRange.last3Months:
          startDate = DateTime(now.year, now.month - 2, 1);
          break;
        case AnalyticsTimeRange.thisYear:
          startDate = DateTime(now.year, 1, 1);
          break;
        case AnalyticsTimeRange.allTime:
          startDate = DateTime(2020, 1, 1);
          break;
      }

      final totalIncome = _transactionRepository.getTotalIncome(start: startDate, end: endDate);
      final totalExpense = _transactionRepository.getTotalExpense(start: startDate, end: endDate);
      final categoryBreakdown = _transactionRepository.getCategoryBreakdown(start: startDate, end: endDate);
      final monthlySpendTrend = _transactionRepository.getMonthlySpendTrend(months: 6);
      final topMerchants = _transactionRepository.getTopMerchants(limit: 5, start: startDate, end: endDate);

      emitSuccess(
        data: AnalyticsData(
          timeRange: event.timeRange,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          categoryBreakdown: categoryBreakdown,
          monthlySpendTrend: monthlySpendTrend,
          topMerchants: topMerchants,
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (e) {
      emitFailed(message: 'Failed to load analytics: $e');
    }
  }
}
