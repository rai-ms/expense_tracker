import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/services/di/injection.dart';
import '../../../../core/services/sms_sync_service/sms_sync_service.dart';
import '../../../../data/models/transaction_entity.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../../../blocs/dashboard/dashboard_bloc.dart';
import '../../transactions/ui/widgets/add_transaction_modal.dart';
import '../../transactions/ui/widgets/transaction_detail_modal.dart';
import '../ui/dashboard_view.dart';
import '../ui/widgets/sync_sms_date_modal.dart';

class DashboardController extends StatefulWidget {
  const DashboardController({super.key});

  @override
  State<DashboardController> createState() => DashboardControllerState();
}

class DashboardControllerState extends State<DashboardController>
    with _DashboardMixin {
  late final DashboardBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = DashboardBloc(
      sl<ITransactionRepository>(),
      sl<SmsSyncService>(),
    );
    bloc.add(LoadDashboardDataEvent());
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardView(this);
  }
}

mixin _DashboardMixin on State<DashboardController> {
  DashboardControllerState get _state => this as DashboardControllerState;

  void onSyncSms() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SyncSmsDateModal(
        onSync: (fromDate, toDate, limit) {
          final dateFormat = DateFormat('dd MMM yyyy');
          _state.bloc.add(
            SyncSmsEvent(
              fromDate: fromDate,
              toDate: toDate,
              limit: limit,
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Syncing all SMS since ${dateFormat.format(fromDate)}...'),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  void onAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AddTransactionModal(
        onSave: (txn) {
          _state.bloc.add(AddQuickTransactionEvent(txn));
        },
      ),
    );
  }

  void onAddKhata() {
    context.push(AppRoutes.khata);
  }

  void onExportPdf() {
    context.push(AppRoutes.exportPdf);
  }

  void onSmsSimulator() {
    context.push(AppRoutes.smsSimulator).then((_) {
      _state.bloc.add(LoadDashboardDataEvent());
    });
  }

  void onViewAllTransactions() {
    context.push(AppRoutes.transactions);
  }

  void onTransactionTap(TransactionEntity txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailModal(
        transaction: txn,
        onDelete: () {
          sl<ITransactionRepository>().deleteTransaction(txn.id);
          _state.bloc.add(LoadDashboardDataEvent());
        },
      ),
    );
  }
}
