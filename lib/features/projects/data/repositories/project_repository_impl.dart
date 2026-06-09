import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_dao.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectDao _dao;

  ProjectRepositoryImpl(this._dao);

  @override
  Stream<List<Project>> watchAllProjects() {
    return _dao.watchAllProjects().map(
          (entries) => entries.map(_entryToProject).toList(),
        );
  }

  @override
  Future<int> getProjectCount() {
    return _dao.countProjects();
  }

  @override
  Future<Project?> getProjectById(int id) async {
    final entry = await _dao.getProjectById(id);
    return entry == null ? null : _entryToProject(entry);
  }

  @override
  Future<int> createProject({
    required String name,
    required String colorHex,
    String? iconName,
  }) {
    return _dao.insertProject(
      ProjectsCompanion.insert(
        name: name,
        colorHex: colorHex,
        iconName: Value(iconName),
      ),
    );
  }

  @override
  Future<int> deleteProject(int id) {
    return _dao.deleteProject(id);
  }

  Project _entryToProject(ProjectEntry entry) {
    return Project(
      id: entry.id,
      name: entry.name,
      colorHex: entry.colorHex,
      iconName: entry.iconName,
    );
  }
}
