import '../repositories/task_repository.dart';

class DeleteTask {
  final TaskRepository _repository;

  DeleteTask(this._repository);

  Future<int> call(int id) {
    return _repository.deleteTask(id);
  }
}
