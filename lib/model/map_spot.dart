import 'package:cloud_firestore/cloud_firestore.dart';

class MapSpot {
  final String id;
  final double lat;
  final double lng;
  final List<String> types; // list
  final String address;
  final String description;
  final String? createdBy;
  final String? createdByName;
  final int? approxQty;
  final String? accessNotes;
  final DateTime? createdAt;

  MapSpot({
    required this.id,
    required this.lat,
    required this.lng,
    required this.types,
    required this.address,
    required this.description,
    this.createdBy,
    this.createdByName,
    this.approxQty,
    this.accessNotes,
    this.createdAt,
  });

  factory MapSpot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final rawTypes = d['types'];
    final listTypes = (rawTypes is List)
        ? rawTypes.map((e) => e.toString()).toList()
        : (d['type'] != null ? <String>[d['type'].toString()] : <String>[]);

    return MapSpot(
      id: doc.id,
      lat: (d['lat'] as num).toDouble(),
      lng: (d['lng'] as num).toDouble(),
      types: listTypes,
      address: (d['address'] ?? '') as String,
      description: (d['description'] ?? '') as String,
      createdBy: d['createdBy'] as String?,
      createdByName: d['createdByName'] as String?,
      approxQty: (d['approxQty'] as num?)?.toInt(),
      accessNotes: d['accessNotes'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
