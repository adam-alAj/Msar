import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/solar_service.dart';

/// Extended theme modes: system, light, dark, autoSolar.
enum AppThemeMode { system, light, dark, autoSolar }

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  static const _latKey = 'solar_lat';
  static const _lngKey = 'solar_lng';

  AppThemeMode _mode = AppThemeMode.autoSolar;
  DateTime? _sunrise;
  DateTime? _sunset;
  double _lat = 31.8980;
  double _lng = 35.2042;
  Timer? _timer;

  AppThemeMode get mode => _mode;
  DateTime? get sunrise => _sunrise;
  DateTime? get sunset => _sunset;

  /// Resolved ThemeMode for MaterialApp.
  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.light: return ThemeMode.light;
      case AppThemeMode.dark: return ThemeMode.dark;
      case AppThemeMode.system: return ThemeMode.system;
      case AppThemeMode.autoSolar:
        if (_sunrise == null || _sunset == null) return ThemeMode.system;
        final now = DateTime.now();
        return (now.isBefore(_sunrise!) || now.isAfter(_sunset!))
            ? ThemeMode.dark
            : ThemeMode.light;
    }
  }

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key) ?? 'autoSolar';
    _mode = AppThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => AppThemeMode.autoSolar,
    );
    _lat = prefs.getDouble(_latKey) ?? _lat;
    _lng = prefs.getDouble(_lngKey) ?? _lng;
    _recalculate();
    _startTimer();
    notifyListeners();
  }

  void _recalculate() {
    final times = SolarService.calculate(lat: _lat, lng: _lng);
    _sunrise = times.sunrise;
    _sunset = times.sunset;
  }

  void _startTimer() {
    _timer?.cancel();
    // Check every minute for theme transition
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_mode == AppThemeMode.autoSolar) notifyListeners();
    });
  }

  /// Update location for solar calculation (called from GovernorateProvider).
  void updateLocation(double lat, double lng) {
    if ((_lat - lat).abs() > 0.1 || (_lng - lng).abs() > 0.1) {
      _lat = lat;
      _lng = lng;
      _recalculate();
      _persist();
      if (_mode == AppThemeMode.autoSolar) notifyListeners();
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode.name);
    await prefs.setDouble(_latKey, _lat);
    await prefs.setDouble(_lngKey, _lng);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
