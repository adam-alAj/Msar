import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bridge between Flutter app and native Android widget.
/// Writes nearest checkpoint data to SharedPreferences for the widget to read,
/// and triggers widget refresh via platform channel.
class WidgetBridgeService {
  static const _channel = MethodChannel('com.example.flutter_final_app/widget');
  static const _keyData = 'widget_checkpoints';
  static const _keyLastUpdate = 'widget_last_update';

  /// Write checkpoint data for the widget and trigger native update.
  static Future<void> updateWidgetData(List<Map<String, dynamic>> checkpoints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyData, jsonEncode(checkpoints));
    await prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (_) {
      // Widget may not be placed yet — safe to ignore
    }
  }

  /// Trigger native widget refresh (re-reads SharedPreferences).
  static Future<void> triggerWidgetRefresh() async {
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (_) {}
  }
}
