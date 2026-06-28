import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return true; // Rate limits disabled for now
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
    // Each element may be a Map or a JSON-encoded String (stale cache edge case)
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
  // Limits: Max 100/day, cooldown of 5s between requests.
  static Future<Map<String, dynamic>> parseTaskTitle(String sentence) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Smart Task Parser');
    }

    final allowed = await _checkLimitAndTrack('parse', 100,
        cooldown: const Duration(seconds: 5));
    if (!allowed) {
      throw Exception('Rate limit exceeded. Please try again later.');
    }

    final res = await _callEdgeFunction('parse', {
      'sentence': sentence,
      'currentDate': DateTime.now().toIso8601String(),
    });
    return _parseMap(res);
  }

  // 2. Daily Focus Suggestion
  // Limits: Max 5/day, cooldown of 15 minutes. Returns cached results if limited.
  static Future<Map<String, dynamic>> getDailyFocusSuggestions(
      List<Map<String, dynamic>> tasks) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Focus Suggestions');
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('last_focus_suggestion');

    final allowed = await _checkLimitAndTrack('focus', 5,
        cooldown: const Duration(minutes: 15));
    if (!allowed) {
      if (cached != null) return jsonDecode(cached) as Map<String, dynamic>;
      throw Exception(
          'Rate limit exceeded. Please wait before refreshing Suggestions.');
    }

    final res = await _callEdgeFunction('focus', {
      'tasks': tasks,
      'currentDate': DateTime.now().toIso8601String(),
    });

    final map = _parseMap(res);
    await prefs.setString('last_focus_suggestion', jsonEncode(map));
    return map;
  }

  static Future<Map<String, dynamic>?> getCachedFocusSuggestion() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('last_focus_suggestion');
    if (cached != null) {
      try {
        return jsonDecode(cached) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  // 3. Task Breakdown Assistant
  // Limits: Max 15/day, cooldown of 10s.
  static Future<List<String>> breakDownTask(String taskTitle) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Task Breakdown');
    }

    final allowed = await _checkLimitAndTrack('breakdown', 15,
        cooldown: const Duration(seconds: 10));
    if (!allowed) {
      throw Exception('Rate limit exceeded. Please wait a moment.');
    }

    final res = await _callEdgeFunction('breakdown', {
      'taskTitle': taskTitle,
    });
    return _parseList(res);
  }

  // 4. Weekly Review Summary
  // Limits: Max 3/day, cooldown of 1 hour. Returns cached results if limited.
  static Future<String> getWeeklyReviewSummary(
    List<Map<String, dynamic>> completedTasks,
    List<Map<String, dynamic>> overdueTasks,
  ) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Weekly Review');
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('last_weekly_review');

    final allowed = await _checkLimitAndTrack('weekly', 3,
        cooldown: const Duration(hours: 1));
    if (!allowed) {
      if (cached != null) return cached;
      throw Exception(
          'Rate limit exceeded. Please wait before requesting Weekly wrap-up.');
    }

    final res = await _callEdgeFunction('weekly', {
      'completedTasks': completedTasks,
      'overdueTasks': overdueTasks,
      'currentDate': DateTime.now().toIso8601String(),
    });
    String summary;
    if (res is String) {
      summary = res;
    } else if (res is Map && res.containsKey('summary')) {
      summary = res['summary'].toString();
    } else {
      summary = res.toString();
    }

    await prefs.setString('last_weekly_review', summary);
    return summary;
  }

  // 5. Overdue Task Reschedule Helper
  // Limits: Max 5/day, cooldown of 1 minute.
  static Future<List<Map<String, dynamic>>> rescheduleOverdueTasks(
    List<Map<String, dynamic>> overdueTasks,
  ) async {
    if (!_isPremium) {
      throw Exception('Premium authorization required for Rescheduling Helper');
    }

    final allowed = await _checkLimitAndTrack('reschedule', 5,
        cooldown: const Duration(minutes: 1));
    if (!allowed) {
      throw Exception('Rate limit exceeded. Please wait a minute.');
    }

    final res = await _callEdgeFunction('reschedule', {
      'overdueTasks': overdueTasks,
      'currentDate': DateTime.now().toIso8601String(),
    });
    return _parseListMap(res);
  }
}
