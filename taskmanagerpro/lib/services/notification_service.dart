import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import '../models/notification_model.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  /// 🔹 Khởi tạo thông báo + Hive box
  static Future<void> init() async {
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(initSettings);

    // Mở box Hive nếu chưa mở
    if (!Hive.isBoxOpen('notifications')) {
      await Hive.openBox<AppNotification>('notifications');
    }
  }

  /// 🔔 Hiện thông báo ngay lập tức (3 giây) + lưu lịch sử
  static Future<void> showNow({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Thông báo của ứng dụng Task Manager Pro',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      timeoutAfter: 3000, // ⏰ Tự động ẩn sau 3 giây
      styleInformation: BigTextStyleInformation(''), // Cho phép hiển thị nội dung dài
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notifications.show(
      notificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );

    // ✅ Lưu vào lịch sử
    await _saveToHistory(title: title, body: body);
  }

  /// ⏰ Lên lịch thông báo + lưu lịch sử
  static Future<void> schedule({
    required String title,
    required String body,
    required DateTime time,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Thông báo công việc đã lên lịch',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      timeoutAfter: 3000, // ⏰ Hiện trong 3 giây khi đến giờ
      styleInformation: BigTextStyleInformation(''),
    );

    await _notifications.zonedSchedule(
      time.hashCode,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // ✅ Lưu lịch sử
    await _saveToHistory(title: title, body: body);
  }

  /// 💾 Lưu lịch sử thông báo vào Hive
  static Future<void> _saveToHistory({
    required String title,
    required String body,
  }) async {
    try {
      final box = Hive.box<AppNotification>('notifications');
      final notification = AppNotification(
        title: title,
        body: body,
        timestamp: DateTime.now(),
        read: false,
      );
      await box.add(notification);
    } catch (e) {
      // Tránh crash nếu Hive chưa khởi tạo
      print('⚠️ Lỗi khi lưu thông báo vào Hive: $e');
    }
  }

  /// 📜 Lấy toàn bộ lịch sử (sắp xếp mới nhất lên đầu)
  static List<AppNotification> getHistory() {
    if (!Hive.isBoxOpen('notifications')) return [];
    final box = Hive.box<AppNotification>('notifications');
    return box.values.toList().reversed.toList();
  }

  /// 🗑 Xóa tất cả thông báo
  static Future<void> clearAll() async {
    await _notifications.cancelAll();
    if (Hive.isBoxOpen('notifications')) {
      await Hive.box<AppNotification>('notifications').clear();
    }
  }

  /// 🔢 Đếm số thông báo chưa đọc
  static int getUnreadCount() {
    if (!Hive.isBoxOpen('notifications')) return 0;
    final box = Hive.box<AppNotification>('notifications');
    return box.values.where((n) => n.read == false).length;
  }
}
