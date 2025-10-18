import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết công việc"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Chỉnh sửa công việc',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditTaskScreen(existing: task),
                ),
              );
              Navigator.pop(context); // Quay lại sau khi chỉnh sửa
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Trạng thái
              Row(
                children: [
                  Icon(
                    task.isDone ? Icons.check_circle : Icons.timelapse,
                    color: task.isDone ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.isDone ? "Hoàn thành" : "Đang làm",
                    style: TextStyle(
                      color: task.isDone ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Ngày & Danh mục
              if (task.deadline != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Hạn: ${task.deadline}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              if (task.category != null && task.category!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open, size: 20),
                      const SizedBox(width: 8),
                      Text("Danh mục: ${task.category!}",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              if (task.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("Tag: ${task.tags.join(', ')}",
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              const Text(
                "Mô tả công việc:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                task.description?.isNotEmpty == true
                    ? task.description!
                    : "(Không có mô tả)",
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
