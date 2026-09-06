import 'package:expense_tracker/presentation/modules/transactions/models/transaction_filter_criteria.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionFilterCriteria Tests', () {
    test('default criteria has 0 activeFilterCount and isDefault is true', () {
      const criteria = TransactionFilterCriteria();
      expect(criteria.activeFilterCount, 0);
      expect(criteria.isDefault, true);
    });

    test('activeFilterCount correctly increments for each active filter dimension', () {
      var criteria = const TransactionFilterCriteria(
        dateFilter: TransactionDateFilter.today,
        types: {'debit', 'credit'},
        categories: {'Food & Dining', 'Groceries'},
        platforms: {'Google Pay'},
        minAmount: 100,
        maxAmount: 500,
        sortBy: TransactionSortBy.amountHighToLow,
      );

      // 1 (date) + 2 (types) + 2 (categories) + 1 (platform) + 1 (amount) + 1 (sort) = 8
      expect(criteria.activeFilterCount, 8);
      expect(criteria.isDefault, false);
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
      );

      expect(updated.minAmount, isNull);
      expect(updated.maxAmount, 500);
      expect(updated.types, {'debit', 'credit'});

      var cleared = updated.copyWith(clearMaxAmount: true);
      expect(cleared.maxAmount, isNull);
    });
  });
}
