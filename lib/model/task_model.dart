// lib/model/task_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String taskId;
  final String userId;
  final List<String> wasteTypes;
  final String size;
  final String urgency;
  final DateTime? pickupDateTime;
  final String address;
  final String notes;

  final double? lat;
  final double? lng;

  // points system
  final int taskPoints;
  final int creationPoints;
  final int completionPoints;
  final bool awardedCompletion;

  // driver assignment
  final bool driverAssigned;
  final String? driverId;
  final String? driverName;
  final bool driverSeen;

  // task lifecycle
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source;
  final String taskType;

  // qr tracking
  final String qrCodeData;
  final bool qrCodeUsed;

  // status flags
  final String status;
  final Map<String, dynamic> progressStages;
  final String lastProgressStage;

  // user / system flags
  final bool userDeleted;
  final bool cancelledByUser;
  final bool cancelledBySystem;

  const TaskModel({
    required this.taskId,
    required this.userId,
    required this.wasteTypes,
    required this.size,
    required this.urgency,
    required this.pickupDateTime,
    required this.address,
    required this.notes,
    this.lat,
    this.lng,
    required this.taskPoints,
    required this.creationPoints,
    required this.completionPoints,
    required this.awardedCompletion,
    required this.driverAssigned,
    required this.driverId,
    required this.driverName,
    required this.driverSeen,
    required this.createdAt,
    required this.updatedAt,
    required this.source,
    required this.taskType,
    required this.qrCodeData,
    required this.qrCodeUsed,
    required this.status,
    required this.progressStages,
    required this.lastProgressStage,
    this.userDeleted = false,
    this.cancelledByUser = false,
    this.cancelledBySystem = false,
  });

  /// Helper: pretty date/time
  String get pickupWhenText {
    final dt = pickupDateTime;
    if (dt == null) return "Flexible";
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "${dt.day}/${dt.month} • $hh:$mm";
  }

  factory TaskModel.fromMap(Map<String, dynamic> data) {
    // tolerate numbers coming as int/double
    double? _toDYN(dynamic v) => v == null ? null : (v as num).toDouble();

    return TaskModel(
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      wasteTypes: List<String>.from(data['wasteTypes'] ?? []),
      size: data['size'] ?? '',
      urgency: data['urgency'] ?? '',
      address: data['address'] ?? '',
      notes: data['notes'] ?? '',

      // NEW
      lat: _toDYN(data['lat']) ?? _toDYN((data['location'] ?? {})['lat']),
      lng: _toDYN(data['lng']) ?? _toDYN((data['location'] ?? {})['lng']),

      taskPoints: data['taskPoints'] ?? 0,
      creationPoints: data['creationPoints'] ?? 0,
      completionPoints: data['completionPoints'] ?? 0,
      awardedCompletion: data['awardedCompletion'] ?? false,

      driverAssigned: data['driverAssigned'] ?? false,
      driverId: data['driverId'],
      driverName: data['driverName'],
      driverSeen: data['driverSeen'] ?? false,

      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      pickupDateTime: data['pickupDateTime'] is Timestamp
          ? (data['pickupDateTime'] as Timestamp).toDate()
          : null,
      source: data['source'] ?? "user_request",
      taskType: data['taskType'] ?? "pickup",

      qrCodeData: data['qrCodeData'] ?? '',
      qrCodeUsed: data['qrCodeUsed'] ?? false,

      status: data['status'] ?? "pending",
      progressStages: Map<String, dynamic>.from(data['progressStages'] ?? {}),
      lastProgressStage: data['lastProgressStage'] ?? "pending",

      userDeleted: data['userDeleted'] ?? false,
      cancelledByUser: data['cancelledByUser'] ?? false,
      cancelledBySystem: data['cancelledBySystem'] ?? false,
    );
  }
}
