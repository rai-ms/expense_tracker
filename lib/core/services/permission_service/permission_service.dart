import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import '../../base/logger/app_logger.dart';

class PermissionService {
  PermissionService._();

  /// Request essential SMS and Notification permissions on startup
  static Future<void> requestAppPermissions() async {
    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.sms,
          Permission.notification,
        ].request();

        Log.i('Requested app permissions: $statuses');
      }
    } catch (e) {
      Log.e('Error requesting app permissions', error: e);
    }
  }

  /// Check if SMS permission is currently granted
  static Future<bool> isSmsGranted() async {
    if (!Platform.isAndroid) return false;
    return await Permission.sms.isGranted;
  }

  /// Request SMS permission specifically
  static Future<bool> requestSmsPermission() async {
    if (!Platform.isAndroid) return false;
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Request notification permission specifically
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Open app settings if user permanently denied permissions
  static Future<bool> openAppSettingsPage() async {
    return await openAppSettings();
  }
}
