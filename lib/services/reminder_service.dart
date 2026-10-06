import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_model.dart';

class ReminderService {
  ReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    final didInitialize = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (didInitialize != true) {
      throw StateError('Could not initialize task reminders.');
    }
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  Future<void> schedule(TaskModel task) async {
    await initialize();
    final id = _notificationId(task.id);
    await _plugin.cancel(id: id);
    final scheduled = _scheduledDate(task);
    if (!task.reminder || task.isCompleted || scheduled == null) return;
    if (!scheduled.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: 'Taskly reminder',
      body: task.title,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task reminders',
          channelDescription: 'Notifications for tasks you have scheduled.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: task.id,
    );
  }

  Future<void> syncTasks(List<TaskModel> tasks) async {
    await initialize();
    await _plugin.cancelAll();
    final eligible =
        tasks.where((task) {
            final at = _scheduledDate(task);
            return task.reminder &&
                !task.isCompleted &&
                at != null &&
                at.isAfter(DateTime.now());
          }).toList()
          ..sort((a, b) => _scheduledDate(a)!.compareTo(_scheduledDate(b)!));
    // iOS retains only the 64 soonest pending notifications.
    for (final task in eligible.take(64)) {
      await schedule(task);
    }
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  tz.TZDateTime? _scheduledDate(TaskModel task) {
    if (task.dueDate == null || task.dueTime == null) return null;
    final time = task.dueTime!.split(':');
    if (time.length != 2) return null;
    final hour = int.tryParse(time[0]);
    final minute = int.tryParse(time[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return tz.TZDateTime(
      tz.local,
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      hour,
      minute,
    );
  }

  int _notificationId(String taskId) {
    var hash = 0x811c9dc5;
    for (final unit in taskId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
