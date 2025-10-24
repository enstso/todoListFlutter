import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? reminderAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    this.reminderAt,
  });

Map<String,dynamic> toMap(){
  return {
    'userId': userId,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'createdAt':  Timestamp.fromDate(createdAt) ,
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
  };
}
factory TaskModel.fromMap( Object? obj, String id){
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
    reminderAt: map['reminderAt'] != null
          ? (map['reminderAt'] as Timestamp).toDate()
          : null,
    );
}
}