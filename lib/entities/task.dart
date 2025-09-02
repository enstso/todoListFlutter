class Task {
  final String id;
  final String title;
  final String description;
  bool isCompleted;
  final DateTime createdAt;
  DateTime? completedAt;

  Task(
    this.id, 
    this.title, 
    this.description,
      {
        this.isCompleted = false,
         DateTime? createdAt,
          this.completedAt})
          : createdAt = createdAt ?? DateTime.now();

Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id ?? this.id,
      title ?? this.title,
      description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
