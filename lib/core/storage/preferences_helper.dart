import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyLastUsedRiffId = 'last_used_riff_id';
  static const String _keyLastBpm = 'last_bpm';
  static const String _keyMetronomeVolume = 'metronome_volume';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyPracticeReminders = 'practice_reminders';
  static const String _keyNotificationTime = 'notification_time';
  static const String _keyAutoplay = 'autoplay_enabled';
  static const String _keyDefaultTimeSignature = 'default_time_signature';
  static const String _keyQuickStartEnabled = 'quick_start_enabled';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keySkillLevel = 'skill_level';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // First launch
  static Future<bool> isFirstLaunch() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  static Future<void> setFirstLaunchComplete() async {
    final prefs = await _preferences;
    await prefs.setBool(_keyIsFirstLaunch, false);
  }

  // Last used riff
  static Future<String?> getLastUsedRiffId() async {
    final prefs = await _preferences;
    return prefs.getString(_keyLastUsedRiffId);
  }

  static Future<void> setLastUsedRiffId(String riffId) async {
    final prefs = await _preferences;
    await prefs.setString(_keyLastUsedRiffId, riffId);
  }

  // Last BPM
  static Future<int> getLastBpm() async {
    final prefs = await _preferences;
    return prefs.getInt(_keyLastBpm) ?? 80;
  }

  static Future<void> setLastBpm(int bpm) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyLastBpm, bpm);
  }

  // Metronome volume
  static Future<double> getMetronomeVolume() async {
    final prefs = await _preferences;
    return prefs.getDouble(_keyMetronomeVolume) ?? 0.7;
  }

  static Future<void> setMetronomeVolume(double volume) async {
    final prefs = await _preferences;
    await prefs.setDouble(_keyMetronomeVolume, volume);
  }

  // Theme mode
  static Future<String> getThemeMode() async {
    final prefs = await _preferences;
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    final prefs = await _preferences;
    await prefs.setString(_keyThemeMode, mode);
  }

  // Practice reminders
  static Future<bool> getPracticeReminders() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyPracticeReminders) ?? true;
  }

  static Future<void> setPracticeReminders(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyPracticeReminders, enabled);
  }

  // Notification time (stored as minutes since midnight)
  static Future<int> getNotificationTime() async {
    final prefs = await _preferences;
    return prefs.getInt(_keyNotificationTime) ?? (19 * 60); // Default 7:00 PM
  }

  static Future<void> setNotificationTime(int minutesSinceMidnight) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyNotificationTime, minutesSinceMidnight);
  }

  // Autoplay
  static Future<bool> getAutoplayEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyAutoplay) ?? false;
  }

  static Future<void> setAutoplayEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyAutoplay, enabled);
  }

  // Default time signature
  static Future<int> getDefaultTimeSignature() async {
    final prefs = await _preferences;
    return prefs.getInt(_keyDefaultTimeSignature) ?? 4;
  }

  static Future<void> setDefaultTimeSignature(int timeSignature) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyDefaultTimeSignature, timeSignature);
  }

  // Onboarding
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await _preferences;
    await prefs.setBool(_keyOnboardingCompleted, true);
  }

  static Future<void> setOnboardingNotCompleted() async {
    final prefs = await _preferences;
    await prefs.setBool(_keyOnboardingCompleted, false);
  }

  // Skill level: 'principiante', 'intermedio', 'avanzado'
  static Future<String> getSkillLevel() async {
    final prefs = await _preferences;
    return prefs.getString(_keySkillLevel) ?? 'principiante';
  }

  static Future<void> setSkillLevel(String level) async {
    final prefs = await _preferences;
    await prefs.setString(_keySkillLevel, level);
  }

  // Quick start enabled
  static Future<bool> getQuickStartEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyQuickStartEnabled) ?? true;
  }

  static Future<void> setQuickStartEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(_keyQuickStartEnabled, enabled);
  }

  // Practice session settings
  static Future<Map<String, dynamic>> getPracticeSettings() async {
    return {
      'lastBpm': await getLastBpm(),
      'metronomeVolume': await getMetronomeVolume(),
      'autoplayEnabled': await getAutoplayEnabled(),
      'defaultTimeSignature': await getDefaultTimeSignature(),
      'quickStartEnabled': await getQuickStartEnabled(),
    };
  }

  static Future<void> updatePracticeSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('lastBpm')) {
      await setLastBpm(settings['lastBpm'] as int);
    }
    if (settings.containsKey('metronomeVolume')) {
      await setMetronomeVolume(settings['metronomeVolume'] as double);
    }
    if (settings.containsKey('autoplayEnabled')) {
      await setAutoplayEnabled(settings['autoplayEnabled'] as bool);
    }
    if (settings.containsKey('defaultTimeSignature')) {
      await setDefaultTimeSignature(settings['defaultTimeSignature'] as int);
    }
    if (settings.containsKey('quickStartEnabled')) {
      await setQuickStartEnabled(settings['quickStartEnabled'] as bool);
    }
  }

  // User preferences
  static Future<Map<String, dynamic>> getUserPreferences() async {
    return {
      'themeMode': await getThemeMode(),
      'practiceReminders': await getPracticeReminders(),
      'notificationTime': await getNotificationTime(),
      'metronomeVolume': await getMetronomeVolume(),
    };
  }

  static Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    if (preferences.containsKey('themeMode')) {
      await setThemeMode(preferences['themeMode'] as String);
    }
    if (preferences.containsKey('practiceReminders')) {
      await setPracticeReminders(preferences['practiceReminders'] as bool);
    }
    if (preferences.containsKey('notificationTime')) {
      await setNotificationTime(preferences['notificationTime'] as int);
    }
    if (preferences.containsKey('metronomeVolume')) {
      await setMetronomeVolume(preferences['metronomeVolume'] as double);
    }
  }

  // Statistics and analytics
  static Future<void> recordPracticeSession({
    required String riffId,
    required int durationMinutes,
    required int bpm,
    required double accuracy,
  }) async {
    final prefs = await _preferences;
    
    // Update counters
    final totalSessions = prefs.getInt('total_sessions') ?? 0;
    final totalMinutes = prefs.getInt('total_practice_minutes') ?? 0;
    final bestAccuracy = prefs.getDouble('best_accuracy') ?? 0.0;
    
    await prefs.setInt('total_sessions', totalSessions + 1);
    await prefs.setInt('total_practice_minutes', totalMinutes + durationMinutes);
    
    if (accuracy > bestAccuracy) {
      await prefs.setDouble('best_accuracy', accuracy);
    }
    
    // Update last practice
    await prefs.setString('last_practice_date', DateTime.now().toIso8601String());
    await setLastUsedRiffId(riffId);
    await setLastBpm(bpm);
  }

  static Future<Map<String, dynamic>> getStatistics() async {
    final prefs = await _preferences;
    
    return {
      'totalSessions': prefs.getInt('total_sessions') ?? 0,
      'totalPracticeMinutes': prefs.getInt('total_practice_minutes') ?? 0,
      'bestAccuracy': prefs.getDouble('best_accuracy') ?? 0.0,
      'lastPracticeDate': prefs.getString('last_practice_date'),
    };
  }

  // Clear all preferences (for reset/logout)
  static Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.clear();
  }

  // Clear only user data (keep app settings)
  static Future<void> clearUserData() async {
    final prefs = await _preferences;
    final keysToKeep = [
      _keyThemeMode,
      _keyMetronomeVolume,
      _keyDefaultTimeSignature,
    ];
    
    final Map<String, dynamic> settingsToKeep = {};
    for (final key in keysToKeep) {
      if (prefs.containsKey(key)) {
        settingsToKeep[key] = prefs.get(key);
      }
    }
    
    await prefs.clear();
    
    // Restore kept settings
    for (final entry in settingsToKeep.entries) {
      if (entry.value is String) {
        await prefs.setString(entry.key, entry.value as String);
      } else if (entry.value is int) {
        await prefs.setInt(entry.key, entry.value as int);
      } else if (entry.value is double) {
        await prefs.setDouble(entry.key, entry.value as double);
      } else if (entry.value is bool) {
        await prefs.setBool(entry.key, entry.value as bool);
      }
    }
  }
}