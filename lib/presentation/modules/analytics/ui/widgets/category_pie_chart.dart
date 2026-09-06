import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';

class CategoryPieChart extends StatefulWidget {
  final Map<String, double> categoryBreakdown;
  final double totalExpense;

  const CategoryPieChart({
    super.key,
    required this.categoryBreakdown,
    required this.totalExpense,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (widget.categoryBreakdown.isEmpty || widget.totalExpense <= 0) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: const Center(
          child: Text(
            'No expense data available for this range',
            style: TextStyle(color: AppColors.textSecondaryDark),
          ),
        ),
      );
    }

    final entries = widget.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Expense by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currency.format(widget.totalExpense),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.debitRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: entries.asMap().entries.map((item) {
                  final index = item.key;
                  final entry = item.value;
                  final isTouched = index == touchedIndex;
                  final double radius = isTouched ? 45.0 : 38.0;
                  final catMeta = AppConstants.getCategory(entry.key);
                  final Color color = catMeta['color'] as Color;

                  final pct = ((entry.value / widget.totalExpense) * 100).toInt();

                  return PieChartSectionData(
                    color: color,
                    value: entry.value,
                    title: isTouched ? '$pct%' : '',
                    radius: radius,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Category Legend List
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: entries.map((e) {
              final catMeta = AppConstants.getCategory(e.key);
              final Color color = catMeta['color'] as Color;
              final pct = ((e.value / widget.totalExpense) * 100).toStringAsFixed(1);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.key} ($pct%)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
