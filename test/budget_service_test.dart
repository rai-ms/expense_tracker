import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/services/budget_service/budget_service.dart';

void main() {
  group('BudgetService Status & Calculation Tests', () {
    final budgetService = BudgetService();

    test('Normal spend (<75%) returns correct status', () {
      final status = budgetService.calculateStatus(
        category: 'Food & Dining',
        budgetAmount: 10000.0,
        spentAmount: 5000.0,
      );

      expect(status.category, 'Food & Dining');
      expect(status.budgetAmount, 10000.0);
      expect(status.spentAmount, 5000.0);
      expect(status.percentage, 50);
      expect(status.progress, 0.5);
      expect(status.level, BudgetAlertLevel.normal);
      expect(status.remainingAmount, 5000.0);
      expect(status.overspendAmount, 0.0);
      expect(status.isExceeded, false);
      expect(status.isWarning, false);
    });

    test('Warning spend (75% - 99%) flags warning level', () {
      final status = budgetService.calculateStatus(
        category: 'Shopping',
        budgetAmount: 10000.0,
        spentAmount: 8500.0,
      );

      expect(status.percentage, 85);
      expect(status.progress, 0.85);
      expect(status.level, BudgetAlertLevel.warning);
      expect(status.remainingAmount, 1500.0);
      expect(status.overspendAmount, 0.0);
      expect(status.isExceeded, false);
      expect(status.isWarning, true);
    });

    test('Exceeded spend (>=100%) flags exceeded level with overspend amount', () {
      final status = budgetService.calculateStatus(
        category: 'Entertainment',
        budgetAmount: 5000.0,
        spentAmount: 6200.0,
      );

      expect(status.percentage, 124);
      expect(status.progress, 1.0); // clamped
      expect(status.rawProgress, 1.24);
      expect(status.level, BudgetAlertLevel.exceeded);
      expect(status.remainingAmount, 0.0);
      expect(status.overspendAmount, 1200.0);
      expect(status.isExceeded, true);
      expect(status.isWarning, false);
    });

    test('Zero budget handles edge case safely without division by zero', () {
      final status = budgetService.calculateStatus(
        category: 'Miscellaneous',
        budgetAmount: 0.0,
        spentAmount: 500.0,
      );

      expect(status.progress, 0.0);
      expect(status.percentage, 0);
      expect(status.level, BudgetAlertLevel.normal);
      expect(status.overspendAmount, 500.0);
    });

    test('Exact 75% boundary transitions to warning level', () {
      final status = budgetService.calculateStatus(
        category: 'Bills & Utilities',
        budgetAmount: 10000.0,
        spentAmount: 7500.0,
      );

      expect(status.percentage, 75);
      expect(status.level, BudgetAlertLevel.warning);
      expect(status.isWarning, true);
    });

    test('Exact 100% boundary transitions to exceeded level', () {
      final status = budgetService.calculateStatus(
        category: 'Fuel',
        budgetAmount: 5000.0,
        spentAmount: 5000.0,
      );

      expect(status.percentage, 100);
      expect(status.level, BudgetAlertLevel.exceeded);
      expect(status.isExceeded, true);
      expect(status.remainingAmount, 0.0);
    });
  });
}
