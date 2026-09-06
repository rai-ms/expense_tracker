import '../../data/models/transaction_entity.dart';

abstract class ITransactionRepository {
  const ITransactionRepository();

  List<TransactionEntity> getAllTransactions();
  List<TransactionEntity> getTransactionsByDateRange(DateTime start, DateTime end);
  List<TransactionEntity> getRecentTransactions({int limit = 10});
  TransactionEntity? getTransactionByUid(String uid);
  bool hasTransactionWithTxnId(String txnId);
  int addTransaction(TransactionEntity transaction);
  List<int> addTransactions(List<TransactionEntity> transactions);
  bool updateTransaction(TransactionEntity transaction);
  bool deleteTransaction(int id);
  
  // Analytics queries
  double getTotalIncome({DateTime? start, DateTime? end});
  double getTotalExpense({DateTime? start, DateTime? end});
  double getNetBalance({DateTime? start, DateTime? end});
  Map<String, double> getCategoryBreakdown({DateTime? start, DateTime? end});
  Map<String, double> getMonthlySpendTrend({int months = 6});
  Map<String, double> getTopMerchants({int limit = 5, DateTime? start, DateTime? end});
}
