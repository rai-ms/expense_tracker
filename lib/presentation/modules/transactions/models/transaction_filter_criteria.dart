

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

  Map<String, dynamic> toJson() {
    return {
      'dateFilter': dateFilter.name,
      'customStartDate': customStartDate?.toIso8601String(),
      'customEndDate': customEndDate?.toIso8601String(),
      'types': types.toList(),
      'categories': categories.toList(),
      'platforms': platforms.toList(),
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'sortBy': sortBy.name,
      'searchQuery': searchQuery,
    };
  }

  factory TransactionFilterCriteria.fromJson(Map<String, dynamic> json) {
    TransactionDateFilter df = TransactionDateFilter.thisMonth;
    for (final val in TransactionDateFilter.values) {
      if (val.name == json['dateFilter']) {
        df = val;
        break;
      }
    }

    TransactionSortBy sb = TransactionSortBy.dateNewest;
    for (final val in TransactionSortBy.values) {
      if (val.name == json['sortBy']) {
        sb = val;
        break;
      }
    }

    return TransactionFilterCriteria(
      dateFilter: df,
      customStartDate: json['customStartDate'] != null
          ? DateTime.tryParse(json['customStartDate'] as String)
          : null,
      customEndDate: json['customEndDate'] != null
          ? DateTime.tryParse(json['customEndDate'] as String)
          : null,
      types: (json['types'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {},
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {},
      platforms: (json['platforms'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? {},
      minAmount: (json['minAmount'] as num?)?.toDouble(),
      maxAmount: (json['maxAmount'] as num?)?.toDouble(),
      sortBy: sb,
      searchQuery: json['searchQuery'] as String?,
    );
  }
}
