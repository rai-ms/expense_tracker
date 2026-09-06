import 'package:flutter/material.dart';

import '../../../../core/services/di/injection.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../../../blocs/analytics/analytics_bloc.dart';
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
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
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
