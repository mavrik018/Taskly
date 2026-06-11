import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      return OnboardingState(isCompleted: true, userName: name);
    });
  }

  Future<void> updateUserName(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, name);
      return OnboardingState(isCompleted: true, userName: name);
    });
  }
}

final onboardingProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
