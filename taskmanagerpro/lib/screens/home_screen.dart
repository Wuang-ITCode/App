import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/task_tile.dart';
import 'edit_task_screen.dart';
import 'stats_screen.dart';
import 'category_manager_screen.dart';
import 'profile_screen.dart';
import 'task_detail_screen.dart';
import '../screens/notification_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? statusFilter;
  String? categoryFilter;
  final _searchC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskSrv = context.watch<TaskService>();
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final theme = Theme.of(context);
    // 🔔 Khi mở app, hiển thị thông báo chưa đọc
    final unread = NotificationService.getUnreadCount();
    if (unread > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.indigoAccent,
            content: Text(
              '🔔 Bạn có $unread thông báo mới chưa đọc!',
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // 🌈 AppBar gọn, hiện đại
      appBar: AppBar(
        title: null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 26),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade600, Colors.indigo.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.shade800.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        actions: [
          // 🔍 Tìm kiếm dạng biểu tượng
          IconButton(
            tooltip: 'Tìm kiếm công việc',
            icon: const Icon(Icons.search_rounded),
            onPressed: () async {
              final controller = TextEditingController();
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey.shade900,
                  title: const Text(
                    'Tìm kiếm',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Nhập tiêu đề, mô tả hoặc tag...',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _searchC.text = controller.text.trim();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Tìm'),
                    ),
                  ],
                ),
              );
            },
          ),

          IconButton(
            tooltip: 'Lịch sử thông báo',
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Thống kê chi tiết',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Quản lý danh mục',
            icon: const Icon(Icons.folder_open_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryManagerScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Hồ sơ cá nhân',
            icon: const Icon(Icons.person_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Bộ lọc danh mục và trạng thái
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 🔹 Danh mục
                    StreamBuilder<List<String>>(
                      stream: taskSrv.watchCategories(),
                      builder: (context, snapshot) {
                        final categories = snapshot.data ?? [];
                        if (categoryFilter != null &&
                            !categories.contains(categoryFilter)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => categoryFilter = null);
                          });
                        }

                        return DropdownButton<String>(
                          value: categoryFilter,
                          hint: const Text('Danh mục'),
                          dropdownColor: theme.cardColor,
                          items: categories
                              .map(
                                (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ),
                          )
                              .toList(),
                          onChanged: (v) => setState(() => categoryFilter = v),
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // 🔹 Thêm danh mục nhanh
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Thêm danh mục',
                      onPressed: () async {
                        final controller = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: theme.cardColor,
                            title: const Text('Thêm danh mục'),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Nhập tên danh mục',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final name = controller.text.trim();
                                  if (name.isNotEmpty) {
                                    await context
                                        .read<TaskService>()
                                        .addCategoryIfNotExists(name);
                                  }
                                  if (context.mounted) Navigator.pop(context);
                                },
                                child: const Text('Lưu'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // 🔹 Trạng thái
                    DropdownButton<String>(
                      value: statusFilter,
                      hint: const Text('Trạng thái'),
                      dropdownColor: theme.cardColor,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Tất cả')),
                        DropdownMenuItem(value: 'todo', child: Text('Đang làm')),
                        DropdownMenuItem(value: 'done', child: Text('Hoàn thành')),
                      ],
                      onChanged: (v) => setState(() => statusFilter = v),
                    ),
                    const SizedBox(width: 8),

                    // 🔹 Xóa lọc
                    IconButton(
                      tooltip: 'Xóa lọc',
                      icon: const Icon(Icons.filter_alt_off_rounded),
                      onPressed: () => setState(() {
                        statusFilter = null;
                        categoryFilter = null;
                        _searchC.clear();
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // 📋 Danh sách công việc
            Expanded(
              child: StreamBuilder<List<TaskModel>>(
                stream: taskSrv.watchTasks(
                  query: _searchC.text.trim().isEmpty ? null : _searchC.text.trim(),
                  statusFilter: statusFilter,
                  category: categoryFilter,
                ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snap.data ?? [];
                  if (tasks.isEmpty) {
                    return const Center(
                      child: Text('Chưa có công việc nào.\nNhấn "+" để thêm.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 120),
                    separatorBuilder: (_, __) =>
                        Divider(height: 0, color: theme.dividerColor),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) {
                      final t = tasks[i];
                      return TaskTile(
                        task: t,
                        subtitle: [
                          if (t.deadline != null) 'Hạn: ${df.format(t.deadline!)}',
                          if ((t.category ?? '').isNotEmpty)
                            'Danh mục: ${t.category}',
                          if (t.tags.isNotEmpty) 'Tag: ${t.tags.join(", ")}',
                        ].join(' • '),
                        onToggle: () => taskSrv.toggleDone(t),
                        onEdit: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditTaskScreen(existing: t),
                            ),
                          );
                        },
                        onDelete: () => taskSrv.deleteTask(t.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  TaskDetailScreen(task: t),
                              transitionsBuilder: (_, anim, __, child) =>
                                  FadeTransition(opacity: anim, child: child),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            // 📊 Thống kê tổng quan
            StreamBuilder<List<TaskModel>>(
              stream: taskSrv.watchTasks(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                final tasks = snap.data!;
                if (tasks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Text("Chưa có dữ liệu để thống kê."),
                  );
                }

                final total = tasks.length;
                final done = tasks.where((t) => t.isDone).length;
                final todo = total - done;
                final donePercent = total == 0 ? 0 : (done / total) * 100;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: theme.brightness == Brightness.light
                          ? [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                          : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 28,
                                sectionsSpace: 2,
                                sections: [
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: done.toDouble(),
                                    title: '${donePercent.toStringAsFixed(0)}%',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                    value: todo.toDouble(),
                                    title: '',
                                    radius: 38,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Thống kê tiến độ tổng quan",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Tổng số công việc: $total'),
                                Text('Hoàn thành: $done'),
                                Text('Chưa hoàn thành: $todo'),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditTaskScreen()),
          );
        },
        label: const Text('Thêm'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}