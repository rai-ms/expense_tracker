import 'package:injectable/injectable.dart';

import '../notification_service/notification_service.dart';
import '../objectbox_service/objectbox_service.dart';

@module
abstract class RegisterModule {
  @preResolve
  @singleton
  Future<ObjectBoxService> get objectBoxService async {
    final service = ObjectBoxService.instance;
    await service.init();
    return service;
  }

  @preResolve
  @singleton
  Future<NotificationService> get notificationService async {
    final service = NotificationService.instance;
    await service.init();
    return service;
  }
}
