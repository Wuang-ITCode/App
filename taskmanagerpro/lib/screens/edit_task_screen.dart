import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart'; // ✅ Thêm import

class EditTaskScreen extends StatefulWidget {
  final TaskModel? existing;
  const EditTaskScreen({super.key, this.existing});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _titleC = TextEditingController();
  final _descC = TextEditingController();
  final _categoryC = TextEditingController();
  final _tagsC = TextEditingController(); // nhập dạng: work, urgent
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _titleC.text = t.title;
      _descC.text = t.description ?? '';
      _categoryC.text = t.category ?? '';
      _tagsC.text = t.tags.join(', ');
      _deadline = t.deadline;
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _categoryC.dispose();
    _tagsC.dispose();
    super.dispose();
  }

  // 🔹 Chọn ngày + giờ deadline
  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDate: _deadline ?? now,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (time == null) return;

    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // 🔹 Lưu hoặc cập nhật công việc
  Future<void> _save() async {
    if (_titleC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('⚠️ Vui lòng nhập tiêu đề')));
      return;
    }

    final srv = context.read<TaskService>();
    final tags = _tagsC.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final category = _categoryC.text.trim().isEmpty ? null : _categoryC.text.trim();

    try {
      late TaskModel t;
      if (widget.existing == null) {
        // 🆕 Thêm công việc mới
        t = TaskModel(
          id: '_', // Firestore sẽ tự tạo ID
          title: _titleC.text.trim(),
          description: _descC.text.trim().isEmpty ? null : _descC.text.trim(),
          deadline: _deadline,
          category: category,
          tags: tags,
          isDone: false,
          createdAt: now,
          updatedAt: now,
        );
        await srv.addTask(t);
      } else {
        // ✏️ Cập nhật công việc cũ
        final old = widget.existing!;
        t = TaskModel(
          id: old.id,
          title: _titleC.text.trim(),
          description: _descC.text.trim().isEmpty ? null : _descC.text.trim(),
          deadline: _deadline,
          category: category,
          tags: tags,
          isDone: old.isDone,
          createdAt: old.createdAt,
          updatedAt: now,
        );
        await srv.updateTask(t);
      }

      // 🔸 Nếu có nhập danh mục mới thì thêm vào Firestore (tránh trùng)
      if (category != null && category.isNotEmpty) {
        await srv.addCategoryIfNotExists(category);
      }

      // 🔔 Lên lịch thông báo nếu có deadline
      if (_deadline != null && _deadline!.isAfter(DateTime.now())) {
        final notifyTime = _deadline!.subtract(const Duration(minutes: 10));
        await NotificationService.schedule(
          title: 'Nhắc việc: ${_titleC.text.trim()}',
          body:
          'Sắp đến hạn vào ${DateFormat('HH:mm dd/MM/yyyy').format(_deadline!)}',
          time: notifyTime.isBefore(DateTime.now())
              ? DateTime.now().add(const Duration(seconds: 10))
              : notifyTime,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Lưu công việc thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi lưu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Thêm công việc' : 'Sửa công việc'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Lưu',
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tiêu đề
            TextField(
              controller: _titleC,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Mô tả
            TextField(
              controller: _descC,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Danh mục
            TextField(
              controller: _categoryC,
              decoration: const InputDecoration(
                labelText: 'Danh mục (VD: Học tập, Công việc, Cá nhân...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Tag
            TextField(
              controller: _tagsC,
              decoration: const InputDecoration(
                labelText: 'Tag (phân cách bằng dấu phẩy, VD: gấp, rà soát)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Deadline
            Row(
              children: [
                Expanded(
                  child: Text(
                    _deadline == null
                        ? '⏰ Chưa đặt hạn'
                        : 'Hạn: ${df.format(_deadline!)}',
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Chọn hạn'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nút lưu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Lưu công việc'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
