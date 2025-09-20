import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/map_spot.dart';
import '../utils/geohash.dart';

class MapSpotsService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('map_spots');

  Future<void> createSpot({
    required double lat,
    required double lng,
    required List<String> types,       // CHANGED
    required String address,           // NEW
    String? description,
    String? createdByName,
    int? approxQty,                    // NEW
    String? accessNotes,               // NEW
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final geohash = MiniGeohash.encode(lat, lng, precision: 7);

    await _col.add({
      'types': types,                  // list
      'address': address,              // store address string
      'description': description ?? '',
      'createdBy': uid,
      'createdByName': createdByName,
      'lat': lat,
      'lng': lng,
      'approxQty': approxQty,
      'accessNotes': accessNotes,
      'geohash': geohash,
      'cleaned': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSpot(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    final doc = await _col.doc(id).get();
    final data = doc.data();
    if (data == null || data['createdBy'] != uid) {
      throw Exception('Not your spot');
    }
    await _col.doc(id).delete();
  }

  /// Driver (or admin) marks a spot as cleaned.
  /// It switches icon (via `cleaned: true`), then deletes after [delay] seconds.
  Future<void> markCleaned(String id, {Duration delay = const Duration(seconds: 15)}) async {
    await _col.doc(id).update({
      'cleaned': true,
      'cleanedAt': FieldValue.serverTimestamp(),
    });
    // server-side TTL would be ideal; for now, client job:
    Future.delayed(delay, () async {
      try { await _col.doc(id).delete(); } catch (_) {}
    });
  }

  Stream<List<MapSpot>> spotsAround({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) {
    final precision = radiusKm > 20 ? 5 : radiusKm > 5 ? 6 : 7;
    final centerHash = MiniGeohash.encode(lat, lng, precision: precision);
    final prefixes = {centerHash, ...MiniGeohash.neighbors(centerHash)};

    final streams = prefixes.map((p) {
      final start = p;
      final end = '$p\uf8ff';
      return _col
          .orderBy('geohash')
          .startAt([start])
          .endAt([end])
          .snapshots()
          .map((q) => q.docs.map((d) => MapSpot.fromDoc(d.id, d.data())).toList());
    }).toList();

    return _zip(streams).map((lists) {
      final merged = <String, MapSpot>{};
      for (final l in lists) {
        for (final s in l) {
          if (_distanceKm(lat, lng, s.lat, s.lng) <= radiusKm) merged[s.id] = s;
        }
      }
      return merged.values.toList();
    });
  }

  // --- helpers (unchanged) ---
  Stream<List<List<T>>> _zip<T>(List<Stream<List<T>>> inputs) async* {
    final buffers = List<List<T>>.generate(inputs.length, (_) => const []);
    final have = List<bool>.filled(inputs.length, false);
    final controller = StreamController<List<List<T>>>();
    final subs = <StreamSubscription>[];

    for (var i = 0; i < inputs.length; i++) {
      subs.add(inputs[i].listen((list) {
        buffers[i] = list;
        have[i] = true;
        if (have.every((v) => v)) controller.add(buffers.map((e) => List<T>.from(e)).toList());
      }, onError: controller.addError));
    }

    yield* controller.stream;
    for (final s in subs) { await s.cancel(); }
  }

  double _deg2rad(double d) => d * (pi / 180.0);
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
}
