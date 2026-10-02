import 'dart:async';

class LocalStorage {
  static final LocalStorage instance = LocalStorage._internal();
  LocalStorage._internal();
  factory LocalStorage() => instance;

  final Map<String, dynamic> _memoryStore = {};

  Future<void> write(String key, Object value) async {
    _memoryStore[key] = value;
  }

  Future<Object?> read(String key) async {
    return _memoryStore[key];
  }

  Future<void> remove(String key) async {
    _memoryStore.remove(key);
  }

  Future<void> clear() async {
    _memoryStore.clear();
  }
}
