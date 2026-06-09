import '../repositories/project_repository.dart';

/// Free tier limit for projects.
const int kFreeProjectLimit = 5;

class CreateProject {
  final ProjectRepository _repository;

  CreateProject(this._repository);

  /// Throws [ProjectLimitException] if the free-tier cap (5) is reached.
  Future<int> call({
    required String name,
    required String colorHex,
    String? iconName,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Project name cannot be empty');
    }

    final count = await _repository.getProjectCount();
    if (count >= kFreeProjectLimit) {
      throw ProjectLimitException(
        'Free tier allows up to $kFreeProjectLimit projects. '
        'Delete an existing project to add a new one.',
      );
    }

    return _repository.createProject(
      name: trimmedName,
      colorHex: colorHex,
      iconName: iconName,
    );
  }
}

class ProjectLimitException implements Exception {
  final String message;
  const ProjectLimitException(this.message);

  @override
  String toString() => 'ProjectLimitException: $message';
}
