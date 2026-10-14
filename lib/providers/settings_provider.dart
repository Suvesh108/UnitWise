import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/native/native_channel.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'unitwise_theme_mode';
  static const String _keyCurrency = 'unitwise_currency';
  static const String _keyOnboarding = 'unitwise_has_completed_onboarding';

  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  String _currency = '₹';
  bool _hasCompletedOnboarding = false;
  Map<String, dynamic> _deviceStats = {};

  SettingsProvider(this._prefs) {
    _loadSettings();
    refreshDeviceStats();
  }

  ThemeMode get themeMode => _themeMode;
  String get currency => _currency;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  Map<String, dynamic> get deviceStats => _deviceStats;

  void _loadSettings() {
    _hasCompletedOnboarding = _prefs.getBool(_keyOnboarding) ?? false;
    final themeStr = _prefs.getString(_keyThemeMode);
    if (themeStr != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => ThemeMode.system,
      );
    }

    final cur = _prefs.getString(_keyCurrency);
    if (cur != null) {
      _currency = cur;
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _prefs.setBool(_keyOnboarding, true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _hasCompletedOnboarding = false;
    await _prefs.setBool(_keyOnboarding, false);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_keyThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> setCurrency(String cur) async {
    _currency = cur;
    await _prefs.setString(_keyCurrency, cur);
    notifyListeners();
  }

  Future<void> refreshDeviceStats() async {
    final stats = await NativeChannel.getDevicePowerStats();
    _deviceStats = stats;
    notifyListeners();
  }
}
