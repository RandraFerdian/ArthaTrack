import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyUsername = 'username';
  static const String _keyLastUsername = 'last_username';
  static const String _keyGyroEnabled = 'gyro_enabled';
  static const String _keyNotificationEnabled = 'notification_enabled';
  static const String _keyAccelEnabled = 'accel_enabled';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('SessionManager must be initialized before use.');
    }
    return _prefs!;
  }

  static bool get isLoggedIn => prefs.getBool(_keyIsLoggedIn) ?? false;

  static int? get userId => prefs.getInt(_keyUserId);

  static String? get username => prefs.getString(_keyUsername);

  static String? get lastUsername => prefs.getString(_keyLastUsername);

  static bool get gyroEnabled => prefs.getBool(_keyGyroEnabled) ?? true;

  static bool get accelEnabled => prefs.getBool(_keyAccelEnabled) ?? true;

  static bool get notificationEnabled =>
      prefs.getBool(_keyNotificationEnabled) ?? false;

  static Future<void> saveSession(int userId, String username) async {
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
  }

  static Future<void> saveLastUsername(String username) async {
    await prefs.setString(_keyLastUsername, username);
  }

  static Future<void> clearSession() async {
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
  }

  static Future<void> setGyroEnabled(bool value) async {
    await prefs.setBool(_keyGyroEnabled, value);
  }

  static Future<void> setAccelEnabled(bool value) async {
    await prefs.setBool(_keyAccelEnabled, value);
  }

  static Future<void> setNotificationEnabled(bool value) async {
    await prefs.setBool(_keyNotificationEnabled, value);
  }
}
