import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/map_spot.dart';

/// Driver-focused wrapper around the same `map_spots` collection.
/// Reuses MapSpot model. Driver cannot create spots; can only view + mark cleaned.
class DriverMapService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('map_spots');

  /// Stream spots around [lat,lng] within [radiusKm].
  Stream<List<MapSpot>> spotsAround({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) {
    // use same geohash-prefix fan-out approach as user service
    final precision = radiusKm > 20 ? 5 : radiusKm > 5 ? 6 : 7;
    String _encode(double la, double lo, {int precision = 7}) {
      const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
      var latRange = [-90.0, 90.0], lonRange = [-180.0, 180.0];
      var hash = '', bits = 0, ch = 0, even = true;
      while (hash.length < precision) {
        if (even) {
          final mid = (lonRange[0] + lonRange[1]) / 2;
          if (lo > mid) { ch |= 1 << (4 - bits); lonRange[0] = mid; } else { lonRange[1] = mid; }
        } else {
          final mid = (latRange[0] + latRange[1]) / 2;
          if (la > mid) { ch |= 1 << (4 - bits); latRange[0] = mid; } else { latRange[1] = mid; }
        }
        even = !even;
        if (bits < 4) { bits++; } else { hash += base32[ch]; bits = 0; ch = 0; }
      }
      return hash;
    }

    Iterable<String> _neighbors(String g) {
      // cheap neighbor set by truncating last char range (overscan via startAt/endAt with \uf8ff)
      return {g};
    }

    final centerHash = _encode(lat, lng, precision: precision);
    final prefixes = {centerHash, ..._neighbors(centerHash)}.toList();

    final streams = prefixes.map((p) {
      final start = p;
      final end = '$p\uf8ff';
      return _col
          .orderBy('geohash')
          .startAt([start])
          .endAt([end])
          .snapshots()
          .map((q) => q.docs.map((d) => MapSpot.fromDoc(d)).toList());
    });

    return StreamZip<List<MapSpot>>(streams).map((lists) {
      final merged = <String, MapSpot>{};
      for (final l in lists) {
        for (final s in l) {
          if (_distanceKm(lat, lng, s.lat, s.lng) <= radiusKm) merged[s.id] = s;
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
    // remove just this pin shortly after (client cleanup; server TTL ideal)
    Future.delayed(const Duration(seconds: 10), () async {
      try { await _col.doc(id).delete(); } catch (_) {}
    });
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

/// Small helper to zip multiple streams (local copy to avoid extra deps).
class StreamZip<T> extends Stream<List<T>> {
  final List<Stream<T>> _streams;
  StreamZip(Iterable<Stream<T>> streams) : _streams = streams.toList();

  @override
  StreamSubscription<List<T>> listen(
    void Function(List<T>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<T>>();
    final values = List<T?>.filled(_streams.length, null, growable: false);
    final have   = List<bool>.filled(_streams.length, false, growable: false);
    final subs   = <StreamSubscription<T>>[];
    var doneCount = 0;

    void emitIfReady() {
      if (have.every((v) => v)) {
        controller.add(values.cast<T>());
      }
    }

    // Start listening to all input streams
    for (var i = 0; i < _streams.length; i++) {
      subs.add(
        _streams[i].listen(
          (v) {
            values[i] = v;
            have[i] = true;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () {
            doneCount++;
            if (doneCount == _streams.length) {
              // all sources finished
              controller.close();
            }
          },
          cancelOnError: cancelOnError,
        ),
      );
    }

    // When the outer subscription is cancelled, cancel all inners
    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };

    // Wire caller’s handlers to the controller’s stream
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
