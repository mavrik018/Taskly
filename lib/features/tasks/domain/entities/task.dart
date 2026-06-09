class Task {
  final int id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final int priority; // 1 = High, 2 = Medium, 3 = Low, 4 = None/Neutral
  final int? projectId;
  final bool isCompleted;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.priority,
    this.projectId,
    required this.isCompleted,
  });

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? Function()? dueDate,
    int? Function()? projectId,
    int? priority,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      projectId: projectId != null ? projectId() : this.projectId,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
