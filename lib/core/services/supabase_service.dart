import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty ||
        url.contains('your-supabase-url') ||
        anonKey.isEmpty ||
        anonKey.contains('your-anon-key')) {
      throw Exception(
          'CRITICAL: Supabase URL or Anon Key is missing or using default placeholders. Please define them using env.json or --dart-define.');
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
  }

  static SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static User? get currentUser => client?.auth.currentUser;

  static Session? get currentSession => client?.auth.currentSession;

  static Stream<AuthState> get authStateChanges {
    final c = client;
    if (c == null) return const Stream.empty();
    return c.auth.onAuthStateChange;
  }

  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase is not initialized');
    return await c.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );
  }

  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final c = client;
    if (c == null) throw Exception('Supabase is not initialized');
    return await c.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    final c = client;
    if (c == null) return;
    await c.auth.signOut();
  }
}
