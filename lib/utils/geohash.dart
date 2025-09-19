/// Minimal geohash encoder + neighbors we need for prefix queries.
/// (Not full spec; good enough for proximity buckets around a point.)
class MiniGeohash {
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encode(double lat, double lon, {int precision = 7}) {
    var minLat = -90.0, maxLat = 90.0;
    var minLon = -180.0, maxLon = 180.0;
    var hash = StringBuffer();
    var isLon = true;
    var bit = 0, ch = 0;

    while (hash.length < precision) {
      if (isLon) {
        final mid = (minLon + maxLon) / 2;
        if (lon > mid) {
          ch = (ch << 1) + 1;
          minLon = mid;
        } else {
          ch = (ch << 1) + 0;
          maxLon = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (lat > mid) {
          ch = (ch << 1) + 1;
          minLat = mid;
        } else {
          ch = (ch << 1) + 0;
          maxLat = mid;
        }
      }
      isLon = !isLon;
      if (++bit == 5) {
        hash.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return hash.toString();
  }

  static List<String> neighbors(String hash) {
    // Super-simple 8-neighbor set by trimming one char and brute appending.
    // Good enough for small radii w/ client filtering.
    if (hash.isEmpty) return const [];
    final prefix = hash.substring(0, hash.length - 1);
    return [
      for (final c in _base32.split('')) prefix + c,
    ];
  }
}
