import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import '../../features/settings/presentation/controllers/settings_provider.dart';
import '../../features/onboarding/presentation/controllers/onboarding_provider.dart';
import 'supabase_service.dart';

class ProfileSyncService {
  ProfileSyncService._();

  static Future<void> syncAll(Ref ref) async {
    final client = SupabaseService.client;
    final user = SupabaseService.currentUser;
    if (client == null || user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Fetch cloud profile
      final response = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final cloudSettings = response['settings'] as Map<String, dynamic>? ?? {};

        // Write all settings from cloud to local SharedPreferences (including rate limits, configurations, theme, etc)
        for (final entry in cloudSettings.entries) {
          final key = entry.key;
          final value = entry.value;

          if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          } else if (value is String) {
            await prefs.setString(key, value);
          } else if (value is List) {
            await prefs.setStringList(key, value.map((e) => e.toString()).toList());
          }
        }

        // Notify theme provider
        final isDark = prefs.getBool('is_dark_mode') ?? true;
        ref.read(themeModeProvider.notifier).setThemeMode(isDark);

        // Notify settings provider
        final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        ref.read(settingsProvider.notifier).setNotificationsEnabled(notificationsEnabled);

        // Notify onboarding provider
        final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
        final userName = prefs.getString('user_name') ?? 'Champion';
        ref.read(onboardingProvider.notifier).setOnboardingState(
          completed: onboardingCompleted,
          name: userName,
        );

        // Sync profile name from column if it was updated
        final cloudName = response['name'] as String? ?? 'Champion';
        if (cloudName != 'Champion' && cloudName.isNotEmpty) {
          await prefs.setString('user_name', cloudName);
          ref.read(onboardingProvider.notifier).setOnboardingState(
            completed: onboardingCompleted,
            name: cloudName,
          );
        }

        // Sync streak from columns
        final cloudStreak = response['streak_count'] as int? ?? 0;
        final cloudLastUsed = response['last_active_date'] as String?;
        if (cloudLastUsed != null) {
          await prefs.setString('streak_last_used_date', cloudLastUsed);
          await prefs.setInt('streak_continuous_count', cloudStreak);
        }

        // Push any local adjustments back to cloud to merge
        await pushLocalProfileToCloud();
      } else {
        // Profile row does not exist, create it with local data
        await pushLocalProfileToCloud();
      }
    } catch (e) {
      debugPrint('Error during ProfileSyncService.syncAll: $e');
    }
  }

  static Future<void> pushLocalProfileToCloud() async {
    final client = SupabaseService.client;
    final user = SupabaseService.currentUser;
    if (client == null || user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final Map<String, dynamic> sharedPrefsMap = {};

      // Retrieve all SharedPreferences key-values, excluding Supabase internal auth keys
      for (final key in allKeys) {
        if (key.startsWith('supabase.auth.token')) continue;
        sharedPrefsMap[key] = prefs.get(key);
      }

      final localName = prefs.getString('user_name') ?? 'Champion';
      final localStreak = prefs.getInt('streak_continuous_count') ?? 0;
      final localLastUsed = prefs.getString('streak_last_used_date');

      await client.from('profiles').upsert({
        'id': user.id,
        'name': localName,
        'streak_count': localStreak,
        if (localLastUsed != null) 'last_active_date': localLastUsed,
        'settings': sharedPrefsMap,
      });
    } catch (e) {
      debugPrint('Error pushing local profile to cloud: $e');
    }
  }
}
