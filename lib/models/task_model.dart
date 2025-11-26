import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum describing the category of a task.
enum TaskCategory {
  work,
  personal,
  shopping,
  other,
}

extension TaskCategoryX on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.work:
        return 'Work';
      case TaskCategory.personal:
        return 'Personal';
      case TaskCategory.shopping:
        return 'Shopping';
      case TaskCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.personal:
        return Colors.purple;
      case TaskCategory.shopping:
        return Colors.green;
      case TaskCategory.other:
        return Colors.grey;
    }
  }

  static TaskCategory fromName(String? name) {
    return TaskCategory.values.firstWhere(
      (c) => c.name == name,
      orElse: () => TaskCategory.other,
    );
  }
}

/// Domain model representing a single task stored in Firestore.
class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final TaskCategory category;
  final List<String> tags;
  final String? imageUrl;

  /// Optional assignee email (for display / UX).
  final String? assignedTo;

  /// Optional UID of the assignee (used for queries / security).
  final String? assignedToUid;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.category,
    required this.tags,
    this.imageUrl,
    this.assignedTo,
    this.assignedToUid,
  });

  /// Creates a [TaskModel] from Firestore data.
  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['createdAt'];
    final completedTs = map['completedAt'];

    return TaskModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      completedAt:
          completedTs is Timestamp ? completedTs.toDate() : null,
      category: TaskCategoryX.fromName(map['category'] as String?),
      tags: (map['tags'] as List<dynamic>? ?? []).cast<String>(),
      imageUrl: map['imageUrl'] as String?,
      assignedTo: map['assignedTo'] as String?,
      assignedToUid: map['assignedToUid'] as String?,
    );
  }

  /// Serializes this model to a Firestore-friendly Map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'category': category.name,
      'tags': tags,
      'imageUrl': imageUrl,
      'assignedTo': assignedTo,
      'assignedToUid': assignedToUid,
    };
  }

  /// Returns a copy with some fields overridden.
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    TaskCategory? category,
    List<String>? tags,
    String? imageUrl,
    String? assignedTo,
    String? assignedToUid,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToUid: assignedToUid ?? this.assignedToUid,
    );
  }
}
