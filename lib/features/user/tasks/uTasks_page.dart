// lib/features/user/tasks/uTasks_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../model/task_model.dart';
import '../../../services/uTasks_updateDelete.dart';
import '../widgets/uAppBar.dart';
import '../widgets/uNavBar.dart';
import 'widgets/task_card.dart';

class UTasksPage extends StatelessWidget {
  const UTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = UTasksUpdateDeleteService();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        extendBody: false,
        extendBodyBehindAppBar: true,
        appBar: const UAppBar(title: "Your Tasks 📝"),
        bottomNavigationBar: const UNavBar(currentIndex: 2),

        body: Column(
          children: [
            // Tabs under the custom AppBar
            Padding(
              padding: EdgeInsets.only(top: 70.h),
              child: const TabBar(
                indicatorColor: Colors.green,
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "Upcoming"),
                  Tab(text: "History"),
                ],
              ),
            ),

            // Tab contents
            Expanded(
              child: TabBarView(
                children: [
                  // Upcoming tasks
                  StreamBuilder(
                    stream: service.streamUpcomingTasks(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text("Error loading tasks ❌"));
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final tasks = snapshot.data!
                          .map((data) => TaskModel.fromMap(data))
                          .where((task) => task.status != "completed")
                          .toList();

                      if (tasks.isEmpty) {
                        return const Center(
                            child: Text("No upcoming tasks 🗑️"));
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCard(
                            task: task,
                            onDelete: () async =>
                                await service.deleteTaskForUser(task.taskId),
                            onTap: () => context.push('/uTaskDetails', extra: task.taskId),
                          );
                        },
                      );
                    },
                  ),

                  // History (completed)
                  StreamBuilder(
                    stream: service.streamHistoryTasks(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text("Error loading tasks ❌"));
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final tasks = snapshot.data!
                          .map((data) => TaskModel.fromMap(data))
                          .where((task) =>
                              task.status == "completed" || task.status == "cancelled" || task.userDeleted)
                          .toList();

                      if (tasks.isEmpty) {
                        return const Center(
                            child: Text("No history yet 📜"));
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCard(
                            task: task,
                            onTap: () => context.push('/uTaskDetails', extra: task.taskId),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
