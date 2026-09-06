import 'package:flutter/material.dart';

import '../../../../core/services/di/injection.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../bloc/analytics_bloc.dart';
import '../../../../core/services/event_bus/app_events.dart';
import '../ui/analytics_view.dart';

class AnalyticsController extends StatefulWidget {
  const AnalyticsController({super.key});

  @override
  State<AnalyticsController> createState() => AnalyticsControllerState();
}

class AnalyticsControllerState extends State<AnalyticsController>
    with _AnalyticsMixin {
  late final AnalyticsBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = AnalyticsBloc(sl<ITransactionRepository>());
    bloc.add(const LoadAnalyticsEvent(timeRange: AnalyticsTimeRange.thisMonth));
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
      final current = bloc.state.data;
      bloc.add(
        LoadAnalyticsEvent(
          timeRange: current?.timeRange ?? AnalyticsTimeRange.thisMonth,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsView(this);
  }
}

mixin _AnalyticsMixin on State<AnalyticsController> {
  AnalyticsControllerState get _state => this as AnalyticsControllerState;

  void onTimeRangeChanged(AnalyticsTimeRange range) {
    _state.bloc.add(LoadAnalyticsEvent(timeRange: range));
  }
}
