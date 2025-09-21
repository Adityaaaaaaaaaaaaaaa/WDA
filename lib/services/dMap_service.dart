import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/map_spot.dart';
import '../utils/geohash.dart'; // <- same helper you already use in MapSpotsService

/// Driver-focused wrapper around the same `map_spots` collection.
/// Reuses MapSpot model. Driver cannot create spots; can only view + mark cleaned.
class DriverMapService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('map_spots');

  /// Stream spots around [lat,lng] within [radiusKm].
  /// Uses geohash prefix fan-out (center + 8 neighbors) and merges results.
  Stream<List<MapSpot>> spotsAround({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) {
    // pick geohash precision similarly to user service
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
          .map((q) => q.docs.map((d) => MapSpot.fromDoc(d)).toList());
    }).toList();

    return _zip(streams).map((lists) {
      final merged = <String, MapSpot>{};
      for (final l in lists) {
        for (final s in l) {
          if (_distanceKm(lat, lng, s.lat, s.lng) <= radiusKm) {
            merged[s.id] = s;
          }
        }
      }
      return merged.values.toList();
    });
  }

  /// Driver marks a spot as cleaned. We update then remove only this doc.
  Future<void> markCleaned(String id) async {
    await _col.doc(id).update({
      'cleaned': true,
      'cleanedAt': FieldValue.serverTimestamp(),
    });
    // client-side cleanup; server-side TTL would be ideal
    Future.delayed(const Duration(seconds: 10), () async {
      try {
        await _col.doc(id).delete();
      } catch (_) {}
    });
  }

  // --- helpers (same math as user service) ---
  double _deg2rad(double d) => d * (pi / 180.0);

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Zip multiple `Stream<List<T>>` into a single `Stream<List<List<T>>>`.
  /// This mirrors the implementation you already have in MapSpotsService.
  Stream<List<List<T>>> _zip<T>(List<Stream<List<T>>> inputs) async* {
    final buffers = List<List<T>>.generate(inputs.length, (_) => const []);
    final have = List<bool>.filled(inputs.length, false);
    final controller = StreamController<List<List<T>>>();
    final subs = <StreamSubscription>[];

    for (var i = 0; i < inputs.length; i++) {
      subs.add(inputs[i].listen((list) {
        buffers[i] = list;
        have[i] = true;
        if (have.every((v) => v)) {
          controller.add(buffers.map((e) => List<T>.from(e)).toList());
        }
      }, onError: controller.addError));
    }

    // forward zipped stream
    yield* controller.stream;

    // cleanup when consumer cancels
    for (final s in subs) {
      await s.cancel();
    }
  }
}
