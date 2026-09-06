

enum TransactionDateFilter {
  thisMonth,
  today,
  thisWeek,
  lastMonth,
  allTime,
  custom,
}

enum TransactionSortBy {
  dateNewest,
  dateOldest,
  amountHighToLow,
  amountLowToHigh,
}

class TransactionFilterCriteria {
  final TransactionDateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final Set<String> types; // e.g. {'debit', 'credit'} or {'ignored'}
  final Set<String> categories; // e.g. {'Food & Dining', 'Groceries'}
  final Set<String> platforms; // e.g. {'Google Pay', 'HDFC Bank'}
  final double? minAmount;
  final double? maxAmount;
  final TransactionSortBy sortBy;
  final String? searchQuery;

  const TransactionFilterCriteria({
    this.dateFilter = TransactionDateFilter.thisMonth,
    this.customStartDate,
    this.customEndDate,
    this.types = const {},
    this.categories = const {},
    this.platforms = const {},
    this.minAmount,
    this.maxAmount,
    this.sortBy = TransactionSortBy.dateNewest,
    this.searchQuery,
  });

  /// Total count of active non-default filters
  int get activeFilterCount {
    int count = 0;
    if (dateFilter != TransactionDateFilter.thisMonth) count++;
    if (types.isNotEmpty) count += types.length;
    if (categories.isNotEmpty) count += categories.length;
    if (platforms.isNotEmpty) count += platforms.length;
    if (minAmount != null || maxAmount != null) count++;
    if (sortBy != TransactionSortBy.dateNewest) count++;
    return count;
  }

  bool get isDefault =>
      activeFilterCount == 0 && (searchQuery == null || searchQuery!.isEmpty);

  TransactionFilterCriteria copyWith({
    TransactionDateFilter? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    Set<String>? types,
    Set<String>? categories,
    Set<String>? platforms,
    double? minAmount,
    double? maxAmount,
    TransactionSortBy? sortBy,
    String? searchQuery,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return TransactionFilterCriteria(
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      types: types ?? this.types,
      categories: categories ?? this.categories,
      platforms: platforms ?? this.platforms,
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
