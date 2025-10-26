import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 1)
class AppNotification {
  @HiveField(0)
  String title;

  @HiveField(1)
  String body;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  bool read;

  AppNotification({
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
  });
}
