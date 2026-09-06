part of 'transactions_bloc.dart';

/// State data class holding filtered transactions, criteria and summaries
class TransactionsData {
  final List<TransactionEntity> transactions;
  final TransactionFilterCriteria criteria;
  final String dateFilterLabel;
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final List<String> availableCategories;
  final List<String> availablePlatforms;

  const TransactionsData({
    required this.transactions,
    this.criteria = const TransactionFilterCriteria(),
    this.dateFilterLabel = 'This Month',
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.netBalance = 0.0,
    this.availableCategories = const [],
    this.availablePlatforms = const [],
  });

  // Backward compatibility convenience getters
  String? get searchQuery => criteria.searchQuery;
  String? get selectedCategory =>
      criteria.categories.isEmpty ? null : criteria.categories.first;
  String get selectedType =>
      criteria.types.isEmpty ? 'all' : criteria.types.first;
  String? get selectedPlatform =>
      criteria.platforms.isEmpty ? null : criteria.platforms.first;
  TransactionDateFilter get dateFilter => criteria.dateFilter;
  DateTime? get startDate => criteria.customStartDate;
  DateTime? get endDate => criteria.customEndDate;
}
