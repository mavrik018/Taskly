import '../entities/project.dart';

abstract class ProjectRepository {
  /// Watch all projects reactively.
  Stream<List<Project>> watchAllProjects();

  /// Get project count (used to enforce free tier limit).
  Future<int> getProjectCount();

  /// Get a single project by its id.
  Future<Project?> getProjectById(int id);

  /// Create a new project and return the new row id.
  Future<int> createProject({
    required String name,
    required String colorHex,
    String? iconName,
  });

  /// Delete a project by id.
  Future<int> deleteProject(int id);
}
