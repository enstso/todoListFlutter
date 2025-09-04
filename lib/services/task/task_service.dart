
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/models/task_model.dart';

class TaskService {
  final CollectionReference taskRef = FirebaseFirestore.instance.collection('tasks');

  Future<void> addTask(TaskModel task) async {
    await taskRef.add(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await taskRef.doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String id) async {
    await taskRef.doc(id).delete();
  }

  Future<TaskModel?> getTaskById(String id) async {
    final doc = await taskRef.doc(id).get();
    if (doc.exists) {
      return TaskModel.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  Stream<List<TaskModel>> getTasks() {
    return taskRef.orderBy('createdAt',descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
