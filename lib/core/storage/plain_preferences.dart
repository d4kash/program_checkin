import 'storage_policy.dart';

abstract class PlainPreferences {
  Future<void> setString(String key, String value);
  Future<String?> getString(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<Map<String, String>> dumpForTests();
}

class MemoryPlainPreferences implements PlainPreferences {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }

  @override
  Future<Map<String, String>> dumpForTests() async => Map.unmodifiable(_values);
}

class GuardedPlainPreferences implements PlainPreferences {
  GuardedPlainPreferences(this._inner);

  final PlainPreferences _inner;

  @override
  Future<void> setString(String key, String value) async {
    StoragePolicy.assertPlainPreferenceAllowed(key, value);
    await _inner.setString(key, value);
  }

  @override
  Future<String?> getString(String key) => _inner.getString(key);

  @override
  Future<void> remove(String key) => _inner.remove(key);

  @override
  Future<void> clear() => _inner.clear();

  @override
  Future<Map<String, String>> dumpForTests() => _inner.dumpForTests();
}
