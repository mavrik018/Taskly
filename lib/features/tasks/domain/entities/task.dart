class Task {
  final int id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final int priority; // 1 = High, 2 = Medium, 3 = Low, 4 = None/Neutral
  final int? projectId;
  final bool isCompleted;
  final DateTime? completedAt; // Set when task is marked complete

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.priority,
    this.projectId,
    required this.isCompleted,
    this.completedAt,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? Function()? dueDate,
    int? Function()? projectId,
    int? priority,
    bool? isCompleted,
    DateTime? Function()? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      projectId: projectId != null ? projectId() : this.projectId,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
    );
  }
}
