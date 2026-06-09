import '../repositories/task_repository.dart';

class CreateTask {
  final TaskRepository _repository;

  CreateTask(this._repository);

  Future<int> call({
    required String title,
    String? description,
    DateTime? dueDate,
    required int priority,
    int? projectId,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }
    return _repository.createTask(
      title: title.trim(),
      description: description,
      dueDate: dueDate,
      priority: priority,
      projectId: projectId,
    );
  }
}
