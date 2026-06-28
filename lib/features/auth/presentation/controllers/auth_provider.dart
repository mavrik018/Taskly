import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';

// Provider for Sync Service
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(db);
  ref.onDispose(() => service.dispose());
  return service;
});

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    _initListener();
    return SupabaseService.currentUser;
  }

  void _initListener() {
    SupabaseService.authStateChanges.listen((data) {
      state = data.session?.user;
      if (data.session?.user != null) {
        // Trigger sync when user signs in
        ref.read(syncServiceProvider).sync();
      }
    });
  }

  Future<void> signUp(String email, String password) async {
    await SupabaseService.signUp(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    await SupabaseService.signIn(email: email, password: password);
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});
