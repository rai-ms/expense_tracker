import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../base/base_service/base_service.dart';
import '../../base/logger/app_logger.dart';

/// Local notification service for bill payment reminders
class NotificationService extends BaseService<Future<void>, void> {
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._();

  @override
  Future<void> init({void param}) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          Log.i('Notification tapped: ${details.payload}');
        },
      );
      Log.i('NotificationService initialized successfully.');
    } catch (e, stack) {
      Log.e('Failed to initialize NotificationService', error: e, stackTrace: stack);
    }
  }

  /// Show an instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bill_reminders_channel',
      'Bill Reminders',
      channelDescription: 'Notifications for upcoming bills and payment dues',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Show budget alert notification
  Future<void> showBudgetAlertNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_alerts_channel',
      'Budget Alerts',
      channelDescription: 'Alerts when approaching or exceeding category spending limits',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
