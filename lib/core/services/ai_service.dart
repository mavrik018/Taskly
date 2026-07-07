import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_sync_service.dart';

class AIService {
  static bool get _isPremium {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  // Client-Side Rate & Cooldown Tracker
  static Future<bool> _checkLimitAndTrack(String action, int limitPerDay,
      {Duration? cooldown}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month}-${now.day}";

      // 1. Check daily limit
      final keyCount = 'ai_limit_count_${action}_$dateStr';
      final currentCount = prefs.getInt(keyCount) ?? 0;

      if (currentCount >= limitPerDay) {
        debugPrint(
            'AI Rate Limit Exceeded for $action: $currentCount/$limitPerDay today');
        return false;
      }

      // 2. Check cooldown interval
      if (cooldown != null) {
        final keyLastTime = 'ai_limit_last_time_$action';
        final lastTimeStr = prefs.getString(keyLastTime);
        if (lastTimeStr != null) {
          final lastTime = DateTime.parse(lastTimeStr);
          if (now.difference(lastTime) < cooldown) {
            debugPrint('AI Cooldown active for $action. Please wait.');
            return false;
          }
        }
        await prefs.setString(keyLastTime, now.toIso8601String());
      }

      // 3. Increment usage count
      await prefs.setInt(keyCount, currentCount + 1);
      try {
        await ProfileSyncService.pushLocalProfileToCloud();
      } catch (_) {}
      return true;
    } catch (e) {
      debugPrint('Error evaluating AI rate limits: $e');
      return true; // Fallback to allow if storage fails
    }
  }

  static Future<dynamic> _callEdgeFunction(
      String action, Map<String, dynamic> payload) async {
    final client = Supabase.instance.client;
    final response = await client.functions.invoke(
      'ai-assistants',
      body: {
        'action': action,
        ...payload,
      },
    );
    if (response.status == 200) {
      return response.data;
    } else {
      throw Exception(
          'Edge function returned status ${response.status}: ${response.data}');
    }
  }

  static List<String> _parseList(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    } else if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    }
    throw Exception('Failed to parse list from $data');
  }

  static List<Map<String, dynamic>> _parseListMap(dynamic data) {
    List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is List) {
        raw = decoded;
      } else {
        throw Exception('Failed to parse list of maps from String: $data');
      }
    } else {
      throw Exception(
          'Failed to parse list of maps from $data (type: ${data.runtimeType})');
    }
    return raw.map((e) {
      if (e is Map) {
        return Map<String, dynamic>.from(e);
      } else if (e is String) {
        final decoded = jsonDecode(e);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      throw Exception('Cannot convert element to Map<String,dynamic>: $e');
    }).toList();
  }

  static Map<String, dynamic> _parseMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    throw Exception('Failed to parse map from $data');
  }

  // 1. Smart Task Parser
  // Limits: Max 50/day, cooldown of 3s.
  static Future<Map<String, dynamic>> parseTaskTitle(String sentence) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Smart Task Parser');
    }

    if (sentence.trim().length < 5) {
      throw Exception('Task title too short to parse.');
    }

    final allowed = await _checkLimitAndTrack('parse', 50,
        cooldown: const Duration(seconds: 3));
    if (!allowed) {
      throw Exception('Rate limit exceeded or cooldown active. Please wait.');
    }

    final res = await _callEdgeFunction('parse', {
      'sentence': sentence,
      'currentDate': DateTime.now().toIso8601String(),
    });
    return _parseMap(res);
  }

  // 2. Daily Focus Suggestion
  // Limits: 1 Auto, 2 Manual per day.
  static Future<Map<String, dynamic>> getDailyFocusSuggestions(
      List<Map<String, dynamic>> tasks,
      {required bool isManual}) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Focus Suggestions');
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User session not found.');
    }

    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // 1. Check Server-Side / Database Cache first (to sync across devices) - Bypass on manual regeneration
    if (!isManual) {
      try {
        final cachedResponse = await client
            .from('daily_focus_cache')
            .select('suggestion')
            .eq('user_id', user.id)
            .eq('date', dateStr)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (cachedResponse != null && cachedResponse['suggestion'] != null) {
          final suggestionMap =
              cachedResponse['suggestion'] as Map<String, dynamic>;
          // Save locally to SharedPreferences cache too
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('last_focus_suggestion');
          await prefs.setString(
              'last_focus_suggestion', jsonEncode(suggestionMap));
          await prefs.setString('last_focus_suggestion_date', dateStr);
          return suggestionMap;
        }
      } catch (e) {
        debugPrint('Error reading focus suggestion cache from server: $e');
      }
    }

    // 2. Check client-side rate limits/cooldowns
    final action = isManual ? 'focus_manual' : 'focus_auto';
    final limit = isManual ? 5 : 1;
    final cooldown = isManual ? const Duration(seconds: 5) : null;

    final allowed =
        await _checkLimitAndTrack(action, limit, cooldown: cooldown);
    if (!allowed) {
      if (isManual) {
        final prefs = await SharedPreferences.getInstance();
        final keyCount = 'ai_limit_count_${action}_${now.year}-${now.month}-${now.day}';
        final currentCount = prefs.getInt(keyCount) ?? 0;
        if (currentCount >= limit) {
          throw Exception('Daily suggestion limit reached.');
        }
        throw Exception(
            'Cooldown active. Please wait 5 seconds before regenerating.');
      }
      // Return local cache if rate-limited
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('last_focus_suggestion');
      if (cached != null) return jsonDecode(cached) as Map<String, dynamic>;
      throw Exception(
          'Rate limit exceeded. Please wait before refreshing Suggestions.');
    }

    final res = await _callEdgeFunction('focus', {
      'tasks': tasks,
      'currentDate': now.toIso8601String(),
    });

    final map = _parseMap(res);

    // 3. Save to Local Cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_focus_suggestion');
      await prefs.setString('last_focus_suggestion', jsonEncode(map));
      await prefs.setString('last_focus_suggestion_date', dateStr);
      try {
        await ProfileSyncService.pushLocalProfileToCloud();
      } catch (_) {}
    } catch (_) {}

    // 4. Save to Server-Side Cache
    try {
      await client.from('daily_focus_cache').insert({
        'user_id': user.id,
        'date': dateStr,
        'suggestion': map,
      });
    } catch (e) {
      debugPrint('Error saving focus suggestion cache to server: $e');
    }

    return map;
  }

  static Future<Map<String, dynamic>?> getCachedFocusSuggestion() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final cachedDate = prefs.getString('last_focus_suggestion_date');
    if (cachedDate != dateStr) {
      // Stale cache from a previous day
      return null;
    }
    final cached = prefs.getString('last_focus_suggestion');
    if (cached != null) {
      try {
        return jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  static String _simpleHash(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (31 * hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  // 3. Task Breakdown Assistant
  // Limits: Max 15/day, cooldown of 3s.
  static Future<List<String>> breakDownTask(
      String taskId, String taskTitle) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Task Breakdown');
    }

    final titleHash = _simpleHash(taskTitle);
    final cacheKey = 'breakdown_${taskId}_$titleHash';

    // Check SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      debugPrint('Error reading breakdown cache: $e');
    }

    // Check Limit & Cooldown
    final allowed = await _checkLimitAndTrack('breakdown', 7,
        cooldown: const Duration(seconds: 3));
    if (!allowed) {
      throw Exception(
          'Rate limit exceeded or cooldown active. Please wait a moment.');
    }

    final res = await _callEdgeFunction('breakdown', {
      'taskTitle': taskTitle,
    });
    final list = _parseList(res);

    // Save to SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(list));
      try {
        await ProfileSyncService.pushLocalProfileToCloud();
      } catch (_) {}
    } catch (_) {}

    return list;
  }

  static bool isSameCalendarWeek(DateTime date1, DateTime date2) {
    final monday1 = DateTime(date1.year, date1.month, date1.day)
        .subtract(Duration(days: date1.weekday - 1));
    final monday2 = DateTime(date2.year, date2.month, date2.day)
        .subtract(Duration(days: date2.weekday - 1));
    return monday1.year == monday2.year &&
        monday1.month == monday2.month &&
        monday1.day == monday2.day;
  }

  static Future<String> getWeeklyReviewSummary(
    List<Map<String, dynamic>> completedTasks,
    List<Map<String, dynamic>> overdueTasks,
  ) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Weekly Review');
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User session not found.');
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final timeStr = prefs.getString('last_weekly_review_time');

    if (timeStr != null) {
      final lastGenerated = DateTime.parse(timeStr);
      if (isSameCalendarWeek(lastGenerated, now)) {
        final cached = prefs.getString('last_weekly_review');
        if (cached != null) return cached;
        throw Exception('WEEKLY_LIMIT_REACHED');
      }
    }

    final res = await _callEdgeFunction('weekly', {
      'completedTasks': completedTasks,
      'overdueTasks': overdueTasks,
      'currentDate': now.toIso8601String(),
    });

    String summary;
    if (res is String) {
      summary = res;
    } else if (res is Map && res.containsKey('summary')) {
      summary = res['summary'].toString();
    } else {
      summary = res.toString();
    }

    // Save to Cache
    try {
      await prefs.setString('last_weekly_review', summary);
      await prefs.setString('last_weekly_review_time', now.toIso8601String());
      try {
        await ProfileSyncService.pushLocalProfileToCloud();
      } catch (_) {}
    } catch (_) {}

    return summary;
  }

  // 5. Overdue Task Reschedule Helper
  // Limits: Max 5/day, cooldown of 10 seconds.
  static Future<List<Map<String, dynamic>>> rescheduleOverdueTasks(
    List<Map<String, dynamic>> overdueTasks,
  ) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Rescheduling Helper');
    }

    final allowed = await _checkLimitAndTrack('reschedule', 5,
        cooldown: const Duration(seconds: 10));
    if (!allowed) {
      throw Exception('LIMIT_REACHED');
    }

    final res = await _callEdgeFunction('reschedule', {
      'overdueTasks': overdueTasks,
      'currentDate': DateTime.now().toIso8601String(),
    });
    return _parseListMap(res);
  }

  static Future<int> getRemainingLimit(String action, int limitPerDay) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month}-${now.day}";
      final keyCount = 'ai_limit_count_${action}_$dateStr';
      final currentCount = prefs.getInt(keyCount) ?? 0;
      return (limitPerDay - currentCount).clamp(0, limitPerDay);
    } catch (_) {
      return limitPerDay;
    }
  }

  static Future<Duration> getRemainingCooldown(
      String action, Duration cooldown) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyLastTime = 'ai_limit_last_time_$action';
      final lastTimeStr = prefs.getString(keyLastTime);
      if (lastTimeStr != null) {
        final lastTime = DateTime.parse(lastTimeStr);
        final elapsed = DateTime.now().difference(lastTime);
        if (elapsed < cooldown) {
          return cooldown - elapsed;
        }
      }
    } catch (_) {}
    return Duration.zero;
  }
}
