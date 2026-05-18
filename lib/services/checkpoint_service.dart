import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/checkpoint.dart';
import '../models/vote.dart';
import '../models/checkpoint_status.dart';
import '../utils/constants.dart';

class CheckpointService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Checkpoints ────────────────────────────────────────────────────────────

  Stream<List<Checkpoint>> getCheckpoints() {
    return _firestore
        .collection(AppConstants.checkpointsCollection)
        .snapshots()
        .map((s) => s.docs.map(Checkpoint.fromFirestore).toList());
  }

  Stream<List<Checkpoint>> getCheckpointsByRegion(String region) {
    return _firestore
        .collection(AppConstants.checkpointsCollection)
        .where('region', isEqualTo: region)
        .snapshots()
        .map((s) => s.docs.map(Checkpoint.fromFirestore).toList());
  }

  Future<void> addCheckpoint(Checkpoint checkpoint) async {
    await _firestore
        .collection(AppConstants.checkpointsCollection)
        .add(checkpoint.toFirestore());
  }

  Future<void> updateCheckpoint(Checkpoint checkpoint) async {
    await _firestore
        .collection(AppConstants.checkpointsCollection)
        .doc(checkpoint.id)
        .update(checkpoint.toFirestore());
  }

  Future<void> deleteCheckpoint(String checkpointId) async {
    await _firestore
        .collection(AppConstants.checkpointsCollection)
        .doc(checkpointId)
        .delete();
  }

  // ─── Votes ───────────────────────────────────────────────────────────────────

  Future<void> submitVote(Vote vote) async {
    await _firestore
        .collection(AppConstants.votesCollection)
        .add(vote.toFirestore());
    debugPrint('✅ Vote submitted: ${vote.direction} → ${vote.status}');
  }

  // ─── FIXED: GetAllCheckpointStatuses - Using correct query ───────────────
  
  Future<Map<String, CheckpointStatus>> getAllCheckpointStatuses(
      List<String> checkpointIds, {GetOptions? options}) async {
    if (checkpointIds.isEmpty) return {};

    final cutoff = DateTime.now().subtract(
      Duration(minutes: AppConstants.voteTimeWindowMinutes),
    );

    // FIX: Query without timestamp filter first to avoid index issues
    final snapshot = await _firestore
        .collection(AppConstants.votesCollection)
        .get(options ?? const GetOptions());
    
    // Filter in memory instead of using where clause
    final allVotes = snapshot.docs
        .map(Vote.fromFirestore)
        .where((v) => v.timestamp.isAfter(cutoff))
        .toList();
    
    debugPrint('🗳  Loaded ${allVotes.length} votes (last ${AppConstants.voteTimeWindowMinutes} min)');

    // Group by checkpointId
    final Map<String, List<Vote>> byCheckpoint = {};
    for (final v in allVotes) {
      byCheckpoint.putIfAbsent(v.checkpointId, () => []).add(v);
    }

    // Fetch checkpoint docs for admin overrides
    final checkpointDocs = await _firestore
        .collection(AppConstants.checkpointsCollection)
        .get(options ?? const GetOptions());
    final Map<String, Map<String, dynamic>> overrides = {};
    for (final doc in checkpointDocs.docs) {
      final data = doc.data();
      if (data.containsKey('entranceStatus') || data.containsKey('exitStatus')) {
        overrides[doc.id] = data;
      }
    }

    // Build status for every requested checkpoint
    final Map<String, CheckpointStatus> result = {};
    for (final id in checkpointIds) {
      final votes = byCheckpoint[id] ?? [];
      final override = overrides[id];
      result[id] = CheckpointStatus(
        checkpointId: id,
        entrance: override != null && override['entranceStatus'] != null
            ? DirectionStatus(status: override['entranceStatus'], percentage: 100, lastUpdated: DateTime.now(), totalVotes: 0)
            : _calculateDirectionStatus(votes, 'ENTRANCE'),
        exit: override != null && override['exitStatus'] != null
            ? DirectionStatus(status: override['exitStatus'], percentage: 100, lastUpdated: DateTime.now(), totalVotes: 0)
            : _calculateDirectionStatus(votes, 'EXIT'),
      );
    }
    return result;
  }

  // ─── FIXED: Single checkpoint status for detail screen ────────────────────

  Future<CheckpointStatus> getCheckpointStatus(String checkpointId) async {
    final cutoff = DateTime.now().subtract(
      Duration(minutes: AppConstants.voteTimeWindowMinutes),
    );

    // Check for admin override
    final cpDoc = await _firestore
        .collection(AppConstants.checkpointsCollection)
        .doc(checkpointId)
        .get();
    final cpData = cpDoc.data();

    // Get all votes and filter in memory
    final snapshot = await _firestore
        .collection(AppConstants.votesCollection)
        .get();

    final votes = snapshot.docs
        .map(Vote.fromFirestore)
        .where((v) => v.checkpointId == checkpointId && v.timestamp.isAfter(cutoff))
        .toList();
        
    debugPrint('🗳  ${votes.length} recent votes for checkpoint $checkpointId');

    return CheckpointStatus(
      checkpointId: checkpointId,
      entrance: cpData != null && cpData['entranceStatus'] != null
          ? DirectionStatus(status: cpData['entranceStatus'], percentage: 100, lastUpdated: DateTime.now(), totalVotes: 0)
          : _calculateDirectionStatus(votes, 'ENTRANCE'),
      exit: cpData != null && cpData['exitStatus'] != null
          ? DirectionStatus(status: cpData['exitStatus'], percentage: 100, lastUpdated: DateTime.now(), totalVotes: 0)
          : _calculateDirectionStatus(votes, 'EXIT'),
    );
  }

  // ─── FIXED: Real-time stream for detail screen ──────────────────────────

  Stream<CheckpointStatus> watchCheckpointStatus(String checkpointId) {
    // Combine checkpoint doc (for overrides) with votes
    final cpStream = _firestore
        .collection(AppConstants.checkpointsCollection)
        .doc(checkpointId)
        .snapshots();

    final votesStream = _firestore
        .collection(AppConstants.votesCollection)
        .snapshots();

    return cpStream.asyncExpand((cpSnapshot) {
      return votesStream.map((votesSnapshot) {
        final cutoff = DateTime.now().subtract(
          Duration(minutes: AppConstants.voteTimeWindowMinutes),
        );
        final cpData = cpSnapshot.data();
        final votes = votesSnapshot.docs
            .map(Vote.fromFirestore)
            .where((v) => v.checkpointId == checkpointId && v.timestamp.isAfter(cutoff))
            .toList();

        return CheckpointStatus(
          checkpointId: checkpointId,
          entrance: cpData != null && cpData['entranceStatus'] != null
              ? DirectionStatus(status: cpData['entranceStatus'], percentage: 100, lastUpdated: DateTime.now(), totalVotes: 0)
              : _calculateDirectionStatus(votes, 'ENTRANCE'),
          exit: cpData != null && cpData['exitStatus'] != null
              ? DirectionStatus(status: cpData['exitStatus'], percentage: 100, lastUpdated: DateTime.now(), totalVotes: 0)
              : _calculateDirectionStatus(votes, 'EXIT'),
        );
      });
    });
  }

  // ─── Admin override ──────────────────────────────────────────────────────────

  Future<void> overrideStatus(
      String checkpointId, String direction, String status) async {
    await _firestore
        .collection(AppConstants.checkpointsCollection)
        .doc(checkpointId)
        .update({
      '${direction.toLowerCase()}Status': status,
      '${direction.toLowerCase()}OverrideAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  DirectionStatus _calculateDirectionStatus(
      List<Vote> votes, String direction) {
    final dirVotes =
        votes.where((v) => v.direction == direction).toList();

    if (dirVotes.isEmpty) {
      return DirectionStatus(
        status: 'OPEN',
        percentage: 0,
        lastUpdated: DateTime.now(),
        totalVotes: 0,
      );
    }

    final Map<String, int> counts = {};
    for (final v in dirVotes) {
      counts[v.status] = (counts[v.status] ?? 0) + 1;
    }

    final total = dirVotes.length;
    String winner = 'OPEN';
    double maxPct = 0;

    counts.forEach((status, count) {
      final pct = (count / total) * 100;
      if (pct > maxPct ||
          (pct == maxPct &&
              (AppConstants.statusPriority[status] ?? 0) >
                  (AppConstants.statusPriority[winner] ?? 0))) {
        maxPct = pct;
        winner = status;
      }
    });

    final lastUpdated = dirVotes
        .map((v) => v.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return DirectionStatus(
      status: winner,
      percentage: maxPct,
      lastUpdated: lastUpdated,
      totalVotes: total,
    );
  }
}