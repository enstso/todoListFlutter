import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:todo_list/models/task_model.dart';

class TaskService {
  // Firebase Authentication for retrieving current user
  final FirebaseAuth _auth;

  // Reference to the Firestore "tasks" collection
  final CollectionReference _taskRef;

  // Firebase Storage for uploading images
  final FirebaseStorage _storage;

  TaskService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _taskRef = (firestore ?? FirebaseFirestore.instance).collection('tasks'),
       _storage = storage ?? FirebaseStorage.instance;

  // Adds a new task to Firestore, optionally uploading an image to Storage
  Future<void> addTask(TaskModel task, {Uint8List? imageBytes}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    // The final URL of the uploaded image, if any
    String? imageUrl = task.imageUrl;

    try {
      // Uploads image to Storage if provided
      if (imageBytes != null) {
        imageUrl = await _uploadImage(uid, imageBytes);
      }

      // Adds the task to Firestore
      await _taskRef.add({
        ...task.toMap(),
        'userId': uid,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(), // Server-side timestamp
      });
    } on FirebaseException catch (e) {
      throw Exception('Firestore add failed: ${e.message}');
    }
  }

  // Updates an existing task, optionally replacing or removing the image
  Future<void> updateTask(
    TaskModel task, {
    Uint8List? imageBytes,
    bool removeImage = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      String? imageUrl = task.imageUrl;

      // If image removal is requested
      if (removeImage) {
        imageUrl = null;
      }

      // If a new image is provided, upload it and override imageUrl
      if (imageBytes != null) {
        imageUrl = await _uploadImage(uid, imageBytes);
      }

      // Update task document in Firestore
      await _taskRef.doc(task.id).update({
        ...task.toMap(),
        'userId': uid,
        'imageUrl': imageUrl,
      });
    } on FirebaseException catch (e) {
      throw Exception('Firestore update failed: ${e.message}');
    }
  }

  // Deletes a task by its Firestore document ID
  Future<void> deleteTask(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _taskRef.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Firestore delete failed: ${e.message}');
    }
  }

  // Retrieves a task by its ID, returns null if not found
  Future<TaskModel?> getTaskById(String id) async {
    final doc = await _taskRef.doc(id).get();
    final data = doc.data();
    if (doc.exists && data != null) {
      return TaskModel.fromMap(data, doc.id);
    }
    return null;
  }

  // Returns a stream of tasks for the current user
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

            // Ensures createdAt exists to avoid errors
            data['createdAt'] ??= Timestamp.now();

            return TaskModel.fromMap(data, d.id);
          }).toList(),
        );
  }

  // Returns a stream of tasks filtered by category for the current user
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

  // Returns a stream of tasks matching the search query (title, description, or tags)
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

  // Uploads an image to Firebase Storage and returns its download URL
  Future<String> _uploadImage(String uid, Uint8List bytes) async {
    // Build storage path using user ID + timestamp
    final ref = _storage.ref().child(
      'task_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // Upload raw byte data
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

    // Returns the public download URL
    return ref.getDownloadURL();
  }
}
