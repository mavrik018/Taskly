import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

class ProjectDao {
  final AppDatabase _db;

  ProjectDao(this._db);

  Stream<List<ProjectEntry>> watchAllProjects() {
    return (_db.select(_db.projects)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<int> countProjects() async {
    final count = _db.projects.id.count();
    final query = _db.selectOnly(_db.projects)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> insertProject(ProjectsCompanion project) {
    return _db.into(_db.projects).insert(project);
  }

  Future<int> deleteProject(int id) {
    return (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();
  }

  Future<ProjectEntry?> getProjectById(int id) {
    return (_db.select(_db.projects)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }
}
