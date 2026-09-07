import 'dart:convert';
import 'package:injectable/injectable.dart';

import '../../base/logger/app_logger.dart';
import '../notification_service/notification_service.dart';
import '../objectbox_service/objectbox_service.dart';

/// Alert level for a category budget
enum BudgetAlertLevel {
  normal,
  warning, // 75% - 99%
  exceeded; // 100%+
}

/// Calculated status of a category's budget vs spending
class CategoryBudgetStatus {
  final String category;
  final double budgetAmount;
  final double spentAmount;
  final double progress; // 0.0 to 1.0 (clamped for visual indicators)
  final double rawProgress; // actual ratio
  final int percentage;
  final BudgetAlertLevel level;

  const CategoryBudgetStatus({
    required this.category,
    required this.budgetAmount,
    required this.spentAmount,
    required this.progress,
    required this.rawProgress,
    required this.percentage,
    required this.level,
  });

  bool get isWarning => level == BudgetAlertLevel.warning;
  bool get isExceeded => level == BudgetAlertLevel.exceeded;
  double get remainingAmount => (budgetAmount - spentAmount).clamp(0.0, double.infinity);
  double get overspendAmount => spentAmount > budgetAmount ? spentAmount - budgetAmount : 0.0;
}

/// Service managing category-specific monthly spending limits, calculation, and overspend push alerts
@lazySingleton
class BudgetService {
  static const String _prefCategoryBudgetsKey = 'spendwise_category_budgets_json';
  static const String _prefAlertHistoryKey = 'spendwise_budget_alerts_history_json';

  /// Get all configured category budgets: Map of Category Name -> Monthly Budget Amount
  Map<String, double> getCategoryBudgets() {
    final rawJson = ObjectBoxService.instance.getSetting(_prefCategoryBudgetsKey);
    if (rawJson == null || rawJson.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final Map<String, double> result = {};
      decoded.forEach((key, value) {
        final amount = (value as num).toDouble();
        if (amount > 0) {
          result[key] = amount;
        }
      });
      return result;
    } catch (e) {
      Log.e('Failed to parse category budgets: $e');
      return {};
    }
  }

  /// Get budget for a specific category
  double? getBudgetForCategory(String category) {
    final budgets = getCategoryBudgets();
    return budgets[category];
  }

  /// Set or update monthly budget for a category
  Future<void> setCategoryBudget(String category, double amount) async {
    final budgets = getCategoryBudgets();
    if (amount <= 0) {
      budgets.remove(category);
    } else {
      budgets[category] = amount;
    }
    _saveBudgets(budgets);
    Log.i('Category budget updated: $category -> ₹$amount');
  }

  /// Remove budget limit for a category
  Future<void> removeCategoryBudget(String category) async {
    final budgets = getCategoryBudgets();
    budgets.remove(category);
    _saveBudgets(budgets);
    Log.i('Category budget removed for: $category');
  }

  void _saveBudgets(Map<String, double> budgets) {
    final jsonStr = jsonEncode(budgets);
    ObjectBoxService.instance.setSetting(_prefCategoryBudgetsKey, jsonStr);
  }

  /// Calculate the status of a specific category budget given its current spend
  CategoryBudgetStatus calculateStatus({
    required String category,
    required double budgetAmount,
    required double spentAmount,
  }) {
    final double rawProgress = budgetAmount > 0 ? (spentAmount / budgetAmount) : 0.0;
    final double progress = rawProgress.clamp(0.0, 1.0);
    final int percentage = (rawProgress * 100).round();

    final BudgetAlertLevel level;
    if (rawProgress >= 1.0) {
      level = BudgetAlertLevel.exceeded;
    } else if (rawProgress >= 0.75) {
      level = BudgetAlertLevel.warning;
    } else {
      level = BudgetAlertLevel.normal;
    }

    return CategoryBudgetStatus(
      category: category,
      budgetAmount: budgetAmount,
      spentAmount: spentAmount,
      progress: progress,
      rawProgress: rawProgress,
      percentage: percentage,
      level: level,
    );
  }

  /// Check current month category spends against budgets and trigger push alerts if thresholds are breached.
  /// Fires at most once per threshold (80% and 100%) per category per calendar month.
  Future<List<String>> checkAndTriggerAlerts(Map<String, double> categorySpends) async {
    final budgets = getCategoryBudgets();
    if (budgets.isEmpty) return [];

    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final alertHistory = _loadAlertHistory(monthKey);

    final List<String> triggeredAlerts = [];

    for (final entry in budgets.entries) {
      final category = entry.key;
      final budget = entry.value;
      final spent = categorySpends[category] ?? 0.0;

      if (budget <= 0) continue;

      final ratio = spent / budget;
      final historyList = alertHistory[category] ?? <int>[];

      // Threshold 100%: Exceeded Limit
      if (ratio >= 1.0) {
        if (!historyList.contains(100)) {
          final overspend = (spent - budget).toInt();
          final title = '🚨 Budget Exceeded: $category';
          final body = overspend > 0
              ? 'You have exceeded your $category limit by ₹$overspend! (₹${spent.toInt()} / ₹${budget.toInt()})'
              : 'You have reached 100% of your $category budget! (₹${spent.toInt()} / ₹${budget.toInt()})';

          await NotificationService.instance.showBudgetAlertNotification(
            id: category.hashCode ^ 100,
            title: title,
            body: body,
          );

          historyList.add(100);
          triggeredAlerts.add(title);
          Log.w('Triggered 100% budget alert for $category');
        }
      }
      // Threshold 80%: Approaching Limit Warning
      else if (ratio >= 0.80) {
        if (!historyList.contains(80)) {
          final percent = (ratio * 100).round();
          final remaining = (budget - spent).toInt();
          final title = '⚠️ Budget Alert: $category at $percent%';
          final body = 'You have spent ₹${spent.toInt()} of ₹${budget.toInt()}. Only ₹$remaining remaining this month!';

          await NotificationService.instance.showBudgetAlertNotification(
            id: category.hashCode ^ 80,
            title: title,
            body: body,
          );

          historyList.add(80);
          triggeredAlerts.add(title);
          Log.w('Triggered 80% budget alert for $category');
        }
      }

      alertHistory[category] = historyList;
    }

    if (triggeredAlerts.isNotEmpty) {
      _saveAlertHistory(monthKey, alertHistory);
    }

    return triggeredAlerts;
  }

  Map<String, List<int>> _loadAlertHistory(String monthKey) {
    final rawJson = ObjectBoxService.instance.getSetting('$_prefAlertHistoryKey:$monthKey');
    if (rawJson == null || rawJson.isEmpty) return {};

    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final Map<String, List<int>> result = {};
      decoded.forEach((cat, list) {
        if (list is List) {
          result[cat] = list.map((e) => (e as num).toInt()).toList();
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  void _saveAlertHistory(String monthKey, Map<String, List<int>> history) {
    final jsonStr = jsonEncode(history);
    ObjectBoxService.instance.setSetting('$_prefAlertHistoryKey:$monthKey', jsonStr);
  }
}
