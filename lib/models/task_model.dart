import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskCategory {
  work('Work', 0xFF2196F3),
  personal('Personal', 0xFF4CAF50),
  shopping('Shopping', 0xFFFF9800),
  health('Health', 0xFFE91E63),
  finance('Finance', 0xFF9C27B0),
  other('Other', 0xFF607D8B);

  const TaskCategory(this.displayName, this.colorValue);
  final String displayName;
  final int colorValue;
  Color get color => Color(colorValue);
}

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

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    this.category = TaskCategory.other,
    this.tags = const [],
  });

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      // ATTENTION: createdAt géré côté serveur à la création,
      // mais conservé lors des updates si déjà présent.
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'category': category.name,
      'tags': tags,
    };
  }

  factory TaskModel.fromMap(Object? obj, String id) {
    final map = (obj ?? {}) as Map<String, dynamic>;
    final tsCreated = map['createdAt'];
    final tsCompleted = map['completedAt'];

    return TaskModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (tsCreated is Timestamp) ? tsCreated.toDate() : DateTime.now(),
      completedAt: (tsCompleted is Timestamp) ? tsCompleted.toDate() : null,
      category: TaskCategory.values.firstWhere(
        (cat) => cat.name == map['category'],
        orElse: () => TaskCategory.other,
      ),
      tags: List<String>.from(map['tags'] ?? const []),
    );
  }
}
