import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/datasources/task_dao.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../../../core/utils/notification_manager.dart';
import '../../../settings/presentation/controllers/settings_provider.dart';
import '../../../../core/utils/streak_manager.dart';

// Provider for the Drift Database instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Provider for Task Repository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepositoryImpl(TaskDao(db));
});

// Stream Provider for all tasks sorted by priority and due date
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchAllTasks();
});

// Stream Provider for tasks filtered by a specific Project ID
final projectTasksStreamProvider =
    StreamProvider.family<List<Task>, int>((ref, projectId) {
  final repository = ref.watch(taskRepositoryProvider);
  return repository.watchTasksForProject(projectId);
});

// Controller for Task CRUD operations
class TasksController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  Future<int?> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    required int priority,
    int? projectId,
  }) async {
    int? createdId;
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      final useCase = CreateTask(_repository);
      createdId = await useCase(
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        projectId: projectId,
      );

      final notificationsEnabled = ref.read(settingsProvider).notificationsEnabled;

      // Schedule reminder if due date/time is set in the future
      if (notificationsEnabled && createdId != null && dueDate != null && dueDate.isAfter(DateTime.now())) {
        await NotificationManager.scheduleNotification(
          id: createdId!,
          title: title,
          scheduledTime: dueDate,
        );
      }
    });
    state = result;
    return createdId;
  }

  Future<void> toggleCompletion(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = UpdateTask(_repository);
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await useCase(updatedTask);

      if (updatedTask.isCompleted) {
        // Cancel notification on completion
        await NotificationManager.cancelNotification(updatedTask.id);
        // Update daily streak
        await StreakManager.updateStreak();
      } else {
        final notificationsEnabled = ref.read(settingsProvider).notificationsEnabled;
        // Reschedule reminder on uncomposing if due date is in the future
        if (notificationsEnabled && updatedTask.dueDate != null && updatedTask.dueDate!.isAfter(DateTime.now())) {
          await NotificationManager.scheduleNotification(
            id: updatedTask.id,
            title: updatedTask.title,
            scheduledTime: updatedTask.dueDate!,
          );
        }
      }
    });
  }

  Future<void> updateTaskDetails(Task task) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = UpdateTask(_repository);
      await useCase(task);

      // Update scheduled notification
      await NotificationManager.cancelNotification(task.id);
      final notificationsEnabled = ref.read(settingsProvider).notificationsEnabled;
      if (notificationsEnabled && !task.isCompleted && task.dueDate != null && task.dueDate!.isAfter(DateTime.now())) {
        await NotificationManager.scheduleNotification(
          id: task.id,
          title: task.title,
          scheduledTime: task.dueDate!,
        );
      }
    });
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = DeleteTask(_repository);
      await useCase(id);
      // Cancel notification on deletion
      await NotificationManager.cancelNotification(id);
    });
  }
}

final tasksControllerProvider =
    NotifierProvider<TasksController, AsyncValue<void>>(
  TasksController.new,
);
