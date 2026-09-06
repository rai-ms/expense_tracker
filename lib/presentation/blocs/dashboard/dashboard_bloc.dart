import '../../../core/base/bloc_base/base_bloc.dart';
import '../../../core/base/bloc_base/bloc_event.dart';
import '../../../core/services/sms_sync_service/sms_sync_service.dart';
import '../../../data/models/transaction_entity.dart';
import '../../../domain/repositories/i_transaction_repository.dart';

// Dashboard Events
abstract class DashboardEvent extends BlocEvent {
  const DashboardEvent();
}

class LoadDashboardDataEvent extends DashboardEvent {}

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

  const DashboardData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.todaySpend,
    required this.monthlyBudget,
    required this.recentTransactions,
    required this.categoryBreakdown,
  });

  DashboardData copyWith({
    double? totalBalance,
    double? totalIncome,
    double? totalExpense,
    double? todaySpend,
    double? monthlyBudget,
    List<TransactionEntity>? recentTransactions,
    Map<String, double>? categoryBreakdown,
  }) {
    return DashboardData(
      totalBalance: totalBalance ?? this.totalBalance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      todaySpend: todaySpend ?? this.todaySpend,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
    );
  }
}

// Dashboard BLoC
class DashboardBloc extends BaseBloc<DashboardEvent, DashboardData> {
  final ITransactionRepository _transactionRepository;
  final SmsSyncService _smsSyncService;

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
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final totalIncome = _transactionRepository.getTotalIncome(start: startOfMonth, end: endOfMonth);
      final totalExpense = _transactionRepository.getTotalExpense(start: startOfMonth, end: endOfMonth);
      final totalBalance = _transactionRepository.getNetBalance();

      final todayTxns = _transactionRepository.getTransactionsByDateRange(startOfDay, endOfDay);
      double todaySpend = 0.0;
      for (final t in todayTxns) {
        if (t.isDebit) todaySpend += t.amount;
      }

      final recent = _transactionRepository.getRecentTransactions(limit: 8);
      final categoryBreakdown = _transactionRepository.getCategoryBreakdown(start: startOfMonth, end: endOfMonth);

      emitSuccess(
        data: DashboardData(
          totalBalance: totalBalance,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          todaySpend: todaySpend,
          monthlyBudget: 50000.0, // Default configurable budget
          recentTransactions: recent,
          categoryBreakdown: categoryBreakdown,
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
      int addedCount = 0;

      for (final parsed in parsedList) {
        // Skip if already in DB
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
        addedCount++;
      }

      if (addedCount > 0) {
        // Log transaction sync count
      }

      // Reload dashboard stats
      add(LoadDashboardDataEvent());
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
      add(LoadDashboardDataEvent());
    } catch (e) {
      emitFailed(message: 'Failed to add transaction: $e');
    }
  }
}
