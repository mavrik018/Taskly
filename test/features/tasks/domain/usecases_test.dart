import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/features/tasks/domain/entities/task.dart';
import 'package:taskflow/features/tasks/domain/usecases/create_task.dart';
import 'package:taskflow/features/tasks/domain/usecases/delete_task.dart';
import 'package:taskflow/features/tasks/domain/usecases/update_task.dart';
import '../../../mocks.dart';

void main() {
  late MockTaskRepository mockRepository;
  late CreateTask createTask;
  late UpdateTask updateTask;
  late DeleteTask deleteTask;

  setUpAll(() {
    registerFallbackValue(const Task(id: 0, title: '', priority: 0, isCompleted: false));
  });

  setUp(() {
    mockRepository = MockTaskRepository();
    createTask = CreateTask(mockRepository);
    updateTask = UpdateTask(mockRepository);
    deleteTask = DeleteTask(mockRepository);
  });

  group('CreateTask Usecase', () {
    test('should call createTask on repository when title is valid', () async {
      when(() => mockRepository.createTask(
            title: 'Test Task',
            description: any(named: 'description'),
            dueDate: any(named: 'dueDate'),
            priority: any(named: 'priority'),
            projectId: any(named: 'projectId'),
          )).thenAnswer((_) async => 1);

      final result = await createTask(title: 'Test Task', priority: 1);

      expect(result, 1);
      verify(() => mockRepository.createTask(
            title: 'Test Task',
            description: null,
            dueDate: null,
            priority: 1,
            projectId: null,
          )).called(1);
    });

    test('should throw ArgumentError when title is empty', () async {
      expect(() => createTask(title: '', priority: 1), throwsArgumentError);
    });
  });

  group('UpdateTask Usecase', () {
    const testTask = Task(id: 1, title: 'Old Title', priority: 1, isCompleted: false);

    test('should call updateTask on repository with valid task title', () async {
      when(() => mockRepository.updateTask(any())).thenAnswer((_) async => true);

      final result = await updateTask(testTask.copyWith(title: 'New Title'));

      expect(result, true);
      verify(() => mockRepository.updateTask(any(that: isA<Task>().having((t) => t.title, 'title', 'New Title')))).called(1);
    });
  });

  group('DeleteTask Usecase', () {
    test('should call deleteTask on repository', () async {
      when(() => mockRepository.deleteTask(any())).thenAnswer((_) async => 1);

      final result = await deleteTask(1);

      expect(result, 1);
      verify(() => mockRepository.deleteTask(1)).called(1);
    });
  });
}
