import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/app_database.dart';

class SettingsNotifier extends Notifier<SettingsState> {
  static const _notificationsKey = 'notifications_enabled';
  static const _subscriptionKey = 'subscription_tier';

  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState(
      notificationsEnabled: true,
      subscriptionTier: 'FREE',
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    final subscriptionTier = prefs.getString(_subscriptionKey) ?? 'FREE';
    state = SettingsState(
      notificationsEnabled: notificationsEnabled,
      subscriptionTier: subscriptionTier,
    );
  }

  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> setSubscriptionTier(String tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionKey, tier);
    state = state.copyWith(subscriptionTier: tier);
  }

  Future<void> clearAllData(AppDatabase db) async {
    await db.delete(db.tasks).go();
    await db.delete(db.projects).go();
  }
}

class SettingsState {
  final bool notificationsEnabled;
  final String subscriptionTier;

  SettingsState({
    required this.notificationsEnabled,
    required this.subscriptionTier,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    String? subscriptionTier,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);


