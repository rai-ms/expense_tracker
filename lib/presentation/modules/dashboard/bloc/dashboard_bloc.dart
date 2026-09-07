import 'package:bot_toast/bot_toast.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../../core/base/bloc_base/base_bloc.dart';
import '../../../../core/base/bloc_base/bloc_event.dart';
import '../../../../core/base/logger/app_logger.dart';
import '../../../../core/services/budget_service/budget_service.dart';
import '../../../../core/services/di/injection.dart';
import '../../../../core/services/event_bus/app_events.dart';
import '../../../../core/services/objectbox_service/objectbox_service.dart';
import '../../../../core/services/sms_sync_service/sms_sync_service.dart';
import '../../../../data/models/transaction_entity.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

@injectable
class DashboardBloc extends BaseBloc<DashboardEvent, DashboardData> {
  static const String _prefMonthlyBudgetKey = 'user_monthly_budget_amount';
  static const String _prefLastSyncTimeKey = 'last_sms_sync_time';

  final ITransactionRepository _transactionRepository;
  final SmsSyncService _smsSyncService;
  final BudgetService _budgetService;

  DashboardDateFilter _currentFilter = DashboardDateFilter.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  DashboardBloc(
    this._transactionRepository,
    this._smsSyncService,
    this._budgetService,
  ) {
    on<LoadDashboardDataEvent>(_onLoadDashboardData);
    on<SyncSmsEvent>(_onSyncSms);
    on<AutoSyncSmsEvent>(_onAutoSyncSms);
    on<AddQuickTransactionEvent>(_onAddQuickTransaction);
    on<UpdateMonthlyBudgetEvent>(_onUpdateMonthlyBudget);
    on<SetCategoryBudgetEvent>(_onSetCategoryBudget);
    on<DeleteCategoryBudgetEvent>(_onDeleteCategoryBudget);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardDataEvent event,
    dynamic emit,
  ) async {
    emitLoading();
    try {
      _transactionRepository.cleanDuplicateTransactions();

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
      final categoryBudgets = _budgetService.getCategoryBudgets();

      // If viewing current month, evaluate overspend push alerts
      if (event.filter == DashboardDateFilter.thisMonth) {
        _budgetService.checkAndTriggerAlerts(categoryBreakdown);
      }

      final monthlyBudget = ObjectBoxService.instance.getDoubleSetting(_prefMonthlyBudgetKey, defaultValue: 50000.0);

      emitSuccess(
        data: DashboardData(
          totalBalance: totalBalance,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          todaySpend: todaySpend,
          monthlyBudget: monthlyBudget,
          recentTransactions: recent,
          categoryBreakdown: categoryBreakdown,
          categoryBudgets: categoryBudgets,
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
      final toDate = event.toDate ?? DateTime.now();
      await _syncAndPersist(fromDate: event.fromDate, toDate: toDate, limit: event.limit);

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

  /// Silently syncs SMS since the last recorded sync time. Runs once when the
  /// dashboard is first opened so the user never has to manually sync just to
  /// see transactions that arrived since the app was last used.
  Future<void> _onAutoSyncSms(
    AutoSyncSmsEvent event,
    dynamic emit,
  ) async {
    try {
      final hasPermission = await _smsSyncService.hasSmsPermission();
      if (!hasPermission) return;

      final lastSyncMillis = ObjectBoxService.instance.getIntSetting(_prefLastSyncTimeKey);
      final fromDate = lastSyncMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMillis)
          : DateTime.now().subtract(const Duration(days: 30));
      final toDate = DateTime.now();

      final addedCount = await _syncAndPersist(fromDate: fromDate, toDate: toDate, limit: 1000);

      if (addedCount > 0) {
        BotToast.showText(text: '$addedCount new transaction${addedCount == 1 ? '' : 's'} synced');
        add(LoadDashboardDataEvent(
          filter: _currentFilter,
          customStartDate: _customStart,
          customEndDate: _customEnd,
        ));
      }
    } catch (e) {
      Log.e('Auto SMS sync failed: $e');
    }
  }

  /// Parses inbox SMS in [fromDate, toDate], inserts new transactions, and
  /// persists [toDate] as the last-sync checkpoint. Returns the number added.
  Future<int> _syncAndPersist({
    required DateTime? fromDate,
    required DateTime toDate,
    required int limit,
  }) async {
    final parsedList = await _smsSyncService.syncInbox(
      fromDate: fromDate,
      toDate: toDate,
      limit: limit,
    );

    int addedCount = 0;
    for (final parsed in parsedList) {
      if (_transactionRepository.isDuplicateParsed(parsed)) {
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
      addedCount++;
    }

    if (addedCount > 0) {
      AppEvents.notifyDataChanged();
    }

    ObjectBoxService.instance.setIntSetting(_prefLastSyncTimeKey, toDate.millisecondsSinceEpoch);
    return addedCount;
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

  Future<void> _onUpdateMonthlyBudget(
    UpdateMonthlyBudgetEvent event,
    dynamic emit,
  ) async {
    try {
      ObjectBoxService.instance.setDoubleSetting(_prefMonthlyBudgetKey, event.newBudget);
      add(LoadDashboardDataEvent(
        filter: _currentFilter,
        customStartDate: _customStart,
        customEndDate: _customEnd,
      ));
    } catch (e) {
      emitFailed(message: 'Failed to update monthly budget: $e');
    }
  }

  Future<void> _onSetCategoryBudget(
    SetCategoryBudgetEvent event,
    dynamic emit,
  ) async {
    try {
      await _budgetService.setCategoryBudget(event.category, event.amount);
      add(LoadDashboardDataEvent(
        filter: _currentFilter,
        customStartDate: _customStart,
        customEndDate: _customEnd,
      ));
    } catch (e) {
      emitFailed(message: 'Failed to update category budget: $e');
    }
  }

  Future<void> _onDeleteCategoryBudget(
    DeleteCategoryBudgetEvent event,
    dynamic emit,
  ) async {
    try {
      await _budgetService.removeCategoryBudget(event.category);
      add(LoadDashboardDataEvent(
        filter: _currentFilter,
        customStartDate: _customStart,
        customEndDate: _customEnd,
      ));
    } catch (e) {
      emitFailed(message: 'Failed to delete category budget: $e');
    }
  }
}
