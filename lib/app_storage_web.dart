import 'dart:html' as html;

import 'package:shared_preferences/shared_preferences.dart';

import 'app_storage_interface.dart';

class PlatformAppStorage implements AppStorage {
  PlatformAppStorage({SharedPreferences? prefs});

  @override
  Future<String?> read(String key) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    html.window.localStorage.remove(key);
  }
}
