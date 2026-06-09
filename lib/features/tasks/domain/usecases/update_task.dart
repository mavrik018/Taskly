import '../entities/task.dart';
import '../repositories/task_repository.dart';

class UpdateTask {
  final TaskRepository _repository;

  UpdateTask(this._repository);

  Future<bool> call(Task task) {
    if (task.title.trim().isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }
    return _repository.updateTask(task.copyWith(title: task.title.trim()));
  }
}
