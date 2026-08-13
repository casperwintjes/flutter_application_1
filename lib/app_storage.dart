import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_storage_interface.dart';
import 'app_storage_stub.dart' if (dart.library.html) 'app_storage_web.dart';

export 'app_storage_interface.dart';

Future<AppStorage> createAppStorage({SharedPreferences? prefs}) async {
  if (kIsWeb) {
    return PlatformAppStorage(prefs: prefs);
  }
  return PlatformAppStorage(prefs: prefs);
}
