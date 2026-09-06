import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/base_controller/widget_view.dart';
import '../../../../core/base/bloc_base/bloc_event_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/analytics_bloc.dart';
import '../controller/analytics_controller.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/spend_trend_line_chart.dart';
import 'widgets/top_merchants_widget.dart';

import '../../../../core/localization/app_localizations.dart';

class AnalyticsView
    extends WidgetView<AnalyticsView, AnalyticsControllerState> {
  const AnalyticsView(super.ctr, {super.key});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr('analytics'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<AnalyticsBloc, BlocEventState<AnalyticsData>>(
        bloc: ctr.bloc,
        builder: (context, state) {
          if (state.isLoading && state.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = state.data;
          if (data == null) {
            return const Center(child: Text('No analytics data'));
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Range Segment Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildTimePill(
                        'This Week',
                        AnalyticsTimeRange.thisWeek,
                        data.timeRange,
                      ),
                      const SizedBox(width: 8),
                      _buildTimePill(
                        context.tr('this_month'),
                        AnalyticsTimeRange.thisMonth,
                        data.timeRange,
                      ),
                      const SizedBox(width: 8),
                      _buildTimePill(
                        'Last 3 Months',
                        AnalyticsTimeRange.last3Months,
                        data.timeRange,
                      ),
                      const SizedBox(width: 8),
                      _buildTimePill(
                        'This Year',
                        AnalyticsTimeRange.thisYear,
                        data.timeRange,
                      ),
                      const SizedBox(width: 8),
                      _buildTimePill(
                        context.tr('all_time'),
                        AnalyticsTimeRange.allTime,
                        data.timeRange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Inflow vs Outflow Mini Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.creditGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.creditGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('income'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currency.format(data.totalIncome),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.creditGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.debitRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.debitRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('expense'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currency.format(data.totalExpense),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.debitRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Donut Pie Chart Breakdown
                CategoryPieChart(
                  categoryBreakdown: data.categoryBreakdown,
                  totalExpense: data.totalExpense,
                ),
                const SizedBox(height: 20),

                // 2. Monthly Spend Trend Line Chart
                SpendTrendLineChart(
                  monthlyTrend: data.monthlySpendTrend,
                ),
                const SizedBox(height: 20),

                // 3. Top Merchants Leaderboard
                TopMerchantsWidget(
                  topMerchants: data.topMerchants,
                  totalExpense: data.totalExpense,
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePill(
    String label,
    AnalyticsTimeRange range,
    AnalyticsTimeRange current,
  ) {
    final isSelected = range == current;

    return InkWell(
      onTap: () => ctr.onTimeRangeChanged(range),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.darkSurfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
