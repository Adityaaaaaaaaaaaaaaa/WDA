// lib/model/task_model.dart
class TaskModel {
  final String taskId;
  final String userId;
  final List<String> wasteTypes;
  final String size;
  final String urgency;
  final DateTime? pickupDateTime;
  final String address;
  final String notes;

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
  final String taskType; // pickup, map_report, hazardous, etc.

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

  TaskModel({
    required this.taskId,
    required this.userId,
    required this.wasteTypes,
    required this.size,
    required this.urgency,
    required this.pickupDateTime,
    required this.address,
    required this.notes,
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

  factory TaskModel.fromMap(Map<String, dynamic> data) {
    return TaskModel(
      taskId: data['taskId'] ?? '',
      userId: data['userId'] ?? '',
      wasteTypes: List<String>.from(data['wasteTypes'] ?? []),
      size: data['size'] ?? '',
      urgency: data['urgency'] ?? '',
      pickupDateTime: data['pickupDateTime'] != null
          ? DateTime.tryParse(data['pickupDateTime'])
          : null,
      address: data['address'] ?? '',
      notes: data['notes'] ?? '',

      // points
      taskPoints: data['taskPoints'] ?? 0,
      creationPoints: data['creationPoints'] ?? 0,
      completionPoints: data['completionPoints'] ?? 0,
      awardedCompletion: data['awardedCompletion'] ?? false,

      // driver
      driverAssigned: data['driverAssigned'] ?? false,
      driverId: data['driverId'],   // nullable
      driverName: data['driverName'], // nullable
      driverSeen: data['driverSeen'] ?? false,

      // lifecycle
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.tryParse(data['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      source: data['source'] ?? "user_request",
      taskType: data['taskType'] ?? "pickup",

      // qr
      qrCodeData: data['qrCodeData'] ?? '',
      qrCodeUsed: data['qrCodeUsed'] ?? false,

      // status
      status: data['status'] ?? "pending",
      progressStages: Map<String, dynamic>.from(data['progressStages'] ?? {}),
      lastProgressStage: data['lastProgressStage'] ?? "pending",

      // flags
      userDeleted: data['userDeleted'] ?? false,
      cancelledByUser: data['cancelledByUser'] ?? false,
      cancelledBySystem: data['cancelledBySystem'] ?? false,
    );  
  }
}
