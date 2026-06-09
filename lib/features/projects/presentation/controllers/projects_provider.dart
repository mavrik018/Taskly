import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../data/datasources/project_dao.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/create_project.dart';
import '../../domain/usecases/delete_project.dart';

// ─── Repository Provider ────────────────────────────────────────────────────

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProjectRepositoryImpl(ProjectDao(db));
});

// ─── Stream Provider ─────────────────────────────────────────────────────────

final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAllProjects();
});

// ─── State ────────────────────────────────────────────────────────────────────

class ProjectsState {
  final List<Project> projects;
  final bool isLoading;
  final String? errorMessage;

  const ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ProjectsState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class ProjectsController extends Notifier<ProjectsState> {
  @override
  ProjectsState build() => const ProjectsState();

  ProjectRepository get _repository => ref.read(projectRepositoryProvider);

  Future<void> addProject({
    required String name,
    required String colorHex,
    String? iconName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final useCase = CreateProject(_repository);
      await useCase(name: name, colorHex: colorHex, iconName: iconName);
      state = state.copyWith(isLoading: false);
    } on ProjectLimitException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create project: $e',
      );
    }
  }

  Future<void> deleteProject(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final useCase = DeleteProject(_repository);
      await useCase(id);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete project: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final projectsControllerProvider =
    NotifierProvider<ProjectsController, ProjectsState>(
  ProjectsController.new,
);
