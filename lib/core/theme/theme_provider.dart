import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_sync_service.dart';

class ThemeModeNotifier extends Notifier<bool> {
  static const _key = 'is_dark_mode';

  @override
  bool build() {
    _loadTheme();
    return true;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggleTheme() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
    try {
      // Lazy load profile_sync_service to avoid circular reference if any
      await ProfileSyncService.pushLocalProfileToCloud();
    } catch (_) {}
  }

  void setThemeMode(bool isDark) {
    state = isDark;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, bool>(
  ThemeModeNotifier.new,
);
