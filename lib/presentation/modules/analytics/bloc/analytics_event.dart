part of 'analytics_bloc.dart';

enum AnalyticsTimeRange {
  thisWeek,
  thisMonth,
  last3Months,
  thisYear,
  allTime,
}

/// Base class for Analytics events
abstract class AnalyticsEvent extends BlocEvent {
  const AnalyticsEvent();
}

/// Event to load analytics computations for a given time window
class LoadAnalyticsEvent extends AnalyticsEvent {
  final AnalyticsTimeRange timeRange;
  const LoadAnalyticsEvent({this.timeRange = AnalyticsTimeRange.thisMonth});

  @override
  List<Object?> get props => [timeRange];
}
