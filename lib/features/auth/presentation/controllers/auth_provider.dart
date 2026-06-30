import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskflow/features/onboarding/presentation/controllers/onboarding_provider.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/services/profile_sync_service.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';

// Provider for Sync Service
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(db, ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    _initListener();
    final user = SupabaseService.currentUser;
    if (user != null) {
      Future.microtask(() async {
        try {
          ref.read(syncServiceProvider).sync();
          await ProfileSyncService.syncAll(ref);
        } catch (_) {}
      });
    }
    return user;
  }

  void _initListener() {
    SupabaseService.authStateChanges.listen((data) async {
      state = data.session?.user;
      if (data.session?.user != null) {
        // Trigger sync when user signs in
        ref.read(syncServiceProvider).sync();
        // Sync profile, settings, dark mode, streak
        await ProfileSyncService.syncAll(ref);
      }
    });
  }

  Future<void> signUp(String email, String password, {String? name}) async {
    await SupabaseService.signUp(email: email, password: password, name: name);
  }

  Future<void> signIn(String email, String password) async {
    await SupabaseService.signIn(email: email, password: password);
  }

  Future<void> signOut() async {
    // 1. Sync first
    try {
      await ref.read(syncServiceProvider).sync();
    } catch (e) {
      debugPrint('Sync failed before signOut: $e');
    }

    // 2. Delete all local database data
    try {
      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        await db.delete(db.tasks).go();
        await db.delete(db.projects).go();
      });
    } catch (e) {
      debugPrint('Failed to clear database: $e');
    }

    // 3. Clear SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Failed to clear shared preferences: $e');
    }

    // 4. Perform Supabase signOut
    await SupabaseService.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});
