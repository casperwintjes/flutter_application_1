import 'package:shared_preferences/shared_preferences.dart';

import 'app_storage_interface.dart';

class PlatformAppStorage implements AppStorage {
  PlatformAppStorage({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  SharedPreferences? _resolvedPrefs;

  Future<void> _ensureInitialized() async {
    _resolvedPrefs ??= _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<String?> read(String key) async {
    await _ensureInitialized();
    return _resolvedPrefs?.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    await _ensureInitialized();
    await _resolvedPrefs?.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _ensureInitialized();
    await _resolvedPrefs?.remove(key);
  }
}
