import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_dao.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskDao _taskDao;

  TaskRepositoryImpl(this._taskDao);

  Task _mapToEntity(TaskEntry entry) {
    return Task(
      id: entry.id,
      title: entry.title,
      description: entry.description,
      dueDate: entry.dueDate,
      priority: entry.priority,
      projectId: entry.projectId,
      isCompleted: entry.isCompleted,
    );
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    return _taskDao.watchAllTasks().map((list) => list.map(_mapToEntity).toList());
  }

  @override
  Stream<List<Task>> watchTasksForProject(int projectId) {
    return _taskDao.watchTasksForProject(projectId).map((list) => list.map(_mapToEntity).toList());
  }

  @override
  Future<Task?> getTaskById(int id) async {
    final entry = await _taskDao.getTaskById(id);
    if (entry == null) return null;
    return _mapToEntity(entry);
  }

  @override
  Future<int> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    required int priority,
    int? projectId,
  }) {
    return _taskDao.insertTask(
      TasksCompanion.insert(
        title: title,
        description: Value(description),
        dueDate: Value(dueDate),
        priority: Value(priority),
        projectId: Value(projectId),
        isCompleted: const Value(false),
      ),
    );
  }

  @override
  Future<bool> updateTask(Task task) {
    return _taskDao.updateTask(
      TaskEntry(
        id: task.id,
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        priority: task.priority,
        projectId: task.projectId,
        isCompleted: task.isCompleted,
      ),
    );
  }

  @override
  Future<int> deleteTask(int id) {
    return _taskDao.deleteTask(id);
  }
}
