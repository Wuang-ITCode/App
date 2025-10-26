import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'notification_detail_screen.dart'; // ✅ Thêm file chi tiết thông báo

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ Khi mở màn hình, đánh dấu tất cả là đã đọc
    Future.microtask(() async {
      final box = Hive.box<AppNotification>('notifications');
      for (var i = 0; i < box.length; i++) {
        final item = box.getAt(i);
        if (item != null && item.read == false) {
          item.read = true;
          await box.putAt(i, item);
        }
      }
      setState(() {}); // Cập nhật lại UI
    });
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final notifications = NotificationService.getHistory();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Lịch sử thông báo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Xóa tất cả',
            icon: const Icon(Icons.delete_forever_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Xóa lịch sử?'),
                  content:
                  const Text('Bạn có chắc muốn xóa toàn bộ thông báo không?'),
                  actions: [
                    TextButton(
                      child: const Text('Hủy'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    ElevatedButton(
                      child: const Text('Xóa'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await NotificationService.clearAll();
                if (context.mounted) setState(() {});
              }
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
        child: Text(
          'Chưa có thông báo nào.',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = notifications[i];
          final isUnread = !n.read;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color:
              isUnread ? Colors.indigo.withOpacity(0.08) : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (theme.brightness == Brightness.light)
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: isUnread
                    ? Colors.indigoAccent
                    : Colors.grey.shade400,
                child: const Icon(Icons.notifications_rounded,
                    color: Colors.white),
              ),
              title: Text(
                n.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isUnread
                      ? theme.colorScheme.onSurface
                      : Colors.grey.shade700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${n.body}\n🕓 ${df.format(n.timestamp)}',
                  style: TextStyle(
                    height: 1.4,
                    color: isUnread
                        ? theme.textTheme.bodyMedium?.color
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              isThreeLine: true,

              // ✅ Khi nhấn → mở chi tiết thông báo
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        NotificationDetailScreen(notification: n),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration:
                    const Duration(milliseconds: 300),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
