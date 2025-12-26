import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class StorageService {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Regular Storage (SharedPreferences)
  static String? getString(String key) {
    return _prefs?.getString(key);
  }
  
  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }
  
  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }
  
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }
  
  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }
  
  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }
  
  static double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }
  
  static Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }
  
  static List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }
  
  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }
  
  static Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }
  
  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }
  
  // JSON Storage helpers
  static Map<String, dynamic>? getJson(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await setString(key, json.encode(value));
  }
  
  static List<dynamic>? getJsonList(String key) {
    final jsonString = getString(key);
    if (jsonString == null) return null;
    try {
      return json.decode(jsonString) as List<dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  static Future<bool> setJsonList(String key, List<dynamic> value) async {
    return await setString(key, json.encode(value));
  }
  
  // Secure Storage (for sensitive data like tokens)
  static Future<String?> getSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> setSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  static Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  static Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }
  
  static Future<Map<String, String>> getAllSecure() async {
    return await _secureStorage.readAll();
  }
}
