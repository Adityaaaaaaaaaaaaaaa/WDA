class MapSpot {
  final String id;
  final String type;
  final String description;
  final double lat;
  final double lng;
  final String createdBy;
  final String? createdByName;
  final bool cleaned;              // kept for future; user UI ignores it
  final DateTime? createdAt;

  MapSpot({
    required this.id,
    required this.type,
    required this.description,
    required this.lat,
    required this.lng,
    required this.createdBy,
    this.createdByName,
    this.cleaned = false,
    this.createdAt,
  });

  factory MapSpot.fromDoc(String id, Map<String, dynamic> m) => MapSpot(
        id: id,
        type: (m['type'] ?? 'General Waste') as String,
        description: (m['description'] ?? '') as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        createdBy: (m['createdBy'] ?? '') as String,
        createdByName: m['createdByName'] as String?,
        cleaned: (m['cleaned'] ?? false) as bool,
        createdAt: (m['createdAt'] as dynamic)?.toDate(),
      );
}
