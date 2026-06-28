import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'supabase_service.dart';

class SyncService {
  final AppDatabase _db;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService(this._db) {
    _initConnectivityListener();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  void _initConnectivityListener() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isConnected =
          results.any((result) => result != ConnectivityResult.none);
      if (isConnected) {
        sync();
      }
    });
  }

  Future<void> sync() async {
    final client = SupabaseService.client;
    final user = SupabaseService.currentUser;
    if (client == null || user == null) {
      debugPrint(
          'Sync skipped: Supabase not initialized or user not logged in');
      return;
    }

    if (_isSyncing) return;
    _isSyncing = true;

    try {
      debugPrint('Sync: Starting synchronization process...');

      // 1. Push deleted projects
      final deletedProjectsList = await (_db.select(_db.projects)
            ..where((p) => p.isDeleted.equals(true)))
          .get();
      for (final project in deletedProjectsList) {
        await client.from('projects').delete().match({
          'user_id': user.id,
          'id': project.id,
        });
        // Remove locally
        await (_db.delete(_db.projects)..where((p) => p.id.equals(project.id)))
            .go();
      }

      // 2. Push deleted tasks
      final deletedTasksList = await (_db.select(_db.tasks)
            ..where((t) => t.isDeleted.equals(true)))
          .get();
      for (final task in deletedTasksList) {
        await client.from('tasks').delete().match({
          'user_id': user.id,
          'id': task.id,
        });
        // Remove locally
        await (_db.delete(_db.tasks)..where((t) => t.id.equals(task.id))).go();
      }

      // 3. Push unsynced projects
      final unsyncedProjectsList = await (_db.select(_db.projects)
            ..where(
                (p) => p.isSynced.equals(false) & p.isDeleted.equals(false)))
          .get();

      for (final project in unsyncedProjectsList) {
        await client.from('projects').upsert({
          'id': project.id,
          'user_id': user.id,
          'name': project.name,
          'color_hex': project.colorHex,
          'icon_name': project.iconName,
        });
        // Mark as synced locally
        await (_db.update(_db.projects)..where((p) => p.id.equals(project.id)))
            .write(
          const ProjectsCompanion(
            isSynced: Value(true),
            userId: Value(null), // optionally set here or below
          ),
        );
      }

      // 4. Push unsynced tasks
      final unsyncedTasksList = await (_db.select(_db.tasks)
            ..where(
                (t) => t.isSynced.equals(false) & t.isDeleted.equals(false)))
          .get();

      for (final task in unsyncedTasksList) {
        await client.from('tasks').upsert({
          'id': task.id,
          'user_id': user.id,
          'title': task.title,
          'description': task.description,
          'due_date': task.dueDate?.toIso8601String(),
          'priority': task.priority,
          'project_id': task.projectId,
          'is_completed': task.isCompleted,
          'completed_at': task.completedAt?.toIso8601String(),
        });
        // Mark as synced locally
        await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
          const TasksCompanion(
            isSynced: Value(true),
          ),
        );
      }

      // 5. Pull projects from Supabase
      final List<dynamic> remoteProjects =
          await client.from('projects').select().eq('user_id', user.id);
      for (final rp in remoteProjects) {
        final int id = rp['id'];
        final String name = rp['name'];
        final String colorHex = rp['color_hex'];
        final String? iconName = rp['icon_name'];

        final existing = await (_db.select(_db.projects)
              ..where((p) => p.id.equals(id)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.projects).insert(
                ProjectsCompanion.insert(
                  id: Value(id),
                  name: name,
                  colorHex: colorHex,
                  iconName: Value(iconName),
                  userId: Value(user.id),
                  isSynced: const Value(true),
                  isDeleted: const Value(false),
                ),
              );
        } else if (!existing.isSynced) {
          // Local changes conflict, skip or let local win
        } else {
          // Update local
          await (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(
            ProjectsCompanion(
              name: Value(name),
              colorHex: Value(colorHex),
              iconName: Value(iconName),
              userId: Value(user.id),
              isSynced: const Value(true),
            ),
          );
        }
      }

      // 6. Pull tasks from Supabase
      final List<dynamic> remoteTasks =
          await client.from('tasks').select().eq('user_id', user.id);
      for (final rt in remoteTasks) {
        final int id = rt['id'];
        final String title = rt['title'];
        final String? description = rt['description'];
        final DateTime? dueDate =
            rt['due_date'] != null ? DateTime.parse(rt['due_date']) : null;
        final int priority = rt['priority'];
        final int? projectId = rt['project_id'];
        final bool isCompleted = rt['is_completed'];
        final DateTime? completedAt = rt['completed_at'] != null
            ? DateTime.parse(rt['completed_at'])
            : null;

        final existing = await (_db.select(_db.tasks)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (existing == null) {
          await _db.into(_db.tasks).insert(
                TasksCompanion.insert(
                  id: Value(id),
                  title: title,
                  description: Value(description),
                  dueDate: Value(dueDate),
                  priority: Value(priority),
                  projectId: Value(projectId),
                  isCompleted: Value(isCompleted),
                  completedAt: Value(completedAt),
                  userId: Value(user.id),
                  isSynced: const Value(true),
                  isDeleted: const Value(false),
                ),
              );
        } else if (!existing.isSynced) {
          // Local changes conflict, skip or let local win
        } else {
          // Update local
          await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
            TasksCompanion(
              title: Value(title),
              description: Value(description),
              dueDate: Value(dueDate),
              priority: Value(priority),
              projectId: Value(projectId),
              isCompleted: Value(isCompleted),
              completedAt: Value(completedAt),
              userId: Value(user.id),
              isSynced: const Value(true),
            ),
          );
        }
      }

      debugPrint('Sync: Synchronization completed successfully.');
    } catch (e) {
      debugPrint('Sync: Error during synchronization: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
