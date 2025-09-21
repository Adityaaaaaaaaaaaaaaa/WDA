// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../model/task_model.dart';
import '../../../services/dTasks_service.dart';
import '../../widgets/AppBar.dart';
import '../../widgets/dNavBar.dart';
import 'widgets/dJobs_widgets.dart' hide TaskCardAvailable;
import 'widgets/task_card_available.dart';

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
          return Center(child: Text("No available jobs right now.",
              style: TextStyle(fontSize: 14.sp, color: Colors.black54)));
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
      stream: svc.streamMyTasks(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(child: Text("You don't have active jobs yet.",
              style: TextStyle(fontSize: 14.sp, color: Colors.black54)));
        }

        final tasks = snap.data!.docs
            .map((d) => TaskModel.fromMap(d.data()))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 16.h),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          // svc: null -> Accept button hidden inside card
          itemBuilder: (_, i) => TaskCardAvailable(task: tasks[i], svc: null),
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
          return Center(child: Text("No completed jobs yet.",
              style: TextStyle(fontSize: 14.sp, color: Colors.black54)));
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
