import 'package:intl/intl.dart';
import '../../core/services/objectbox_service/objectbox_service.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../objectbox.g.dart';
import '../models/transaction_entity.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  final ObjectBoxService _boxService;

  TransactionRepositoryImpl(this._boxService);

  @override
  List<TransactionEntity> getAllTransactions() {
    final query = _boxService.transactionBox.query()
      ..order(TransactionEntity_.date, flags: Order.descending);
    final q = query.build();
    final results = q.find();
    q.close();
    return results;
  }

  @override
  List<TransactionEntity> getTransactionsByDateRange(DateTime start, DateTime end) {
    final query = _boxService.transactionBox.query(
      TransactionEntity_.date.between(
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ),
    )..order(TransactionEntity_.date, flags: Order.descending);
    final q = query.build();
    final results = q.find();
    q.close();
    return results;
  }

  @override
  List<TransactionEntity> getRecentTransactions({int limit = 10}) {
    final query = _boxService.transactionBox.query()
      ..order(TransactionEntity_.date, flags: Order.descending);
    final q = query.build()..limit = limit;
    final results = q.find();
    q.close();
    return results;
  }

  @override
  TransactionEntity? getTransactionByUid(String uid) {
    final query = _boxService.transactionBox.query(
      TransactionEntity_.uid.equals(uid),
    ).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  @override
  bool hasTransactionWithTxnId(String txnId) {
    final query = _boxService.transactionBox.query(
      TransactionEntity_.transactionId.equals(txnId),
    ).build();
    final count = query.count();
    query.close();
    return count > 0;
  }

  @override
  int addTransaction(TransactionEntity transaction) {
    return _boxService.transactionBox.put(transaction);
  }

  @override
  List<int> addTransactions(List<TransactionEntity> transactions) {
    return _boxService.transactionBox.putMany(transactions);
  }

  @override
  bool updateTransaction(TransactionEntity transaction) {
    _boxService.transactionBox.put(transaction);
    return true;
  }

  @override
  bool deleteTransaction(int id) {
    return _boxService.transactionBox.remove(id);
  }

  @override
  double getTotalIncome({DateTime? start, DateTime? end}) {
    final list = _getFilteredList(start, end);
    double sum = 0.0;
    for (final t in list) {
      if (t.isCredit) sum += t.amount;
    }
    return sum;
  }

  @override
  double getTotalExpense({DateTime? start, DateTime? end}) {
    final list = _getFilteredList(start, end);
    double sum = 0.0;
    for (final t in list) {
      if (t.isDebit) sum += t.amount;
    }
    return sum;
  }

  @override
  double getNetBalance({DateTime? start, DateTime? end}) {
    final list = _getFilteredList(start, end);
    double income = 0.0;
    double expense = 0.0;
    for (final t in list) {
      if (t.isCredit) income += t.amount;
      if (t.isDebit) expense += t.amount;
    }
    return income - expense;
  }

  @override
  Map<String, double> getCategoryBreakdown({DateTime? start, DateTime? end}) {
    final list = _getFilteredList(start, end);
    final Map<String, double> breakdown = {};
    for (final t in list) {
      if (t.isDebit) {
        breakdown[t.category] = (breakdown[t.category] ?? 0.0) + t.amount;
      }
    }
    return breakdown;
  }

  @override
  Map<String, double> getMonthlySpendTrend({int months = 6}) {
    final now = DateTime.now();
    final Map<String, double> trend = {};

    for (int i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);
      final key = DateFormat('MMM').format(monthDate);

      final list = getTransactionsByDateRange(monthDate, monthEnd);
      double monthExpense = 0.0;
      for (final t in list) {
        if (t.isDebit) monthExpense += t.amount;
      }
      trend[key] = monthExpense;
    }
    return trend;
  }

  @override
  Map<String, double> getTopMerchants({int limit = 5, DateTime? start, DateTime? end}) {
    final list = _getFilteredList(start, end);
    final Map<String, double> merchants = {};
    for (final t in list) {
      if (t.isDebit && t.merchant != null && t.merchant!.isNotEmpty) {
        merchants[t.merchant!] = (merchants[t.merchant!] ?? 0.0) + t.amount;
      }
    }

    final sortedEntries = merchants.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final Map<String, double> result = {};
    for (int i = 0; i < sortedEntries.length && i < limit; i++) {
      result[sortedEntries[i].key] = sortedEntries[i].value;
    }
    return result;
  }

  List<TransactionEntity> _getFilteredList(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return getTransactionsByDateRange(start, end);
    }
    return getAllTransactions();
  }
}
