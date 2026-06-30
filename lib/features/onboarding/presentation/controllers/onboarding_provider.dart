import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/profile_sync_service.dart';

class OnboardingState {
  final bool isCompleted;
  final String userName;

  const OnboardingState({this.isCompleted = false, this.userName = ''});
}

class OnboardingController extends AsyncNotifier<OnboardingState> {
  static const _completedKey = 'onboarding_completed';
  static const _nameKey = 'user_name';

  @override
  Future<OnboardingState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_completedKey) ?? false;
    final name = prefs.getString(_nameKey) ?? '';
    return OnboardingState(isCompleted: completed, userName: name);
  }

  Future<void> completeOnboarding(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedKey, true);
      await prefs.setString(_nameKey, name);
      try {
        await ProfileSyncService.pushLocalProfileToCloud();
      } catch (_) {}
      return OnboardingState(isCompleted: true, userName: name);
    });
  }

  void setOnboardingState({required bool completed, required String name}) {
    state = AsyncValue.data(OnboardingState(isCompleted: completed, userName: name));
  }

  Future<void> updateUserName(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, name);

      // Sync name to Supabase profiles table if logged in
      final client = SupabaseService.client;
      final user = SupabaseService.currentUser;
      if (client != null && user != null) {
        try {
          await client.from('profiles').upsert({
            'id': user.id,
            'name': name,
          });
        } catch (e) {
          debugPrint('Error updating name on Supabase: $e');
        }
      }

      return OnboardingState(isCompleted: true, userName: name);
    });
  }

  Future<void> syncProfileName() async {
    final client = SupabaseService.client;
    final user = SupabaseService.currentUser;
    if (client == null || user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localName = prefs.getString(_nameKey) ?? '';
      
      final response = await client.from('profiles').select('name').eq('id', user.id).maybeSingle();
      final metadataName = user.userMetadata?['name'] as String?;

      if (response != null) {
        final cloudName = response['name'] as String? ?? 'Champion';
        if (cloudName != localName && cloudName != 'Champion') {
          // Cloud name wins
          await prefs.setString(_nameKey, cloudName);
          state = AsyncValue.data(OnboardingState(isCompleted: true, userName: cloudName));
        } else if (localName.isNotEmpty && localName != 'Champion' && cloudName == 'Champion') {
          // Local name wins
          await client.from('profiles').upsert({'id': user.id, 'name': localName});
        } else if (cloudName == 'Champion' && metadataName != null && metadataName.isNotEmpty) {
          // Metadata name wins if profiles has default
          await prefs.setString(_nameKey, metadataName);
          await client.from('profiles').upsert({'id': user.id, 'name': metadataName});
          state = AsyncValue.data(OnboardingState(isCompleted: true, userName: metadataName));
        }
      } else {
        // Create profile row if it doesn't exist
        final nameToUse = (localName.isNotEmpty && localName != 'Champion')
            ? localName
            : (metadataName ?? 'Champion');
        await client.from('profiles').insert({
          'id': user.id,
          'name': nameToUse,
        });
        if (nameToUse != localName) {
          await prefs.setString(_nameKey, nameToUse);
          state = AsyncValue.data(OnboardingState(isCompleted: true, userName: nameToUse));
        }
      }
    } catch (e) {
      debugPrint('Error syncing profile name: $e');
    }
  }
}

final onboardingProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
