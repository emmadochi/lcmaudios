import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _prefKeyDevotionEnabled = 'lcm_devotion_notif_enabled';
  static const String _prefKeyDevotionHour = 'lcm_devotion_hour';
  static const String _prefKeyDevotionMinute = 'lcm_devotion_minute';

  bool _isDevotionReminderEnabled = true;
  TimeOfDay _devotionTime = const TimeOfDay(hour: 6, minute: 0);

  bool get isDevotionReminderEnabled => _isDevotionReminderEnabled;
  TimeOfDay get devotionTime => _devotionTime;

  /// Initialize notification preferences and schedule alarms
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDevotionReminderEnabled = prefs.getBool(_prefKeyDevotionEnabled) ?? true;
    final hour = prefs.getInt(_prefKeyDevotionHour) ?? 6;
    final minute = prefs.getInt(_prefKeyDevotionMinute) ?? 0;
    _devotionTime = TimeOfDay(hour: hour, minute: minute);
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
