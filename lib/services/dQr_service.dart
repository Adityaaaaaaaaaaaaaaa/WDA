import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/task_model.dart';
import 'uRequest_save.dart';

class DQrService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Stream<TaskModel?> streamCurrentInProgress() {
    final uid = _uid ?? '__none__';
    return _db
        .collection('tasks')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'in_progress')
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((q) => q.docs.isEmpty ? null : TaskModel.fromMap(q.docs.first.data()));
  }

  Future<void> markPickupScanned(TaskModel task) async {
    final ref = _db.collection('tasks').doc(task.taskId);
    await ref.update({
      'qrCodeUsed': true,
      'progressStages.atLocation': true,
      'lastProgressStage': 'atLocation',
      'status': 'in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
      'pickupScan': {
        'at': FieldValue.serverTimestamp(),
        'by': _uid,
      },
    });
  }

  Future<void> markLandfillScanned(TaskModel task, {String? landfillId}) async {
    final ref = _db.collection('tasks').doc(task.taskId);

    await ref.update({
      'progressStages.atLandfill': true,
      'progressStages.completed': true,
      'lastProgressStage': 'completed',
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
      if (landfillId != null) 'landfillId': landfillId,
      'landfillScan': {
        'at': FieldValue.serverTimestamp(),
        'by': _uid,
        if (landfillId != null) 'landfillId': landfillId,
      },
    });

    await URequestService().awardCompletionPoints(task.taskId, task.userId);
  }
}
