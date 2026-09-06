import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import '../../base/logger/app_logger.dart';

class PermissionService {
  PermissionService._();

  /// Request SMS and Notification permissions
  static Future<void> requestAppPermissions() async {
    try {
      if (Platform.isAndroid) {
        final smsStatus = await Permission.sms.request();
        final notifStatus = await Permission.notification.request();
        Log.i('Permissions: SMS = $smsStatus, Notifications = $notifStatus');
      }
    } catch (e) {
      Log.e('Error requesting app permissions', error: e);
    }
  }
}
