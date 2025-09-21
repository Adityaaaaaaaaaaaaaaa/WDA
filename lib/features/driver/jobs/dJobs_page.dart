// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../model/task_model.dart';
import '../../../services/dTasks_service.dart';
import '../../widgets/AppBar.dart';
import '../../widgets/dNavBar.dart';
import 'widgets/dJobs_widgets.dart';

class DJobsPage extends StatefulWidget {
  const DJobsPage({super.key});

  @override
  State<DJobsPage> createState() => _DJobsPageState();
}

class _DJobsPageState extends State<DJobsPage> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
  final _svc = DriverTasksService();

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: const UAppBar(title: "View Jobs"),
      bottomNavigationBar: const DNavBar(currentIndex: 1),
      body: Column(
        children: [
          SizedBox(height: 10.h),
          BlueSegmentedTab(controller: _tab),
          SizedBox(height: 12.h),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _MyTasksTab(svc: _svc),
                _AvailableTab(svc: _svc),
                _CompletedTab(svc: _svc),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------- Tabs

class _AvailableTab extends StatelessWidget {
  final DriverTasksService svc;
  const _AvailableTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.streamAvailable(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No available jobs right now.",
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
            ),
          );
        }

        final tasks = snap.data!.docs
            .map((d) => TaskModel.fromMap(d.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, i) => TaskCardAvailable(task: tasks[i], svc: svc),
        );
      },
    );
  }
}

class _MyTasksTab extends StatelessWidget {
  final DriverTasksService svc;
  const _MyTasksTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.streamMyTasks(), // in_progress + scheduled
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "You don't have active jobs yet.",
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
            ),
          );
        }

        // Build entries (task + acceptedAt) so we can sort by acceptedAt
        final entries = snap.data!.docs.map((d) {
          final data = d.data();
          final task = TaskModel.fromMap(data);
          final acceptedAtTs = data['acceptedAt'] as Timestamp?;
          final acceptedAt = acceptedAtTs?.toDate();
          return (task: task, acceptedAt: acceptedAt);
        }).toList();

        // Sort:
        // 1) in_progress first
        // 2) then scheduled by acceptedAt asc (fallback to createdAt asc)
        entries.sort((a, b) {
          final aStatus = a.task.status;
          final bStatus = b.task.status;

          if (aStatus == 'in_progress' && bStatus != 'in_progress') return -1;
          if (bStatus == 'in_progress' && aStatus != 'in_progress') return 1;

          if (aStatus == 'scheduled' && bStatus == 'scheduled') {
            final aKey = a.acceptedAt ?? a.task.createdAt;
            final bKey = b.acceptedAt ?? b.task.createdAt;
            return aKey.compareTo(bKey); // oldest accepted first
          }

          // Fallback: newer updatedAt first
          return b.task.updatedAt.compareTo(a.task.updatedAt);
        });

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
          itemCount: entries.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, i) => TaskCardAvailable(task: entries[i].task, svc: null),
        );
      },
    );
  }
}

class _CompletedTab extends StatelessWidget {
  final DriverTasksService svc;
  const _CompletedTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.streamCompleted(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No completed jobs yet.",
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
            ),
          );
        }

        final tasks = snap.data!.docs
            .map((d) => TaskModel.fromMap(d.data()))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (_, i) => TaskCardAvailable(task: tasks[i], svc: null),
        );
      },
    );
  }
}
