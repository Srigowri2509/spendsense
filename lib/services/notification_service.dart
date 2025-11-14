import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/subscription.dart';

class NotificationSettings {
  bool enabled;
  bool notify3DaysBefore;
  bool notify1DayBefore;
  bool notifyOnDueDate;
  bool notifyRenewalReminders;

  NotificationSettings({
    this.enabled = true,
    this.notify3DaysBefore = true,
    this.notify1DayBefore = true,
    this.notifyOnDueDate = true,
    this.notifyRenewalReminders = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'notify3DaysBefore': notify3DaysBefore,
      'notify1DayBefore': notify1DayBefore,
      'notifyOnDueDate': notifyOnDueDate,
      'notifyRenewalReminders': notifyRenewalReminders,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      notify3DaysBefore: json['notify3DaysBefore'] as bool? ?? true,
      notify1DayBefore: json['notify1DayBefore'] as bool? ?? true,
      notifyOnDueDate: json['notifyOnDueDate'] as bool? ?? true,
      notifyRenewalReminders: json['notifyRenewalReminders'] as bool? ?? true,
    );
  }
}

class NotificationService {
  static const String _settingsKey = 'notification_settings';
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigation will be handled by the app when it receives this callback
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // Android 13+ requires runtime permission
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      // iOS permissions
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Schedule notifications for a subscription
  Future<void> scheduleSubscriptionNotifications(
    Subscription subscription,
    NotificationSettings settings,
  ) async {
    if (!settings.enabled) return;

    try {
      await initialize();

      final now = DateTime.now();
      final dueDate = subscription.nextBillingDate;

      // Schedule 3-day advance notification
      if (settings.notify3DaysBefore) {
        final notifyDate = dueDate.subtract(const Duration(days: 3));
        if (notifyDate.isAfter(now)) {
          await _scheduleNotification(
            id: _generateNotificationId(subscription.id, 3),
            title: 'Subscription Due in 3 Days',
            body: '${subscription.name} payment of ₹${subscription.amount.toStringAsFixed(0)} is due in 3 days',
            scheduledDate: notifyDate,
            payload: subscription.id,
          );
        }
      }

      // Schedule 1-day advance notification
      if (settings.notify1DayBefore) {
        final notifyDate = dueDate.subtract(const Duration(days: 1));
        if (notifyDate.isAfter(now)) {
          await _scheduleNotification(
            id: _generateNotificationId(subscription.id, 1),
            title: 'Subscription Due Tomorrow',
            body: '${subscription.name} payment of ₹${subscription.amount.toStringAsFixed(0)} is due tomorrow',
            scheduledDate: notifyDate,
            payload: subscription.id,
          );
        }
      }

      // Schedule same-day notification
      if (settings.notifyOnDueDate) {
        if (dueDate.isAfter(now)) {
          await _scheduleNotification(
            id: _generateNotificationId(subscription.id, 0),
            title: 'Subscription Due Today',
            body: '${subscription.name} payment of ₹${subscription.amount.toStringAsFixed(0)} is due today',
            scheduledDate: dueDate,
            payload: subscription.id,
          );
        }
      }

      // Schedule renewal reminders
      if (settings.notifyRenewalReminders) {
        if (subscription.billingCycle == BillingCycle.yearly) {
          final renewalDate = dueDate.subtract(const Duration(days: 30));
          if (renewalDate.isAfter(now)) {
            await _scheduleNotification(
              id: _generateNotificationId(subscription.id, 30),
              title: 'Yearly Subscription Renewal',
              body: '${subscription.name} renews in 30 days. Review your subscription?',
              scheduledDate: renewalDate,
              payload: subscription.id,
            );
          }
        } else if (subscription.billingCycle == BillingCycle.monthly) {
          final renewalDate = dueDate.subtract(const Duration(days: 7));
          if (renewalDate.isAfter(now)) {
            await _scheduleNotification(
              id: _generateNotificationId(subscription.id, 7),
              title: 'Monthly Subscription Renewal',
              body: '${subscription.name} renews in 7 days. Review your subscription?',
              scheduledDate: renewalDate,
              payload: subscription.id,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error scheduling subscription notifications: $e');
    }
  }

  /// Cancel notifications for a subscription
  Future<void> cancelSubscriptionNotifications(String subscriptionId) async {
    try {
      await initialize();
      
      // Cancel all possible notification IDs for this subscription
      final ids = [0, 1, 3, 7, 30];
      for (final days in ids) {
        await _notifications.cancel(_generateNotificationId(subscriptionId, days));
      }
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  /// Reschedule all notifications for a list of subscriptions
  Future<void> rescheduleAllNotifications(
    List<Subscription> subscriptions,
    NotificationSettings settings,
  ) async {
    try {
      await initialize();
      
      // Cancel all existing notifications
      await _notifications.cancelAll();

      // Schedule new notifications for each subscription
      for (final subscription in subscriptions) {
        await scheduleSubscriptionNotifications(subscription, settings);
      }
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'subscription_reminders',
        'Subscription Reminders',
        channelDescription: 'Notifications for upcoming subscription payments',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  /// Generate unique notification ID based on subscription ID and days before
  int _generateNotificationId(String subscriptionId, int daysBefore) {
    // Create a simple hash from subscription ID and days
    final hash = subscriptionId.hashCode;
    return (hash.abs() % 100000) * 100 + daysBefore;
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(_settingsKey, jsonString);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return NotificationSettings();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return NotificationSettings.fromJson(json);
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      return NotificationSettings();
    }
  }

  /// Send a test notification
  Future<void> sendTestNotification() async {
    try {
      await initialize();

      const androidDetails = AndroidNotificationDetails(
        'subscription_reminders',
        'Subscription Reminders',
        channelDescription: 'Notifications for upcoming subscription payments',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        999999,
        'Test Notification',
        'This is a test subscription reminder notification',
        details,
      );
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }
}
