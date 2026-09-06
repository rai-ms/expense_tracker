import 'package:get_it/get_it.dart';

import '../../../data/repositories/khata_repository_impl.dart';
import '../../../data/repositories/reminder_repository_impl.dart';
import '../../../data/repositories/transaction_repository_impl.dart';
import '../../../domain/repositories/i_khata_repository.dart';
import '../../../domain/repositories/i_reminder_repository.dart';
import '../../../domain/repositories/i_transaction_repository.dart';
import '../../base/logger/app_logger.dart';
import '../notification_service/notification_service.dart';
import '../objectbox_service/objectbox_service.dart';
import '../sms_sync_service/sms_sync_service.dart';

final GetIt sl = GetIt.instance;

/// Initialize all app dependencies
Future<void> configureDependencies() async {
  try {
    // 1. Core Services
    final objectBoxService = ObjectBoxService.instance;
    await objectBoxService.init();
    sl.registerSingleton<ObjectBoxService>(objectBoxService);

    final notificationService = NotificationService.instance;
    await notificationService.init();
    sl.registerSingleton<NotificationService>(notificationService);

    sl.registerLazySingleton<SmsSyncService>(() => SmsSyncService());

    // 2. Repositories
    sl.registerLazySingleton<ITransactionRepository>(
      () => TransactionRepositoryImpl(sl<ObjectBoxService>()),
    );
    sl.registerLazySingleton<IKhataRepository>(
      () => KhataRepositoryImpl(sl<ObjectBoxService>()),
    );
    sl.registerLazySingleton<IReminderRepository>(
      () => ReminderRepositoryImpl(sl<ObjectBoxService>()),
    );

    Log.i('Dependencies configured successfully.');
  } catch (e, stack) {
    Log.e('Failed to configure dependencies', error: e, stackTrace: stack);
    rethrow;
  }
}
