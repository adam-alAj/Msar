// constants.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'app_theme.dart';

class AppConstants {
  /// Theme-aware status color — use this in widgets instead of raw int colors.
  static Color statusColorFor(BuildContext context, String status) {
    return AppTheme.statusColor(status, Theme.of(context).brightness);
  }

  // West Bank approximate center
  static const LatLng defaultLocation = LatLng(31.9469, 35.2736);
  static const double defaultZoom = 10.0;
  
  // Voting radius in kilometers - REMOVED restriction
  static const double votingRadiusKm = 999.0; // Large value to never restrict
  
  // Time window for vote aggregation (minutes)
  static const int voteTimeWindowMinutes = 60; // Changed to 60 minutes for better testing
  
  // Firebase collections
  static const String checkpointsCollection = 'checkpoints';
  static const String votesCollection = 'votes';
  static const String usersCollection = 'users';
  
  // Status colors
  static const int openColor = 0xFF4CAF50;    // Green
  static const int crowdedColor = 0xFFFFA726; // Orange  
  static const int closedColor = 0xFFE53935;  // Red
  
  // Status priorities for tie-breaking: CROWDED > CLOSED > OPEN
  static const Map<String, int> statusPriority = {
    'CROWDED': 3,
    'CLOSED': 2,
    'OPEN': 1,
  };
  
  // Regions
  static const List<String> regions = [
   
    'رام الله',
    'الخليل',
    'نابلس',
    'بيت لحم',
    'أريحا',
    'جنين',
    'طولكرم',
    'قلقيلية',
    'سلفيت',
    'طوباس',
  ];
  
  // Region mapping for display
  static const Map<String, String> regionArabicNames = {
    'all': 'جميع المناطق',
    'ramallah': 'رام الله',
    'hebron': 'الخليل',
    'nablus': 'نابلس',
    'bethlehem': 'بيت لحم',
    'jericho': 'أريحا',
    'jenin': 'جنين',
    'tulkarm': 'طولكرم',
    'qalqilya': 'قلقيلية',
    'salfit': 'سلفيت',
    'tubas': 'طوباس',
  };
}