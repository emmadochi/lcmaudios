import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _prefKeyDevotionEnabled = 'lcm_devotion_notif_enabled';
  static const String _prefKeyDevotionHour = 'lcm_devotion_hour';
  static const String _prefKeyDevotionMinute = 'lcm_devotion_minute';

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool _isDevotionReminderEnabled = true;
  TimeOfDay _devotionTime = const TimeOfDay(hour: 6, minute: 0);

  bool get isDevotionReminderEnabled => _isDevotionReminderEnabled;
  TimeOfDay get devotionTime => _devotionTime;

  /// Initialize notification preferences and native Android system notifications
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('[NotificationService] Timezone init notice: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('[NotificationService] Notification tapped: ${details.payload}');
        },
      );

      // Request notification permissions for Android 13+ (API 33+)
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
      }

      // Initialize Firebase Cloud Messaging & Topic Subscription
      try {
        final fcm = FirebaseMessaging.instance;
        await fcm.requestPermission(alert: true, badge: true, sound: true);
        await fcm.subscribeToTopic('all_devotees');
        debugPrint('[FCM] Subscribed to all_devotees broadcast topic.');

        // Listen for foreground push notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('[FCM] Foreground message received: ${message.notification?.title}');
          final notif = message.notification;
          if (notif != null) {
            showInstantNotification(
              title: notif.title ?? '🕊️ LCM Audios Faith Broadcast',
              body: notif.body ?? 'New message received from Life Care Ministry.',
              payload: message.data['trackId'],
            );
          }
        });
      } catch (fcmErr) {
        debugPrint('[FCM] Setup notice: $fcmErr');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    _isDevotionReminderEnabled = prefs.getBool(_prefKeyDevotionEnabled) ?? true;
    final hour = prefs.getInt(_prefKeyDevotionHour) ?? 6;
    final minute = prefs.getInt(_prefKeyDevotionMinute) ?? 0;
    _devotionTime = TimeOfDay(hour: hour, minute: minute);
  }

  /// Show an instant native Android system notification with sound and vibration
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lcm_broadcasts_channel',
      'LCM Broadcast Alerts',
      channelDescription: 'Announcements, new sermon releases, and live prayer alarms',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFFE53935),
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] showInstantNotification error: $e');
    }
  }

  /// Automated self-test to verify notifications on the user's device
  Future<void> triggerAutoTestNotification(BuildContext? context) async {
    await showInstantNotification(
      title: '🕊️ LCM Audios Notification Test',
      body: 'Notifications are functioning perfectly! Your daily devotion alarm is active.',
    );

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: Colors.amberAccent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🔔 Test notification sent to your status bar!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1F162B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Update daily morning devotion notification schedule
  Future<void> setDevotionSchedule({
    required bool enabled,
    required TimeOfDay time,
    BuildContext? context,
  }) async {
    _isDevotionReminderEnabled = enabled;
    _devotionTime = time;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyDevotionEnabled, enabled);
    await prefs.setInt(_prefKeyDevotionHour, time.hour);
    await prefs.setInt(_prefKeyDevotionMinute, time.minute);

    if (enabled) {
      await _scheduleNativeDailyAlarm(time);
    } else {
      await _notificationsPlugin.cancel(1001); // 1001 is devotion alarm ID
    }

    if (context != null && context.mounted) {
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.alarm_on_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  enabled
                      ? '🌅 Daily Morning Devotion alarm set for $timeStr'
                      : 'Morning Devotion reminders paused.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1F162B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _scheduleNativeDailyAlarm(TimeOfDay time) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'lcm_devotion_alarm',
        'Daily Morning Devotions',
        channelDescription: 'Scheduled morning devotion prayer reminders',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFD4AF37),
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        1001,
        '🌅 Morning Devotion Time',
        'Start your day in the presence of God. Tap to stream today\'s devotional message.',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[NotificationService] Schedule error: $e');
    }
  }

  /// Display an instant sermon release broadcast notification in-app
  static void showSermonBroadcastAlert(BuildContext context, {
    required String title,
    required String minister,
    required VoidCallback onPlay,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mic_external_on_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEW FAITH RELEASE',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    minister,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onPlay,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('LISTEN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1329),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
