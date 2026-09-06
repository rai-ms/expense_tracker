part of 'transactions_bloc.dart';

enum TransactionDateFilter {
  thisMonth,
  lastMonth,
  allTime,
  custom,
}

/// Base class for all Transactions events
abstract class TransactionsEvent extends BlocEvent {
  const TransactionsEvent();
}

/// Event to load transactions with multiple filter criteria
class LoadTransactionsEvent extends TransactionsEvent {
  final String? searchQuery;
  final String? selectedCategory;
  final String? selectedType; // 'all', 'debit', 'credit'
  final String? selectedPlatform;
  final TransactionDateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const LoadTransactionsEvent({
    this.searchQuery,
    this.selectedCategory,
    this.selectedType = 'all',
    this.selectedPlatform,
    this.dateFilter = TransactionDateFilter.thisMonth,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  List<Object?> get props => [
        searchQuery,
        selectedCategory,
        selectedType,
        selectedPlatform,
        dateFilter,
        customStartDate,
        customEndDate,
      ];
}

/// Event to delete a transaction by ID
class DeleteTransactionEvent extends TransactionsEvent {
  final int transactionId;
  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

/// Event to add a new transaction
class AddTransactionEvent extends TransactionsEvent {
  final TransactionEntity transaction;
  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Event to mark/unmark a transaction as ignored notification
class ToggleIgnoreTransactionEvent extends TransactionsEvent {
  final int transactionId;
  final bool isIgnored;
  final String? ruleKeyword;
  final String? ruleSender;

  const ToggleIgnoreTransactionEvent(
    this.transactionId,
    this.isIgnored, {
    this.ruleKeyword,
    this.ruleSender,
  });

  @override
  List<Object?> get props => [transactionId, isIgnored, ruleKeyword, ruleSender];
}
