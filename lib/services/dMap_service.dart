import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/map_spot.dart';
import '../utils/geohash.dart'; 

class DriverMapService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('map_spots');

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

  Future<void> markCleaned(String id) async {
    await _col.doc(id).update({
      'cleaned': true,
      'cleanedAt': FieldValue.serverTimestamp(),
    });
    Future.delayed(const Duration(seconds: 10), () async {
      try {
        await _col.doc(id).delete();
      } catch (_) {}
    });
  }

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

    yield* controller.stream;

    for (final s in subs) {
      await s.cancel();
    }
  }
}
