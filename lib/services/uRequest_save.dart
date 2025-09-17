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
    required int ecoPoints, // full task points
    String source = "user_request",
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final String taskId = "${user.uid}_${_uuid.v4()}";
      final DateTime now = DateTime.now();

      // breakdown
      final int creationPoints = (ecoPoints / 2).floor();
      final int completionPoints = ecoPoints - creationPoints;

      final taskData = {
        "taskId": taskId,
        "userId": user.uid,
        "wasteTypes": wasteTypes.toList(),
        "size": size,
        "urgency": urgency,
        "pickupDateTime": pickupDateTime != null ? Timestamp.fromDate(pickupDateTime) : null,
        "address": address,
        "notes": notes,

        // points system
        "taskPoints": ecoPoints,
        "creationPoints": creationPoints,
        "completionPoints": completionPoints,
        "awardedCompletion": false,

        "driverAssigned": false,
        "driverId": null,
        "driverName": null,
        "driverSeen": false,

        // lifecycle
        "createdAt": Timestamp.fromDate(now),
        "updatedAt": Timestamp.fromDate(now),
        "source": source,
        "taskType": "pickup",

        // qr
        "qrCodeData": "task:$taskId:user:${user.uid}",
        "qrCodeUsed": false,

        // status + progress
        "status": "pending",
        "progressStages": {
          "accepted": false,
          "enRoute": false,
          "atLocation": false,
          "collected": false,
          "atLandfill": false,
          "completed": false,
        },
        "lastProgressStage": "pending",

        // flags
        "userDeleted": false,
        "cancelledByUser": false,
        "cancelledBySystem": false,
      };

      // save globally
      await _db.collection("tasks").doc(taskId).set(taskData);

      // save inside user's history (with minimal fields)
      await _db
          .collection("users")
          .doc(user.uid)
          .collection("tasks")
          .doc(taskId)
          .set({
        "taskId": taskId,
        "taskPoints": ecoPoints,
        "creationPoints": creationPoints,
        "completionPoints": completionPoints,
        "awardedCompletion": false,
        "status": "pending",
        "createdAt": Timestamp.fromDate(now),
      });

      // immediately add half points to user doc
      await _db.collection("users").doc(user.uid).set({
        "ecoPoints": FieldValue.increment(creationPoints),
      }, SetOptions(merge: true));

      return taskId;
    } catch (e) {
      rethrow;
    }
  }

  /// Award remaining completion points when task is marked completed
  Future<void> awardCompletionPoints(String taskId, String userId) async {
    final taskRef = _db.collection("tasks").doc(taskId);
    final taskSnap = await taskRef.get();
    if (!taskSnap.exists) throw Exception("Task not found");

    final data = taskSnap.data()!;
    if (data["awardedCompletion"] == true) return; // already awarded

    final int completionPoints = data["completionPoints"] ?? 0;

    // update task
    await taskRef.update({
      "awardedCompletion": true,
      "status": "completed",
      "progressStages.completed": true,
      "updatedAt": Timestamp.fromDate(DateTime.now()),
    });

    // update in user’s history subcollection
    await _db
        .collection("users")
        .doc(userId)
        .collection("tasks")
        .doc(taskId)
        .update({
      "awardedCompletion": true,
      "status": "completed",
    });

    // increment eco points for user
    await _db.collection("users").doc(userId).set({
      "ecoPoints": FieldValue.increment(completionPoints),
    }, SetOptions(merge: true));
  }
}
