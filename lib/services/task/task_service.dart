import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:todo_list/models/task_model.dart';

class TaskService {
  final _auth = FirebaseAuth.instance;
  final CollectionReference _taskRef = FirebaseFirestore.instance.collection(
    'tasks',
  );
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addTask(TaskModel task, {Uint8List? imageBytes}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    String? imageUrl = task.imageUrl;

    try {
      if (imageBytes != null) {
        imageUrl = await _uploadImage(uid, imageBytes);
      }

      await _taskRef.add({
        ...task.toMap(),
        'userId': uid,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Firestore add failed: ${e.message}');
    }
  }

  Future<void> updateTask(
    TaskModel task, {
    Uint8List? imageBytes,
    bool removeImage = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      String? imageUrl = task.imageUrl;

      if (removeImage) {
        imageUrl = null;
      }

      if (imageBytes != null) {
        imageUrl = await _uploadImage(uid, imageBytes);
      }

      await _taskRef.doc(task.id).update({
        ...task.toMap(),
        'userId': uid,
        'imageUrl': imageUrl,
      });
    } on FirebaseException catch (e) {
      throw Exception('Firestore update failed: ${e.message}');
    }
  }

  Future<void> deleteTask(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _taskRef.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Firestore delete failed: ${e.message}');
    }
  }

  Future<TaskModel?> getTaskById(String id) async {
    final doc = await _taskRef.doc(id).get();
    final data = doc.data();
    if (doc.exists && data != null) {
      return TaskModel.fromMap(data, doc.id);
    }
    return null;
  }

  Stream<List<TaskModel>> getTasks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _taskRef
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            // fallback createdAt si absent
            data['createdAt'] ??= Timestamp.now();
            return TaskModel.fromMap(data, d.id);
          }).toList(),
        );
  }

  Stream<List<TaskModel>> getTasksByCategory(TaskCategory category) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _taskRef
        .where('userId', isEqualTo: uid)
        .where('category', isEqualTo: category.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['createdAt'] ??= Timestamp.now();
            return TaskModel.fromMap(data, d.id);
          }).toList(),
        );
  }

  Stream<List<TaskModel>> searchTasks(String query) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    final q = query.toLowerCase();

    return _taskRef
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) {
                final data = d.data() as Map<String, dynamic>;
                data['createdAt'] ??= Timestamp.now();
                return TaskModel.fromMap(data, d.id);
              })
              .where(
                (task) =>
                    task.title.toLowerCase().contains(q) ||
                    task.description.toLowerCase().contains(q) ||
                    task.tags.any((t) => t.toLowerCase().contains(q)),
              )
              .toList(),
        );
  }

  Future<String> _uploadImage(String uid, Uint8List bytes) async {
    final ref = _storage.ref().child(
      'task_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

    return ref.getDownloadURL();
  }
}
