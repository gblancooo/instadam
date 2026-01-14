import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _rememberUserKey = 'rememberUser';
  static const String _usernameKey = 'username';

  static Future<void> setRememberUser(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberUserKey, remember);
  }

  static Future<bool> getRememberUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberUserKey) ?? false;
  }

  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}