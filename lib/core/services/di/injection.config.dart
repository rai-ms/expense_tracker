// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../../data/repositories/khata_repository_impl.dart' as _i497;
import '../../../data/repositories/reminder_repository_impl.dart' as _i36;
import '../../../data/repositories/transaction_repository_impl.dart' as _i597;
import '../../../domain/repositories/i_khata_repository.dart' as _i904;
import '../../../domain/repositories/i_reminder_repository.dart' as _i654;
import '../../../domain/repositories/i_transaction_repository.dart' as _i545;
import '../../../presentation/modules/analytics/bloc/analytics_bloc.dart'
    as _i61;
import '../../../presentation/modules/dashboard/bloc/dashboard_bloc.dart'
    as _i896;
import '../../../presentation/modules/khata/bloc/khata_bloc.dart' as _i433;
import '../../../presentation/modules/reminders/bloc/reminders_bloc.dart'
    as _i459;
import '../../../presentation/modules/settings/bloc/locale_bloc.dart' as _i834;
import '../../../presentation/modules/transactions/bloc/transactions_bloc.dart'
    as _i900;
import '../budget_service/budget_service.dart' as _i251;
import '../notification_service/notification_service.dart' as _i333;
import '../objectbox_service/objectbox_service.dart' as _i1038;
import '../receipt_service/receipt_service.dart' as _i349;
import '../security_service/security_service.dart' as _i590;
import '../sms_parser_service/ignored_rule_service.dart' as _i475;
import '../sms_sync_service/sms_sync_service.dart' as _i206;
import '../split_bill_service/split_bill_service.dart' as _i830;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.singletonAsync<_i1038.ObjectBoxService>(
      () => registerModule.objectBoxService,
      preResolve: true,
    );
    await gh.singletonAsync<_i333.NotificationService>(
      () => registerModule.notificationService,
      preResolve: true,
    );
    gh.singleton<_i475.IgnoredRuleService>(() => _i475.IgnoredRuleService());
    gh.singleton<_i834.LocaleBloc>(() => _i834.LocaleBloc());
    gh.lazySingleton<_i251.BudgetService>(() => _i251.BudgetService());
    gh.lazySingleton<_i349.ReceiptService>(() => _i349.ReceiptService());
    gh.lazySingleton<_i590.SecurityService>(() => _i590.SecurityService());
    gh.lazySingleton<_i545.ITransactionRepository>(
      () => _i597.TransactionRepositoryImpl(gh<_i1038.ObjectBoxService>()),
    );
    gh.lazySingleton<_i206.SmsSyncService>(
      () => _i206.SmsSyncService(gh<_i475.IgnoredRuleService>()),
    );
    gh.lazySingleton<_i654.IReminderRepository>(
      () => _i36.ReminderRepositoryImpl(gh<_i1038.ObjectBoxService>()),
    );
    gh.lazySingleton<_i904.IKhataRepository>(
      () => _i497.KhataRepositoryImpl(gh<_i1038.ObjectBoxService>()),
    );
    gh.factory<_i896.DashboardBloc>(
      () => _i896.DashboardBloc(
        gh<_i545.ITransactionRepository>(),
        gh<_i206.SmsSyncService>(),
        gh<_i251.BudgetService>(),
      ),
    );
    gh.lazySingleton<_i830.SplitBillService>(
      () => _i830.SplitBillService(
        gh<_i904.IKhataRepository>(),
        gh<_i545.ITransactionRepository>(),
      ),
    );
    gh.factory<_i61.AnalyticsBloc>(
      () => _i61.AnalyticsBloc(gh<_i545.ITransactionRepository>()),
    );
    gh.factory<_i433.KhataBloc>(
      () => _i433.KhataBloc(gh<_i904.IKhataRepository>()),
    );
    gh.factory<_i900.TransactionsBloc>(
      () => _i900.TransactionsBloc(
        gh<_i545.ITransactionRepository>(),
        gh<_i475.IgnoredRuleService>(),
      ),
    );
    gh.factory<_i459.RemindersBloc>(
      () => _i459.RemindersBloc(gh<_i654.IReminderRepository>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
