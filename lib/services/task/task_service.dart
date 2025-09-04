
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:todo_list/models/task_model.dart';

class TaskService {
  final _auth = FirebaseAuth.instance;
  final CollectionReference _taskRef = FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(TaskModel task) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    await _taskRef.add({...task.toMap(), 'userId': uid});
  }

  Future<void> updateTask(TaskModel task) async {
     final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    await _taskRef.doc(task.id).update({...task.toMap(), 'userId': uid});
  }

  Future<void> deleteTask(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    await _taskRef.doc(id).delete();
  }

  Future<TaskModel?> getTaskById(String id) async {
    final doc = await _taskRef.doc(id).get();
    if (doc.exists) {
      return TaskModel.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  Stream<List<TaskModel>> getTasks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return _taskRef.where('userId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
