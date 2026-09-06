import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/bloc_base/base_bloc.dart';
import '../../../../core/base/bloc_base/bloc_event.dart';
import '../../../../core/services/event_bus/app_events.dart';
import '../../../../data/models/transaction_entity.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

@injectable
class TransactionsBloc extends BaseBloc<TransactionsEvent, TransactionsData> {
  final ITransactionRepository _transactionRepository;

  TransactionDateFilter _currentDateFilter = TransactionDateFilter.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;
  String? _currentType = 'all';
  String? _currentCategory;
  String? _currentPlatform;
  String? _currentSearch;

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
      _currentDateFilter = event.dateFilter;
      _customStart = event.customStartDate;
      _customEnd = event.customEndDate;
      _currentType = event.selectedType ?? 'all';
      _currentCategory = event.selectedCategory;
      _currentPlatform = event.selectedPlatform;
      _currentSearch = event.searchQuery;

      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;
      String dateLabel = 'This Month';

      switch (event.dateFilter) {
        case TransactionDateFilter.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          dateLabel = DateFormat('MMMM yyyy').format(now);
          break;
        case TransactionDateFilter.lastMonth:
          startDate = DateTime(now.year, now.month - 1, 1);
          endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          dateLabel = DateFormat('MMMM yyyy').format(startDate);
          break;
        case TransactionDateFilter.allTime:
          startDate = null;
          endDate = null;
          dateLabel = 'All Time';
          break;
        case TransactionDateFilter.custom:
          startDate = event.customStartDate;
          endDate = event.customEndDate;
          if (startDate != null && endDate != null) {
            final f = DateFormat('dd MMM');
            dateLabel = '${f.format(startDate)} - ${f.format(endDate)}';
          } else {
            dateLabel = 'Custom Range';
          }
          break;
      }

      final all = (startDate != null && endDate != null)
          ? _transactionRepository.getTransactionsByDateRange(startDate, endDate)
          : _transactionRepository.getAllTransactions();

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

      // Calculate totals for this filtered slice
      double income = 0;
      double expense = 0;
      for (final t in filtered) {
        if (t.isCredit) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }

      emitSuccess(
        data: TransactionsData(
          transactions: filtered,
          searchQuery: event.searchQuery,
          selectedCategory: event.selectedCategory,
          selectedType: event.selectedType ?? 'all',
          selectedPlatform: event.selectedPlatform,
          dateFilter: event.dateFilter,
          startDate: startDate,
          endDate: endDate,
          dateFilterLabel: dateLabel,
          totalIncome: income,
          totalExpense: expense,
          netBalance: income - expense,
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
      AppEvents.notifyDataChanged();
      add(
        LoadTransactionsEvent(
          searchQuery: _currentSearch,
          selectedCategory: _currentCategory,
          selectedType: _currentType,
          selectedPlatform: _currentPlatform,
          dateFilter: _currentDateFilter,
          customStartDate: _customStart,
          customEndDate: _customEnd,
        ),
      );
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
      AppEvents.notifyDataChanged();
      add(
        LoadTransactionsEvent(
          searchQuery: _currentSearch,
          selectedCategory: _currentCategory,
          selectedType: _currentType,
          selectedPlatform: _currentPlatform,
          dateFilter: _currentDateFilter,
          customStartDate: _customStart,
          customEndDate: _customEnd,
        ),
      );
    } catch (e) {
      emitFailed(message: 'Failed to add transaction: $e');
    }
  }
}
