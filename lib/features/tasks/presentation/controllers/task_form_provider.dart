import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskFormState {
  final String title;
  final String description;
  final DateTime? dueDate;
  final int priority;
  final int? projectId;

  const TaskFormState({
    this.title = '',
    this.description = '',
    this.dueDate,
    this.priority = 0,
    this.projectId,
  });

  TaskFormState copyWith({
    String? title,
    String? description,
    DateTime? Function()? dueDate,
    int? priority,
    int? Function()? projectId,
  }) {
    return TaskFormState(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      priority: priority ?? this.priority,
      projectId: projectId != null ? projectId() : this.projectId,
    );
  }
}

class TaskFormNotifier extends Notifier<TaskFormState> {
  @override
  TaskFormState build() => const TaskFormState();

  void setTitle(String value) {
    state = state.copyWith(title: value);
  }

  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  void setDueDate(DateTime? value) {
    state = state.copyWith(dueDate: () => value);
  }

  void setPriority(int value) {
    state = state.copyWith(priority: value);
  }

  void setProjectId(int? value) {
    state = state.copyWith(projectId: () => value);
  }

  void reset() {
    state = const TaskFormState();
  }

  void loadFromTask({
    required String title,
    required String description,
    required DateTime? dueDate,
    required int priority,
    required int? projectId,
  }) {
    state = TaskFormState(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      projectId: projectId,
    );
  }
}

final taskFormProvider =
    NotifierProvider.autoDispose<TaskFormNotifier, TaskFormState>(
  TaskFormNotifier.new,
);
