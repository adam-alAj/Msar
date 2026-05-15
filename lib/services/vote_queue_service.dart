import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vote.dart';
import 'checkpoint_service.dart';

/// Queues votes locally when offline and replays them on reconnect.
class VoteQueueService {
  static const _queueKey = 'offline_vote_queue';
  static final VoteQueueService _instance = VoteQueueService._();
  factory VoteQueueService() => _instance;
  VoteQueueService._();

  final CheckpointService _checkpointService = CheckpointService();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _replaying = false;

  /// Initialize connectivity listener for auto-replay.
  void init() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && !_replaying) replayQueue();
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Enqueue a vote locally.
  Future<void> enqueue(Vote vote) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode(vote.toFirestore()));
    await prefs.setStringList(_queueKey, queue);
    debugPrint('📦 Vote queued offline (${queue.length} pending)');
  }

  /// Number of pending votes.
  Future<int> get pendingCount async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_queueKey) ?? []).length;
  }

  /// Replay all queued votes to Firestore.
  Future<void> replayQueue() async {
    if (_replaying) return;
    _replaying = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? [];
      if (queue.isEmpty) return;

      debugPrint('🔄 Replaying ${queue.length} queued votes...');
      final failed = <String>[];

      for (final json in queue) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          final vote = Vote(
            id: '',
            checkpointId: map['checkpointId'] ?? '',
            userId: map['userId'] ?? '',
            direction: map['direction'] ?? '',
            status: map['status'] ?? '',
            comment: map['comment'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as Map?)?['_seconds'] != null
                  ? (map['timestamp']['_seconds'] as int) * 1000
                  : DateTime.now().millisecondsSinceEpoch,
            ),
            userLatitude: map['userLatitude']?.toDouble(),
            userLongitude: map['userLongitude']?.toDouble(),
          );
          await _checkpointService.submitVote(vote);
        } catch (e) {
          debugPrint('⚠️ Failed to replay vote: $e');
          failed.add(json);
        }
      }

      await prefs.setStringList(_queueKey, failed);
      debugPrint('✅ Queue replay done. ${failed.length} remaining.');
    } finally {
      _replaying = false;
    }
  }
}
