import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:todo_list/models/task_model.dart';

/// Service responsible for all task-related operations:
///  - CRUD in Firestore
///  - image upload in Firebase Storage
///  - filtering by current user and assignee.
class TaskService {
  final FirebaseAuth _auth;
  final CollectionReference<Map<String, dynamic>> _taskRef;
  final FirebaseStorage _storage;

  TaskService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _taskRef =
            (firestore ?? FirebaseFirestore.instance).collection('tasks'),
        _storage = storage ?? FirebaseStorage.instance;

  /// Adds a new task to Firestore, optionally uploading an image to Storage.
  ///
  /// The current user is always stored as `userId`.
  /// If [task.assignedToUid] is not null, the assignee will later see this task.
  Future<void> addTask(
    TaskModel task, {
    Uint8List? imageBytes,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    String? imageUrl = task.imageUrl;

    try {
      // Upload image if provided
      if (imageBytes != null) {
        imageUrl = await _uploadImage(uid, imageBytes);
      }

      // Merge model map with enforced userId and imageUrl + server timestamp
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

  /// Updates an existing task, optionally replacing or removing the image.
  ///
  ///  - If [removeImage] is true → imageUrl is set to null.
  ///  - If [imageBytes] is non-null → a new image is uploaded and its URL is used.
  ///  - [assignedToUid] (inside [task]) is preserved and used as-is.
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

  /// Deletes a task by its Firestore document ID.
  Future<void> deleteTask(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    try {
      await _taskRef.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Firestore delete failed: ${e.message}');
    }
  }

  /// Retrieves a task by its ID, returns null if not found.
  Future<TaskModel?> getTaskById(String id) async {
    final doc = await _taskRef.doc(id).get();
    final data = doc.data();
    if (doc.exists && data != null) {
      return TaskModel.fromMap(data, doc.id);
    }
    return null;
  }

  /// Returns a stream of tasks visible to the current user.
  ///
  /// A task is visible if:
  ///  - current user is the owner (`userId == uid`), OR
  ///  - current user is the assignee (`assignedToUid == uid`).
  ///
  /// This uses Firestore composite filters (Filter.or).
  Stream<List<TaskModel>> getTasks() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _taskRef
        .where(
          Filter.or(
            Filter('userId', isEqualTo: uid),
            Filter('assignedToUid', isEqualTo: uid),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = d.data();
            data['createdAt'] ??= Timestamp.now();
            return TaskModel.fromMap(data, d.id);
          }).toList(),
        );
  }

  /// Returns a stream of tasks filtered by category, still respecting:
  ///  - owner OR assignee.
  Stream<List<TaskModel>> getTasksByCategory(TaskCategory category) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _taskRef
        .where(
          Filter.and(
            Filter.or(
              Filter('userId', isEqualTo: uid),
              Filter('assignedToUid', isEqualTo: uid),
            ),
            Filter('category', isEqualTo: category.name),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = d.data();
            data['createdAt'] ??= Timestamp.now();
            return TaskModel.fromMap(data, d.id);
          }).toList(),
        );
  }

  /// Returns a stream of tasks visible to the current user,
  /// further filtered by [query] (title, description, tags).
  Stream<List<TaskModel>> searchTasks(String query) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    final q = query.toLowerCase();

    return _taskRef
        .where(
          Filter.or(
            Filter('userId', isEqualTo: uid),
            Filter('assignedToUid', isEqualTo: uid),
          ),
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) {
                final data = d.data();
                data['createdAt'] ??= Timestamp.now();
                return TaskModel.fromMap(data, d.id);
              })
              .where(
                (task) =>
                    task.title.toLowerCase().contains(q) ||
                    task.description.toLowerCase().contains(q) ||
                    task.tags.any(
                      (t) => t.toLowerCase().contains(q),
                    ),
              )
              .toList(),
        );
  }

  /// Uploads an image to Firebase Storage and returns its download URL.
  Future<String> _uploadImage(String uid, Uint8List bytes) async {
    final ref = _storage
        .ref()
        .child('task_images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

    return ref.getDownloadURL();
  }
}
