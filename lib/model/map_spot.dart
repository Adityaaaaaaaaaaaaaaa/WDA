class MapSpot {
  final String id;
  final List<String> types;   // CHANGED
  final String address;       // NEW
  final String description;
  final double lat;
  final double lng;
  final String createdBy;
  final String? createdByName;
  final int? approxQty;       // NEW
  final String? accessNotes;  // NEW
  final bool cleaned;
  final DateTime? createdAt;

  MapSpot({
    required this.id,
    required this.types,
    required this.address,
    required this.description,
    required this.lat,
    required this.lng,
    required this.createdBy,
    this.createdByName,
    this.approxQty,
    this.accessNotes,
    this.cleaned = false,
    this.createdAt,
  });

  factory MapSpot.fromDoc(String id, Map<String, dynamic> m) => MapSpot(
    id: id,
    types: (m['types'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
    address: (m['address'] ?? '') as String,
    description: (m['description'] ?? '') as String,
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    createdBy: (m['createdBy'] ?? '') as String,
    createdByName: m['createdByName'] as String?,
    approxQty: (m['approxQty'] as num?)?.toInt(),
    accessNotes: m['accessNotes'] as String?,
    cleaned: (m['cleaned'] ?? false) as bool,
    createdAt: (m['createdAt'] as dynamic)?.toDate(),
  );
}
