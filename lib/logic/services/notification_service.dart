import 'dart:convert';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;

class NotificationService {
  static const String _storageKey = 'notification_history';
  static final fln.FlutterLocalNotificationsPlugin _localNotifications = fln.FlutterLocalNotificationsPlugin();

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static Future<void> init() async {
    try {
      final appId = dotenv.env['ONESIGNAL_APP_ID'] ?? "d643324c-c642-44c1-a4e1-6c4fc5bb4a00";
      
      // Load initial unread count
      final prefs = await SharedPreferences.getInstance();
      unreadCountNotifier.value = prefs.getInt('unread_notifications_count') ?? 0;

      // Initialize OneSignal
      OneSignal.initialize(appId);
      debugPrint("✅ OneSignal Initialized!");

      // Initialize Local Notifications
      const fln.AndroidInitializationSettings initializationSettingsAndroid = 
          fln.AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const fln.DarwinInitializationSettings initializationSettingsIOS = fln.DarwinInitializationSettings();
      
      const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
        macOS: initializationSettingsIOS,
      );
      
      await _localNotifications.initialize(
        settings: initializationSettings, 
      ); 

      // Create Notification Channels for Android
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
  
  
        await androidPlugin.requestNotificationsPermission();

        await androidPlugin.createNotificationChannel(
          const fln.AndroidNotificationChannel(
            'food_channel',
            'Food Logs',
            description: 'Notifications for food logging feedback',
            importance: fln.Importance.max,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const fln.AndroidNotificationChannel(
            'water_channel',
            'Water Reminders',
            description: 'Hourly water reminders',
            importance: fln.Importance.high,
          ),
        );
      }

      // Request permissions (OneSignal)
      OneSignal.Notifications.requestPermission(true);
      
      // Handle foreground notifications
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('Notification received in foreground: ${event.notification.body}');
        _saveNotification(event.notification);
      });

      // Handle background notification clicks
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('Notification clicked: ${event.notification.body}');
        _saveNotification(event.notification);
      });
      debugPrint("✅ Local Notifications Initialized!");
    } catch (e) {
      debugPrint("❌ NotificationService Init Error: $e");
    }
  }

  static Future<void> showFoodAddedNotification(String foodName, int calories, int targetCalories, int totalEatenSoFar) async {
    final remaining = targetCalories - totalEatenSoFar;
    final message = remaining > 0 
      ? "You need $remaining kcal more to complete your diet." 
      : "Daily goal reached! Great job.";

    // Fix: AndroidNotificationDetails requires 2 positional arguments: id and name
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics = fln.AndroidNotificationDetails(
      'food_channel',
      'Food Logs',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );
    const fln.NotificationDetails platformChannelSpecifics = fln.NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      id: (DateTime.now().millisecondsSinceEpoch % 1000000).toInt(),
      title: 'Added: $foodName ($calories kcal)',
      body: message,
      notificationDetails: platformChannelSpecifics,
    );

    // Save to local history
    _saveManualNotification('Food Added', 'Added $foodName. $message');
  }

  static Future<void> scheduleWaterReminders() async {
    final now = DateTime.now();
    // Summer months in India: March (3) to June (6)
    final isSummer = now.month >= 3 && now.month <= 6;

    if (!isSummer) {
      debugPrint("Not summer, skipping hourly water reminders.");
      return;
    }

    // Schedule hourly reminders
    await _localNotifications.periodicallyShow(
      id: 999, // water id
      title: 'Stay Hydrated! 💧',
      body: 'It\'s summer! Don\'t forget to drink water every hour.',
      repeatInterval: fln.RepeatInterval.hourly,
      notificationDetails: const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'water_channel',
          'Water Reminders',
          importance: fln.Importance.high,
          priority: fln.Priority.high,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
    );
    debugPrint("Summer detected! Hourly water reminders scheduled.");

    // Save to local history for in-app display
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSavedStr = prefs.getString('last_water_reminder_saved');
      DateTime? lastSaved;
      if (lastSavedStr != null) {
        lastSaved = DateTime.tryParse(lastSavedStr);
      }
      
      // If it's been more than 1 hour since we last saved this message to history
      if (lastSaved == null || now.difference(lastSaved).inHours >= 1) {
        await _saveManualNotification('Stay Hydrated! 💧', 'It\'s summer! Don\'t forget to drink water every hour.');
        await prefs.setString('last_water_reminder_saved', now.toIso8601String());
      }
    } catch (e) {
      debugPrint("Error saving water reminder to history: $e");
    }
  }

  static Future<void> _saveNotification(OSNotification notification) async {
    _saveManualNotification(notification.title ?? 'No Title', notification.body ?? 'No Body');
  }

  static Future<void> _saveManualNotification(String title, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history = prefs.getStringList(_storageKey) ?? [];
      
      final newNotification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'timestamp': DateTime.now().toIso8601String(),
      };

      history.insert(0, jsonEncode(newNotification));
      if (history.length > 30) history.removeRange(30, history.length);
      await prefs.setStringList(_storageKey, history);

      // Increment unread count
      final currentUnread = prefs.getInt('unread_notifications_count') ?? 0;
      final newUnread = currentUnread + 1;
      await prefs.setInt('unread_notifications_count', newUnread);
      unreadCountNotifier.value = newUnread;
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_storageKey) ?? [];
    return history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await resetUnreadCount();
  }

  static Future<void> resetUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('unread_notifications_count', 0);
    unreadCountNotifier.value = 0;
  }
}
