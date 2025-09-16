import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class URequestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  /// Save a new task to Firestore
  Future<String> createTask({
    required Set<String> wasteTypes,
    required String size,
    required String urgency,
    required DateTime? pickupDateTime,
    required String address,
    required String notes,
    required int ecoPoints,
    String source = "user_request",
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Make taskId include userId for easier querying later
      final String taskId = "${user.uid}_${_uuid.v4()}";
      final DateTime now = DateTime.now();

      // QR string (driver will scan this)
      final String qrCodeData = "task:$taskId:user:${user.uid}";

      final taskData = {
        "taskId": taskId,
        "userId": user.uid,
        "wasteTypes": wasteTypes.toList(),
        "size": size,
        "urgency": urgency,
        "pickupDateTime": pickupDateTime?.toIso8601String(),
        "address": address,
        "notes": notes,
        "ecoPoints": ecoPoints,
        "driverAssigned": false,
        "driverId": null,
        "createdAt": now.toIso8601String(),
        "updatedAt": now.toIso8601String(),
        "source": source,

        // QR
        "qrCodeData": qrCodeData,
        "qrCodeUsed": false,

        // Status + Progress
        "status": "pending",
        "progressStages": {
          "accepted": false,
          "enRoute": false,
          "atLocation": false,
          "collected": false,
          "atLandfill": false,
          "completed": false,
        },
      };

      // Save globally
      await _db.collection("tasks").doc(taskId).set(taskData);

      // Save inside user's history
      await _db
          .collection("users")
          .doc(user.uid)
          .collection("tasks")
          .doc(taskId)
          .set({
        "taskId": taskId,
        "ecoPoints": ecoPoints,
        "status": "pending",
        "createdAt": now.toIso8601String(),
      });

      return taskId;
    } catch (e) {
      rethrow;
    }
  }
}
