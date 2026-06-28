import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/tasks.dart';
import 'tables/projects.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, Projects])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        // Enforce foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
        // Clean up temporary/placeholder test tasks
        await customStatement("DELETE FROM tasks WHERE title = 'Smsmkdasndmas' OR title LIKE 'Smsmk%'");
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Recreate tables for the schema upgrade in development
          for (final table in allTables) {
            await m.deleteTable(table.aliasedName);
            await m.createTable(table);
          }
        }
        if (from < 3) {
          // Add sync columns to tasks and projects
          await m.addColumn(tasks, tasks.userId);
          await m.addColumn(tasks, tasks.isSynced);
          await m.addColumn(tasks, tasks.isDeleted);
          await m.addColumn(projects, projects.userId);
          await m.addColumn(projects, projects.isSynced);
          await m.addColumn(projects, projects.isDeleted);
        }
        if (from < 4) {
          // Add completedAt timestamp column
          await m.addColumn(tasks, tasks.completedAt);
        }
      },
    );
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'taskflow.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
