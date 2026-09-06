import 'package:intl/intl.dart';

import '../../../core/base/bloc_base/base_bloc.dart';
import '../../../core/base/bloc_base/bloc_event.dart';
import '../../../core/services/event_bus/app_events.dart';
import '../../../core/services/sms_sync_service/sms_sync_service.dart';
import '../../../data/models/transaction_entity.dart';
import '../../../domain/repositories/i_transaction_repository.dart';

enum DashboardDateFilter {
  thisMonth,
  lastMonth,
  allTime,
  custom,
}

// Dashboard Events
abstract class DashboardEvent extends BlocEvent {
  const DashboardEvent();
}

class LoadDashboardDataEvent extends DashboardEvent {
  final DashboardDateFilter filter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const LoadDashboardDataEvent({
    this.filter = DashboardDateFilter.thisMonth,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  List<Object?> get props => [filter, customStartDate, customEndDate];
}

class SyncSmsEvent extends DashboardEvent {
  final DateTime? fromDate;
  final DateTime? toDate;
  final int limit;

  const SyncSmsEvent({
    this.fromDate,
    this.toDate,
    this.limit = 500,
  });

  @override
  List<Object?> get props => [fromDate, toDate, limit];
}

class AddQuickTransactionEvent extends DashboardEvent {
  final TransactionEntity transaction;
  const AddQuickTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

// Dashboard State Data
class DashboardData {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final double todaySpend;
  final double monthlyBudget;
  final List<TransactionEntity> recentTransactions;
  final Map<String, double> categoryBreakdown;
  final DashboardDateFilter activeFilter;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String filterLabel;

  const DashboardData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.todaySpend,
    required this.monthlyBudget,
    required this.recentTransactions,
    required this.categoryBreakdown,
    this.activeFilter = DashboardDateFilter.thisMonth,
    this.filterStartDate,
    this.filterEndDate,
    this.filterLabel = 'This Month',
  });

  DashboardData copyWith({
    double? totalBalance,
    double? totalIncome,
    double? totalExpense,
    double? todaySpend,
    double? monthlyBudget,
    List<TransactionEntity>? recentTransactions,
    Map<String, double>? categoryBreakdown,
    DashboardDateFilter? activeFilter,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? filterLabel,
  }) {
    return DashboardData(
      totalBalance: totalBalance ?? this.totalBalance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      todaySpend: todaySpend ?? this.todaySpend,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      activeFilter: activeFilter ?? this.activeFilter,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
      filterLabel: filterLabel ?? this.filterLabel,
    );
  }
}

// Dashboard BLoC
class DashboardBloc extends BaseBloc<DashboardEvent, DashboardData> {
  final ITransactionRepository _transactionRepository;
  final SmsSyncService _smsSyncService;

  DashboardDateFilter _currentFilter = DashboardDateFilter.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  DashboardBloc(this._transactionRepository, this._smsSyncService) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<SyncSmsEvent>(_onSyncSms);
    on<AddQuickTransactionEvent>(_onAddQuickTransaction);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    dynamic emit,
  ) async {
    emitLoading();
    try {
      _currentFilter = event.filter;
      _customStart = event.customStartDate;
      _customEnd = event.customEndDate;

      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;
      String filterLabel = 'This Month';

      switch (event.filter) {
        case DashboardDateFilter.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          filterLabel = DateFormat('MMMM yyyy').format(now);
          break;
        case DashboardDateFilter.lastMonth:
          startDate = DateTime(now.year, now.month - 1, 1);
          endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          filterLabel = DateFormat('MMMM yyyy').format(startDate);
          break;
        case DashboardDateFilter.allTime:
          startDate = null;
          endDate = null;
          filterLabel = 'All Time';
          break;
        case DashboardDateFilter.custom:
          startDate = event.customStartDate;
          endDate = event.customEndDate;
          if (startDate != null && endDate != null) {
            final f = DateFormat('dd MMM');
            filterLabel = '${f.format(startDate)} - ${f.format(endDate)}';
          } else {
            filterLabel = 'Custom Range';
          }
          break;
      }

      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final totalIncome = _transactionRepository.getTotalIncome(start: startDate, end: endDate);
      final totalExpense = _transactionRepository.getTotalExpense(start: startDate, end: endDate);
      final totalBalance = _transactionRepository.getNetBalance(start: startDate, end: endDate);

      final todayTxns = _transactionRepository.getTransactionsByDateRange(startOfDay, endOfDay);
      double todaySpend = 0.0;
      for (final t in todayTxns) {
        if (t.isDebit) todaySpend += t.amount;
      }

      final recent = (startDate != null && endDate != null)
          ? _transactionRepository.getTransactionsByDateRange(startDate, endDate)
          : _transactionRepository.getRecentTransactions(limit: 8);

      final categoryBreakdown = _transactionRepository.getCategoryBreakdown(start: startDate, end: endDate);

      emitSuccess(
        data: DashboardData(
          totalBalance: totalBalance,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          todaySpend: todaySpend,
          monthlyBudget: 50000.0,
          recentTransactions: recent,
          categoryBreakdown: categoryBreakdown,
          activeFilter: event.filter,
          filterStartDate: startDate,
          filterEndDate: endDate,
          filterLabel: filterLabel,
        ),
      );
    } catch (e) {
      emitFailed(message: 'Failed to load dashboard data: $e');
    }
  }

  Future<void> _onSyncSms(
    SyncSmsEvent event,
    dynamic emit,
  ) async {
    try {
      final parsedList = await _smsSyncService.syncInbox(
        fromDate: event.fromDate,
        toDate: event.toDate,
        limit: event.limit,
      );

      bool addedAny = false;
      for (final parsed in parsedList) {
        if (parsed.transactionId != null &&
            _transactionRepository.hasTransactionWithTxnId(parsed.transactionId!)) {
          continue;
        }

        final entity = TransactionEntity(
          uid: parsed.uid,
          amount: parsed.amount,
          type: parsed.type,
          category: parsed.category,
          merchant: parsed.merchant,
          platform: parsed.platform,
          transactionId: parsed.transactionId,
          accountOrCard: parsed.accountOrCard,
          date: parsed.date.millisecondsSinceEpoch,
          rawSms: parsed.rawSms,
          balanceAfter: parsed.balanceAfter,
          isAutomated: true,
        );

        _transactionRepository.addTransaction(entity);
        addedAny = true;
      }

      if (addedAny) {
        AppEvents.notifyDataChanged();
      }

      // Reload with active filter
      add(LoadDashboardDataEvent(
        filter: _currentFilter,
        customStartDate: _customStart,
        customEndDate: _customEnd,
      ));
    } catch (e) {
      emitFailed(message: 'Error during SMS sync: $e');
    }
  }

  Future<void> _onAddQuickTransaction(
    AddQuickTransactionEvent event,
    dynamic emit,
  ) async {
    try {
      _transactionRepository.addTransaction(event.transaction);
      AppEvents.notifyDataChanged();
      add(LoadDashboardDataEvent(
        filter: _currentFilter,
        customStartDate: _customStart,
        customEndDate: _customEnd,
      ));
    } catch (e) {
      emitFailed(message: 'Failed to add transaction: $e');
    }
  }
}
