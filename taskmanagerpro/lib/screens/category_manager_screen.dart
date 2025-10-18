import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_service.dart';

class CategoryManagerScreen extends StatelessWidget {
  const CategoryManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskSrv = context.watch<TaskService>();
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
      ),
      body: StreamBuilder<List<String>>(
        stream: taskSrv.watchCategories(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(child: Text('Chưa có danh mục nào.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final cat = categories[i];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(cat),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Xóa danh mục',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: Text(
                          'Bạn có chắc muốn xóa danh mục "$cat"?\n\n'
                              '⚠️ Tất cả công việc thuộc danh mục này cũng sẽ bị xóa!',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await taskSrv.deleteCategory(cat);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã xóa "$cat" và toàn bộ công việc liên quan.')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Thêm danh mục mới'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Nhập tên danh mục...',
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
                      await taskSrv.addCategoryIfNotExists(name);
                      Navigator.pop(context);
                      controller.clear();
                    }
                  },
                  child: const Text('Thêm'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
