import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _nameKey = 'user_name';
  static const String _expiryKey = 'auth_expiry';

  static Future<void> saveLoginData({
    required String token,
    required String name,
    required String expiry,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_expiryKey, expiry);
  }

  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();

    final expiryStr = prefs.getString(_expiryKey);
    if (expiryStr == null) return true;

    final expiry = DateTime.parse(expiryStr);

    return DateTime.now().isAfter(expiry);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

