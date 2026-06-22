import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsNotifier extends ChangeNotifier {
  static const _prefsKey = 'local_notifications_enabled';

  bool _localNotificationsEnabled = true;
  bool _isLoaded = false;

  bool get localNotificationsEnabled => _localNotificationsEnabled;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _localNotificationsEnabled = prefs.getBool(_prefsKey) ?? true;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLocalNotificationsEnabled(bool enabled) async {
    if (_localNotificationsEnabled == enabled && _isLoaded) return;

    _localNotificationsEnabled = enabled;
    _isLoaded = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}
