import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String noFapBox = 'no_fap_box';
  static const String profileBox = 'profile_box';
  static const String settingsBox = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(noFapBox);
    await Hive.openBox(profileBox);
    await Hive.openBox(settingsBox);
  }

  // ─── No Fap Cache ──────────────────────────────────────────
  
  static DateTime? getNoFapResetDate() {
    final box = Hive.box(noFapBox);
    final dateStr = box.get('last_reset_date');
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('DayStack Debug: Error parsing cached date: $e');
      return null;
    }
  }

  static Future<void> saveNoFapResetDate(DateTime date) async {
    final box = Hive.box(noFapBox);
    await box.put('last_reset_date', date.toIso8601String());
  }

  // ─── Profile Cache ─────────────────────────────────────────
  
  static Map<String, dynamic>? getProfile() {
    final box = Hive.box(profileBox);
    final data = box.get('user_profile');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final box = Hive.box(profileBox);
    await box.put('user_profile', profile);
  }

  // ─── Helper for fast flags (SharedPreferences) ─────────────
  
  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }
}
