import '../entities/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchAllTasks();
  Stream<List<Task>> watchTasksForProject(int projectId);
  Future<Task?> getTaskById(int id);
  Future<int> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    required int priority,
    int? projectId,
  });
  Future<bool> updateTask(Task task);
  Future<int> deleteTask(int id);
}
