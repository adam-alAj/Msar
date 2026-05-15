import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._();
  factory FavoritesService() => _instance;
  FavoritesService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final ValueNotifier<Set<String>> favorites = ValueNotifier<Set<String>>({});
  StreamSubscription<QuerySnapshot>? _sub;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _col =>
      _uid != null ? _firestore.collection('users').doc(_uid).collection('favorites') : null;

  /// Start listening to favorites changes.
  void listen() {
    _sub?.cancel();
    if (_col == null) return;
    _sub = _col!.snapshots().listen((snap) {
      favorites.value = snap.docs.map((d) => d.id).toSet();
    });
  }

  void dispose() {
    _sub?.cancel();
  }

  bool isFavorite(String checkpointId) => favorites.value.contains(checkpointId);

  Future<void> toggle(String checkpointId) async {
    if (_col == null) return;
    // Optimistic local update
    final current = Set<String>.from(favorites.value);
    if (current.contains(checkpointId)) {
      current.remove(checkpointId);
      favorites.value = current;
      await _col!.doc(checkpointId).delete();
    } else {
      current.add(checkpointId);
      favorites.value = current;
      await _col!.doc(checkpointId).set({'addedAt': FieldValue.serverTimestamp()});
    }
  }
}
