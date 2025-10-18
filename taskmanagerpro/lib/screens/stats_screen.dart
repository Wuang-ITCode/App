import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/task_model.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final db = FirebaseFirestore.instance;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê theo danh mục')),
      body: StreamBuilder<QuerySnapshot>(
        // ✅ Danh mục lấy ở cấp gốc
        stream: db.collection('categories').snapshots(),
        builder: (context, catSnap) {
          if (catSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!catSnap.hasData || catSnap.data!.docs.isEmpty) {
            return const Center(
              child: Text('Chưa có danh mục nào. Hãy thêm trong Quản lý danh mục!'),
            );
          }

          final categories = catSnap.data!.docs.map((d) => d['name'] as String).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];

              // ✅ Đọc tasks trong "users/{uid}/tasks"
              return StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('users')
                    .doc(uid)
                    .collection('tasks')
                    .where('category', isEqualTo: cat)
                    .snapshots(),
                builder: (context, taskSnap) {
                  if (!taskSnap.hasData) {
                    return const SizedBox.shrink();
                  }

                  final tasks = taskSnap.data!.docs.map((d) => TaskModel.fromDoc(d)).toList();
                  final total = tasks.length;
                  final done = tasks.where((t) => t.isDone).length;
                  final notDone = total - done;
                  final donePercent = total == 0 ? 0 : (done / total) * 100;

                  return Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // ✅ Biểu đồ tròn
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 24,
                                sectionsSpace: 2,
                                sections: [
                                  PieChartSectionData(
                                    color: Colors.green,
                                    value: done.toDouble(),
                                    title: '${donePercent.toStringAsFixed(0)}%',
                                    radius: 36,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                    value: notDone.toDouble(),
                                    title: '',
                                    radius: 34,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // ✅ Thông tin danh mục
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Tổng số công việc: $total'),
                                Text('Hoàn thành: $done'),
                                Text('Chưa hoàn thành: $notDone'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
