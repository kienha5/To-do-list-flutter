import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/todo.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// Duration before deadline to show the reminder notification
  static const reminderBefore = Duration(minutes: 1);

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _androidDetails = AndroidNotificationDetails(
    'todo_reminders',
    'Nhắc việc',
    channelDescription: 'Nhắc trước khi GHI CHÚ đến hạn',
    importance: Importance.max,
    priority: Priority.high,
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);

    // Android 13+ cần xin quyền hiển thị thông báo lúc chạy
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> scheduleReminder(Todo todo) async {
    final due = todo.dueAt;
    if (due == null) return;

    final fireAt = due.subtract(reminderBefore);
    if (!fireAt.isAfter(DateTime.now())) return; // đã quá giờ nhắc

    await _plugin.zonedSchedule(
      id: todo.id,
      title: 'Sắp đến hạn',
      body: todo.title,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: _androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}