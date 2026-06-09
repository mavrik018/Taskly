import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

class TaskDao {
  final AppDatabase _db;

  TaskDao(this._db);

  Stream<List<TaskEntry>> watchAllTasks() {
    return (_db.select(_db.tasks)
          ..orderBy([
            (t) => OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Stream<List<TaskEntry>> watchTasksForProject(int projectId) {
    return (_db.select(_db.tasks)
          ..where((t) => t.projectId.equals(projectId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.dueDate, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<TaskEntry?> getTaskById(int id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTask(TasksCompanion task) {
    return _db.into(_db.tasks).insert(task);
  }

  Future<bool> updateTask(TaskEntry task) {
    return _db.update(_db.tasks).replace(task);
  }

  Future<int> deleteTask(int id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }
}
