import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles local notifications for approaching alerts, wake-up alarms,
/// and ongoing journey status updates.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const int stage1NotificationId = 1001;
  static const int stage2NotificationId = 1002;
  static const int journeyStatusNotificationId = 1003;

  static const String stage1ChannelId = 'wakeme_approaching_channel';
  static const String stage2ChannelId = 'wakeme_wakeup_channel';
  static const String statusChannelId = 'wakeme_status_channel';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          // App opened from notification
        },
      );
      _isInitialized = true;
    } catch (_) {
      // In test or unsupported environments
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImplementation?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Trigger Stage 1 Approaching alert notification
  Future<void> showApproachingNotification({
    required String destinationName,
    required double distanceKm,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      stage1ChannelId,
      'Approaching Alerts',
      channelDescription: 'Alerts when approaching within configured radius',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      styleInformation: BigTextStyleInformation(''),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: stage1NotificationId,
        title: '📍 Approaching: $destinationName',
        body: 'You are within ${distanceKm.toStringAsFixed(1)} km of your stop! Prepare your belongings.',
        notificationDetails: details,
      );
    } catch (_) {}
  }

  /// Trigger Stage 2 Urgent Wake Up alarm notification
  Future<void> showWakeUpNotification({
    required String destinationName,
    required double distanceKm,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      stage2ChannelId,
      'Wake Up Alarms',
      channelDescription: 'Critical wake up alarms when arriving at destination',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      styleInformation: BigTextStyleInformation(''),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: stage2NotificationId,
        title: '🚨 WAKE UP! Arriving at $destinationName',
        body: 'You are now within ${distanceKm.toStringAsFixed(1)} km! Your stop is next.',
        notificationDetails: details,
      );
    } catch (_) {}
  }

  /// Shows an ongoing low-noise status notification while journey is active
  Future<void> showJourneyStatusNotification({
    required String destinationName,
    required String formattedDistance,
    required double progressPercent,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      statusChannelId,
      'Journey Status',
      channelDescription: 'Live distance updates during active journeys',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: (progressPercent * 100).round(),
      playSound: false,
      enableVibration: false,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(
        id: journeyStatusNotificationId,
        title: 'WakeMe: Tracking to $destinationName',
        body: 'Remaining distance: $formattedDistance',
        notificationDetails: details,
      );
    } catch (_) {}
  }

  Future<void> cancelJourneyStatus() async {
    try {
      await _notificationsPlugin.cancel(id: journeyStatusNotificationId);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }
}
