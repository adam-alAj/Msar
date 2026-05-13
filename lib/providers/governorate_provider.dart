import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/governorate.dart';
import '../services/location_permission_service.dart';

class GovernorateProvider extends ChangeNotifier {
  static const _prefKey = 'last_governorate_id';
  static const _boundaryThresholdMinutes = 10;

  final LocationPermissionService _locationService = LocationPermissionService();

  Governorate? _current;
  LatLng? _userPosition;
  bool _isDetecting = false;
  bool _userOverridden = false;

  // Boundary crossing state
  Governorate? _pendingGovernorate;
  DateTime? _pendingEnteredAt;

  Governorate? get current => _current;
  LatLng? get userPosition => _userPosition;
  bool get isDetecting => _isDetecting;
  String? get currentRegionAr => _current?.nameAr;

  StreamSubscription<Position>? _positionSub;

  /// Initialize: try GPS, fallback to prefs, fallback to Ramallah.
  Future<void> init() async {
    _isDetecting = true;
    notifyListeners();

    final status = await _locationService.checkStatus();
    if (status == LocationResult.granted) {
      try {
        final pos = await _locationService.getPosition();
        _userPosition = LatLng(pos.latitude, pos.longitude);
        _current = Governorate.fromCoordinates(pos.latitude, pos.longitude);
        if (_current != null) await _persist(_current!.id);
        _startListening();
      } catch (_) {
        await _loadFromPrefs();
      }
    } else {
      await _loadFromPrefs();
    }

    _isDetecting = false;
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKey);
    _current = id != null
        ? Governorate.all.where((g) => g.id == id).firstOrNull
        : _defaultGovernorate;
    _current ??= _defaultGovernorate;
  }

  Governorate get _defaultGovernorate => Governorate.all.first; // Ramallah

  Future<void> _persist(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, id);
  }

  /// User manually selects a region (or null for all).
  void setManual(String? regionNameAr) {
    if (regionNameAr == null) {
      _current = null;
      _userOverridden = true;
    } else {
      _current = Governorate.all.where((g) => g.nameAr == regionNameAr).firstOrNull;
      _userOverridden = true;
    }
    notifyListeners();
  }

  /// Reset to auto-detected.
  void resetToAuto() {
    _userOverridden = false;
    if (_userPosition != null) {
      _current = Governorate.fromCoordinates(
        _userPosition!.latitude, _userPosition!.longitude,
      );
    }
    notifyListeners();
  }

  void _startListening() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 1000, // 1km movement threshold
      ),
    ).listen(_onPositionUpdate);
  }

  void _onPositionUpdate(Position pos) {
    _userPosition = LatLng(pos.latitude, pos.longitude);
    if (_userOverridden) { notifyListeners(); return; }

    final detected = Governorate.fromCoordinates(pos.latitude, pos.longitude);
    if (detected == null || detected.id == _current?.id) {
      _pendingGovernorate = null;
      _pendingEnteredAt = null;
      notifyListeners();
      return;
    }

    // Boundary crossing: track time in new governorate
    if (_pendingGovernorate?.id != detected.id) {
      _pendingGovernorate = detected;
      _pendingEnteredAt = DateTime.now();
    } else if (_pendingEnteredAt != null) {
      final elapsed = DateTime.now().difference(_pendingEnteredAt!).inMinutes;
      if (elapsed >= _boundaryThresholdMinutes) {
        _pendingGovernorate = null;
        _pendingEnteredAt = null;
        _current = detected;
        _persist(detected.id);
      }
    }
    notifyListeners();
  }

  /// Check if there's a pending boundary crossing prompt.
  Governorate? get pendingBoundaryCrossing => _pendingGovernorate;

  /// Accept the boundary crossing suggestion.
  void acceptBoundaryCrossing() {
    if (_pendingGovernorate != null) {
      _current = _pendingGovernorate;
      _persist(_current!.id);
      _pendingGovernorate = null;
      _pendingEnteredAt = null;
      _userOverridden = false;
      notifyListeners();
    }
  }

  /// Dismiss the boundary crossing suggestion.
  void dismissBoundaryCrossing() {
    _pendingGovernorate = null;
    _pendingEnteredAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
