import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';

class StreakManager {
  static const String _streakCountKey = 'streak_continuous_count';
  static const String _lastUsedDateKey = 'streak_last_used_date';

  /// Recalculates, updates and returns the current daily streak.
  static Future<int> updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final lastUsed = prefs.getString(_lastUsedDateKey);
      int currentStreak = prefs.getInt(_streakCountKey) ?? 0;

      if (lastUsed == null) {
        currentStreak = 1;
      } else {
        final lastDate = DateTime.parse(lastUsed);
        final todayDate = DateTime.parse(todayStr);
        final difference = todayDate.difference(lastDate).inDays;

        if (difference == 1) {
          currentStreak += 1;
        } else if (difference > 1) {
          currentStreak = 1;
        } else if (difference == 0 && currentStreak == 0) {
          currentStreak = 1;
        }
        // If difference == 0 (same day) and currentStreak > 0, it remains unchanged
      }

      await prefs.setString(_lastUsedDateKey, todayStr);
      await prefs.setInt(_streakCountKey, currentStreak);

      // Sync to Supabase in the background if the user is signed in
      await syncStreakToCloud(currentStreak, todayStr);

      return currentStreak;
    } catch (e) {
      debugPrint('Error updating streak: $e');
      return 0;
    }
  }

  /// Synchronizes local streak data with the Supabase profiles database table.
  static Future<void> syncStreakToCloud(int localStreak, String localLastUsed) async {
    final client = SupabaseService.client;
    final user = SupabaseService.currentUser;
    if (client == null || user == null) return;

    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Create profile row on the cloud
        await client.from('profiles').insert({
          'id': user.id,
          'streak_count': localStreak,
          'last_active_date': localLastUsed,
        });
      } else {
        final cloudStreak = response['streak_count'] as int? ?? 0;
        final cloudLastUsed = response['last_active_date'] as String?;

        if (cloudLastUsed == null) {
          // Cloud value has no timestamp, update cloud
          await client.from('profiles').update({
            'streak_count': localStreak,
            'last_active_date': localLastUsed,
          }).eq('id', user.id);
        } else {
          final cloudDate = DateTime.parse(cloudLastUsed);
          final localDate = DateTime.parse(localLastUsed);

          if (localDate.isAfter(cloudDate)) {
            // Local is newer, update cloud
            await client.from('profiles').update({
              'streak_count': localStreak,
              'last_active_date': localLastUsed,
            }).eq('id', user.id);
          } else if (cloudDate.isAfter(localDate) ||
              (cloudDate == localDate && cloudStreak > localStreak)) {
            // Cloud is newer or has a higher count on the same day, update local SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_lastUsedDateKey, cloudLastUsed);
            await prefs.setInt(_streakCountKey, cloudStreak);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing streak to cloud: $e');
    }
  }
}
