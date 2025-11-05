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

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'category': category.name, 
      'tags': tags, 
    };
  }

  factory TaskModel.fromMap(Object? obj, String id) {
    final map = obj as Map<String, dynamic>;
    return TaskModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      category: TaskCategory.values.firstWhere(
        (cat) => cat.name == map['category'],
        orElse: () => TaskCategory.other,
      ), 
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}
