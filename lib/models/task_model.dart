import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Enum representing task categories, each with a display name and color
enum TaskCategory {
  work('Work', 0xFF2196F3),
  personal('Personal', 0xFF4CAF50),
  shopping('Shopping', 0xFFFF9800),
  health('Health', 0xFFE91E63),
  finance('Finance', 0xFF9C27B0),
  other('Other', 0xFF607D8B);

  // Constructor storing display name and color value
  const TaskCategory(this.displayName, this.colorValue);

  // Display name shown in UI
  final String displayName;

  // Hex color value for the category
  final int colorValue;

  // Returns a Flutter Color object from the stored integer
  Color get color => Color(colorValue);
}

// Main model representing a task stored in Firestore
class TaskModel {
  // Unique Firestore document ID
  final String id;

  // ID of the user who owns this task
  final String userId;

  // Task title
  final String title;

  // Optional task description
  final String description;

  // Status: whether the task is completed or not
  final bool isCompleted;

  // Date the task was created
  final DateTime createdAt;

  // Date the task was completed (nullable)
  final DateTime? completedAt;

  // Visual category of the task
  final TaskCategory category;

  // List of textual tags attached to the task
  final List<String> tags;

  // Optional image URL stored in Firebase Storage
  final String? imageUrl;

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
    this.imageUrl
  });

  // Creates a new copy of the task with updated fields (immutability helper)
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
    String? imageUrl
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
      imageUrl: imageUrl ?? this.imageUrl
    );
  }

  // Converts the task into a Firestore-friendly map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt), // Firestore timestamp
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'category': category.name,
      'tags': tags,
      'imageUrl': imageUrl
    };
  }

  // Factory constructor converting Firestore data into a TaskModel
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
      imageUrl: map['imageUrl'] as String?
    );
  }
}
