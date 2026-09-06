import '../../../core/base/bloc_base/base_bloc.dart';
import '../../../core/base/bloc_base/bloc_event.dart';
import '../../../data/models/transaction_entity.dart';
import '../../../domain/repositories/i_transaction_repository.dart';

// Transactions Events
abstract class TransactionsEvent extends BlocEvent {
  const TransactionsEvent();
}

class LoadTransactionsEvent extends TransactionsEvent {
  final String? searchQuery;
  final String? selectedCategory;
  final String? selectedType; // 'all', 'debit', 'credit'
  final String? selectedPlatform;

  const LoadTransactionsEvent({
    this.searchQuery,
    this.selectedCategory,
    this.selectedType,
    this.selectedPlatform,
  });

  @override
  List<Object?> get props => [
        searchQuery,
        selectedCategory,
        selectedType,
        selectedPlatform,
      ];
}

class DeleteTransactionEvent extends TransactionsEvent {
  final int transactionId;
  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class AddTransactionEvent extends TransactionsEvent {
  final TransactionEntity transaction;
  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

// Transactions State Data
class TransactionsData {
  final List<TransactionEntity> transactions;
  final String? searchQuery;
  final String? selectedCategory;
  final String selectedType;
  final String? selectedPlatform;

  const TransactionsData({
    required this.transactions,
    this.searchQuery,
    this.selectedCategory,
    this.selectedType = 'all',
    this.selectedPlatform,
  });
}

// Transactions BLoC
class TransactionsBloc extends BaseBloc<TransactionsEvent, TransactionsData> {
  final ITransactionRepository _transactionRepository;

  TransactionsBloc(this._transactionRepository) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<AddTransactionEvent>(_onAddTransaction);
  }

  void _onLoadTransactions(
    LoadTransactionsEvent event,
    dynamic emit,
  ) {
    emitLoading();
    try {
      final all = _transactionRepository.getAllTransactions();

      var filtered = all;

      // Filter by type
      if (event.selectedType != null && event.selectedType != 'all') {
        filtered = filtered
            .where((t) => t.type.toLowerCase() == event.selectedType!.toLowerCase())
            .toList();
      }

      // Filter by category
      if (event.selectedCategory != null && event.selectedCategory!.isNotEmpty) {
        filtered = filtered
            .where((t) => t.category.toLowerCase() == event.selectedCategory!.toLowerCase())
            .toList();
      }

      // Filter by platform
      if (event.selectedPlatform != null && event.selectedPlatform!.isNotEmpty) {
        filtered = filtered
            .where((t) =>
                t.platform?.toLowerCase() == event.selectedPlatform!.toLowerCase())
            .toList();
      }

      // Filter by search query
      if (event.searchQuery != null && event.searchQuery!.trim().isNotEmpty) {
        final query = event.searchQuery!.toLowerCase().trim();
        filtered = filtered.where((t) {
          final merchantMatch = t.merchant?.toLowerCase().contains(query) ?? false;
          final categoryMatch = t.category.toLowerCase().contains(query);
          final notesMatch = t.notes?.toLowerCase().contains(query) ?? false;
          final txnIdMatch = t.transactionId?.toLowerCase().contains(query) ?? false;
          final platformMatch = t.platform?.toLowerCase().contains(query) ?? false;
          return merchantMatch || categoryMatch || notesMatch || txnIdMatch || platformMatch;
        }).toList();
      }

      emitSuccess(
        data: TransactionsData(
          transactions: filtered,
          searchQuery: event.searchQuery,
          selectedCategory: event.selectedCategory,
          selectedType: event.selectedType ?? 'all',
          selectedPlatform: event.selectedPlatform,
        ),
      );
    } catch (e) {
      emitFailed(message: 'Failed to load transactions: $e');
    }
  }

  void _onDeleteTransaction(
    DeleteTransactionEvent event,
    dynamic emit,
  ) {
    try {
      _transactionRepository.deleteTransaction(event.transactionId);
      add(const LoadTransactionsEvent());
    } catch (e) {
      emitFailed(message: 'Failed to delete transaction: $e');
    }
  }

  void _onAddTransaction(
    AddTransactionEvent event,
    dynamic emit,
  ) {
    try {
      _transactionRepository.addTransaction(event.transaction);
      add(const LoadTransactionsEvent());
    } catch (e) {
      emitFailed(message: 'Failed to add transaction: $e');
    }
  }
}
