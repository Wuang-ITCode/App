import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _col() {
    final uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('tasks');
  }

  // 🔹 Lấy danh sách danh mục (realtime)
  Stream<List<String>> watchCategories() {
    return _db.collection('categories').orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) => d['name'] as String).toList(),
    );
  }

// 🔹 Thêm danh mục nếu chưa tồn tại
  Future<void> addCategoryIfNotExists(String name) async {
    final ref = _db.collection('categories');
    final nameLower = name.trim().toLowerCase();

    // Lấy tất cả danh mục hiện có (chỉ khi ít)
    final all = await ref.get();
    final exists = all.docs.any((d) {
      final existing = (d['name'] as String).trim().toLowerCase();
      return existing == nameLower;
    });

    if (!exists) {
      await ref.add({'name': name.trim()});
    }
  }

  Stream<List<TaskModel>> watchTasks({
    String? query,
    String? statusFilter,
    String? category,
  }) {
    Query<Map<String, dynamic>> q =
    _col().orderBy('createdAt', descending: true);

    // Lọc theo danh mục nếu có
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }

    // ✅ Lọc theo trạng thái
    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (statusFilter == 'done') {
        q = q.where('isDone', isEqualTo: true);
      } else if (statusFilter == 'todo') {
        q = q.where('isDone', isEqualTo: false);
      }
    }

    // ✅ includeMetadataChanges giúp đảm bảo realtime ngay cả khi Firestore chỉ update local
    return q.snapshots(includeMetadataChanges: true).map((snap) {
      var list = snap.docs.map((d) => TaskModel.fromDoc(d)).toList();

      // Lọc theo từ khoá (client side)
      if (query != null && query.trim().isNotEmpty) {
        final keyword = query.toLowerCase();
        list = list.where((t) {
          final hay =
          '${t.title} ${t.description ?? ''} ${t.tags.join(' ')}'.toLowerCase();
          return hay.contains(keyword);
        }).toList();
      }

      return list;
    });
  }

  Future<void> addTask(TaskModel t) async {
    await _col().add(t.toMap());
  }

  Future<void> updateTask(TaskModel t) async {
    await _col().doc(t.id).update(t.toMap());
  }

  Future<void> deleteTask(String id) async {
    await _col().doc(id).delete();
  }

  Future<void> toggleDone(TaskModel t) async {
    await _col().doc(t.id).update({
      'isDone': !t.isDone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔹 Xóa danh mục khỏi Firestore
  Future<void> deleteCategory(String name) async {
    final ref = _db.collection('categories');
    final snap = await ref.where('name', isEqualTo: name).get();

    // 🔹 1. Xóa danh mục trong "categories"
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }

    // 🔹 2. Xóa toàn bộ task thuộc danh mục đó (trong user hiện tại)
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final tasksRef = _db.collection('users').doc(uid).collection('tasks');
      final taskSnap = await tasksRef.where('category', isEqualTo: name).get();

      for (final doc in taskSnap.docs) {
        await doc.reference.delete();
      }
    }
  }
}
