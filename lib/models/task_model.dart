import 'package:intl/intl.dart';

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
    'createdAt': DateFormat.yMEd().add_jms().format(createdAt)  ,
    'completedAt': completedAt!=null ? DateFormat.yMEd().add_jms().format(completedAt!) : null,
  };
}

factory TaskModel.fromMap(Map<String,dynamic> map, String id){
  return TaskModel(
    id: id,
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    isCompleted: map['isCompleted'] ?? false,
    createdAt: DateFormat.yMEd().add_jms().parse(map['createdAt'] ?? ''),
    completedAt: map['completedAt'] != null ? DateFormat.yMEd().add_jms().parse(map['completedAt']) : null,
  );
}
}