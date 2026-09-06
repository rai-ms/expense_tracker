import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/presentation/modules/transactions/models/saved_filter_preset.dart';
import 'package:expense_tracker/presentation/modules/transactions/models/transaction_filter_criteria.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionFilterCriteria Tests', () {
    test('default criteria has 0 activeFilterCount and isDefault is true with flexible mode', () {
      const criteria = TransactionFilterCriteria();
      expect(criteria.activeFilterCount, 0);
      expect(criteria.isDefault, true);
      expect(criteria.matchMode, FilterMatchMode.flexible);
    });

    test('activeFilterCount correctly increments for each active filter dimension and strict mode', () {
      var criteria = const TransactionFilterCriteria(
        dateFilter: TransactionDateFilter.today,
        types: {'debit', 'credit'},
        categories: {'Food & Dining', 'Groceries'},
        platforms: {'Google Pay'},
        minAmount: 100,
        maxAmount: 500,
        sortBy: TransactionSortBy.amountHighToLow,
        matchMode: FilterMatchMode.strict,
      );

      // 1 (date) + 2 (types) + 2 (categories) + 1 (platform) + 1 (amount) + 1 (sort) + 1 (strict mode) = 9
      expect(criteria.activeFilterCount, 9);
      expect(criteria.isDefault, false);
      expect(criteria.matchMode, FilterMatchMode.strict);
    });

    test('copyWith updates fields and clears amounts when requested', () {
      var criteria = const TransactionFilterCriteria(
        minAmount: 50,
        maxAmount: 500,
        types: {'debit'},
      );

      var updated = criteria.copyWith(
        clearMinAmount: true,
        types: {'debit', 'credit'},
        matchMode: FilterMatchMode.strict,
      );

      expect(updated.minAmount, isNull);
      expect(updated.maxAmount, 500);
      expect(updated.types, {'debit', 'credit'});
      expect(updated.matchMode, FilterMatchMode.strict);

      var cleared = updated.copyWith(clearMaxAmount: true);
      expect(cleared.maxAmount, isNull);
    });

    test('SavedFilterPreset serialization and deserialization works accurately with matchMode', () {
      final criteria = const TransactionFilterCriteria(
        types: {'debit'},
        categories: {'Food & Dining'},
        minAmount: 200,
        matchMode: FilterMatchMode.flexible,
      );

      final preset = SavedFilterPreset(
        id: '12345',
        name: 'Food Expenses',
        criteria: criteria,
        createdAt: DateTime(2026, 9, 7),
      );

      final json = preset.toJson();
      final decoded = SavedFilterPreset.fromJson(json);

      expect(decoded.id, '12345');
      expect(decoded.name, 'Food Expenses');
      expect(decoded.criteria.types, {'debit'});
      expect(decoded.criteria.categories, {'Food & Dining'});
      expect(decoded.criteria.minAmount, 200);
      expect(decoded.criteria.matchMode, FilterMatchMode.flexible);
    });

    test('AppConstants returns category details for standard categories', () {
      final foodCat = AppConstants.getCategory('food');
      expect(foodCat['name'], 'Food & Dining');

      final shoppingCat = AppConstants.getCategory('Shopping');
      expect(shoppingCat['name'], 'Shopping');
    });
  });
}
