import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationController {
  NotificationController() {
    _init();
  }

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> _init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);
    // Create notification channel for conversions
    const channel = AndroidNotificationChannel(
      'conversion_channel',
      'Conversions',
      description: 'Shows conversion progress',
      importance: Importance.low,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestPermission() async {
    // No explicit permission request needed for Android notifications.
    // Permissions are handled by the OS (e.g., POST_NOTIFICATIONS).
  }

  Future<void> showProgress({
    required String title,
    required String body,
    required int progress,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'conversion_channel',
      'Conversions',
      channelDescription: 'Conversion progress',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: true,
    );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> updateProgress(int progress) async {
    await showProgress(
      title: 'Converting...',
      body: 'Progress',
      progress: progress,
    );
  }

  Future<void> showSuccess({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'conversion_channel',
      'Conversions',
      channelDescription: 'Conversion progress',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> showFailure({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'conversion_channel',
      'Conversions',
      channelDescription: 'Conversion progress',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> hide() async {
    await _plugin.cancel(id: 0);
  }
}
