part of 'transactions_bloc.dart';

/// State data class holding filtered transactions and summaries
class TransactionsData {
  final List<TransactionEntity> transactions;
  final String? searchQuery;
  final String? selectedCategory;
  final String selectedType;
  final String? selectedPlatform;
  final TransactionDateFilter dateFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String dateFilterLabel;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;

  const TransactionsData({
    required this.transactions,
    this.searchQuery,
    this.selectedCategory,
    this.selectedType = 'all',
    this.selectedPlatform,
    this.dateFilter = TransactionDateFilter.thisMonth,
    this.startDate,
    this.endDate,
    this.dateFilterLabel = 'This Month',
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.netBalance = 0.0,
  });
}
