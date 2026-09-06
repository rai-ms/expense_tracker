import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/bloc_base/base_bloc.dart';
import '../../../../core/base/bloc_base/bloc_event.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/event_bus/app_events.dart';
import '../../../../core/services/sms_parser_service/ignored_rule_service.dart';
import '../../../../data/models/transaction_entity.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../models/transaction_filter_criteria.dart';
export '../models/transaction_filter_criteria.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

@injectable
class TransactionsBloc extends BaseBloc<TransactionsEvent, TransactionsData> {
  final ITransactionRepository _transactionRepository;
  final IgnoredRuleService _ignoredRuleService;

  TransactionFilterCriteria _currentCriteria = const TransactionFilterCriteria();

  TransactionsBloc(this._transactionRepository, this._ignoredRuleService) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<AddTransactionEvent>(_onAddTransaction);
    on<ToggleIgnoreTransactionEvent>(_onToggleIgnoreTransaction);
  }

  void _onLoadTransactions(
    LoadTransactionsEvent event,
    dynamic emit,
  ) {
    emitLoading();
    try {
      _currentCriteria = event.criteria;

      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;
      String dateLabel = 'This Month';

      switch (_currentCriteria.dateFilter) {
        case TransactionDateFilter.today:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          dateLabel = 'Today';
          break;
        case TransactionDateFilter.thisWeek:
          final weekday = now.weekday; // 1 = Monday
          startDate = DateTime(now.year, now.month, now.day - (weekday - 1));
          endDate = DateTime(now.year, now.month, now.day + (7 - weekday), 23, 59, 59);
          dateLabel = 'This Week';
          break;
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
          startDate = _currentCriteria.customStartDate;
          endDate = _currentCriteria.customEndDate;
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

      var filtered = List<TransactionEntity>.from(all);

      // 1. Filter by Types (Multi-select)
      if (_currentCriteria.types.isNotEmpty) {
        final typesLower = _currentCriteria.types.map((t) => t.toLowerCase()).toSet();
        final includesIgnored = typesLower.contains('ignored') || typesLower.contains('notifications');
        final includesDebit = typesLower.contains('debit');
        final includesCredit = typesLower.contains('credit');

        filtered = filtered.where((t) {
          if (t.isIgnored) {
            return includesIgnored;
          } else {
            if (includesDebit && t.isDebit) return true;
            if (includesCredit && t.isCredit) return true;
            if (!includesDebit && !includesCredit && includesIgnored) return false;
            return false;
          }
        }).toList();
      } else {
        // Default: only active valid transactions (exclude ignored notifications)
        filtered = filtered.where((t) => !t.isIgnored).toList();
      }

      // 2. Filter by Categories (Multi-select)
      if (_currentCriteria.categories.isNotEmpty) {
        final catSet = _currentCriteria.categories.map((c) => c.toLowerCase()).toSet();
        filtered = filtered.where((t) => catSet.contains(t.category.toLowerCase())).toList();
      }

      // 3. Filter by Platforms / Banks (Multi-select)
      if (_currentCriteria.platforms.isNotEmpty) {
        final platSet = _currentCriteria.platforms.map((p) => p.toLowerCase()).toSet();
        filtered = filtered.where((t) {
          if (t.platform == null) return false;
          return platSet.contains(t.platform!.toLowerCase());
        }).toList();
      }

      // 4. Filter by Amount Range
      if (_currentCriteria.minAmount != null) {
        filtered = filtered.where((t) => t.amount >= _currentCriteria.minAmount!).toList();
      }
      if (_currentCriteria.maxAmount != null) {
        filtered = filtered.where((t) => t.amount <= _currentCriteria.maxAmount!).toList();
      }

      // 5. Filter by Search Query
      if (_currentCriteria.searchQuery != null && _currentCriteria.searchQuery!.trim().isNotEmpty) {
        final query = _currentCriteria.searchQuery!.toLowerCase().trim();
        filtered = filtered.where((t) {
          final merchantMatch = t.merchant?.toLowerCase().contains(query) ?? false;
          final categoryMatch = t.category.toLowerCase().contains(query);
          final notesMatch = t.notes?.toLowerCase().contains(query) ?? false;
          final txnIdMatch = t.transactionId?.toLowerCase().contains(query) ?? false;
          final platformMatch = t.platform?.toLowerCase().contains(query) ?? false;
          final amountMatch = t.amount.toString().contains(query);
          return merchantMatch || categoryMatch || notesMatch || txnIdMatch || platformMatch || amountMatch;
        }).toList();
      }

      // 6. Sorting
      switch (_currentCriteria.sortBy) {
        case TransactionSortBy.dateNewest:
          filtered.sort((a, b) => b.date.compareTo(a.date));
          break;
        case TransactionSortBy.dateOldest:
          filtered.sort((a, b) => a.date.compareTo(b.date));
          break;
        case TransactionSortBy.amountHighToLow:
          filtered.sort((a, b) => b.amount.compareTo(a.amount));
          break;
        case TransactionSortBy.amountLowToHigh:
          filtered.sort((a, b) => a.amount.compareTo(b.amount));
          break;
      }

      // Calculate totals for active non-ignored transactions in the filtered result
      double income = 0;
      double expense = 0;
      for (final t in filtered) {
        if (!t.isIgnored) {
          if (t.isCredit) {
            income += t.amount;
          } else {
            expense += t.amount;
          }
        }
      }

      // Collect available categories and platforms for filter bottom sheet
      final availableCats = AppConstants.getAllCategories()
          .map((c) => c['name'] as String)
          .toSet()
          .toList();
      final availablePlatforms = AppConstants.supportedPlatforms.toList();

      emitSuccess(
        data: TransactionsData(
          transactions: filtered,
          criteria: _currentCriteria,
          dateFilterLabel: dateLabel,
          totalIncome: income,
          totalExpense: expense,
          netBalance: income - expense,
          availableCategories: availableCats,
          availablePlatforms: availablePlatforms,
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
      add(LoadTransactionsEvent(criteria: _currentCriteria));
    } catch (e) {
      emitFailed(message: 'Failed to delete transaction: $e');
    }
  }

  Future<void> _onToggleIgnoreTransaction(
    ToggleIgnoreTransactionEvent event,
    dynamic emit,
  ) async {
    try {
      _transactionRepository.toggleIgnoredStatus(event.transactionId, event.isIgnored);

      if (event.isIgnored && event.ruleKeyword != null && event.ruleKeyword!.isNotEmpty) {
        await _ignoredRuleService.addIgnoredKeyword(event.ruleKeyword!);
      }
      if (event.isIgnored && event.ruleSender != null && event.ruleSender!.isNotEmpty) {
        await _ignoredRuleService.addIgnoredSender(event.ruleSender!);
      }

      AppEvents.notifyDataChanged();
      add(LoadTransactionsEvent(criteria: _currentCriteria));
    } catch (e) {
      emitFailed(message: 'Failed to update transaction ignore status: $e');
    }
  }

  void _onAddTransaction(
    AddTransactionEvent event,
    dynamic emit,
  ) {
    try {
      _transactionRepository.addTransaction(event.transaction);
      AppEvents.notifyDataChanged();
      add(LoadTransactionsEvent(criteria: _currentCriteria));
    } catch (e) {
      emitFailed(message: 'Failed to add transaction: $e');
    }
  }
}
