import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
  });

Map<String,dynamic> toMap(){
  return {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'createdAt':  Timestamp.fromDate(createdAt) ,
    'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
  };
}
factory TaskModel.fromMap( Object? obj, String id){
  final map = obj as Map<String, dynamic>;
  return TaskModel(
    id: id,
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    isCompleted: map['isCompleted'] ?? false,
    createdAt: map['createdAt'] ,
    completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
}
}