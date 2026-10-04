import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static final LocalStorage instance = LocalStorage._internal();
  LocalStorage._internal();
  factory LocalStorage() => instance;

  final Map<String, dynamic> _memoryStore = {};
  SharedPreferences? _preferences;

  Future<SharedPreferences> _getPreferences() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> write(String key, Object value) async {
    _memoryStore[key] = value;
    final preferences = await _getPreferences();
    await preferences.setString(key, value.toString());
  }

  Future<Object?> read(String key) async {
    if (_memoryStore.containsKey(key)) return _memoryStore[key];
    final preferences = await _getPreferences();
    final value = preferences.getString(key);
    if (value != null) _memoryStore[key] = value;
    return value;
  }

  Future<void> remove(String key) async {
    _memoryStore.remove(key);
    final preferences = await _getPreferences();
    await preferences.remove(key);
  }

  Future<void> clear() async {
    _memoryStore.clear();
    final preferences = await _getPreferences();
    await preferences.clear();
  }
}
