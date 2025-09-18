// lib/features/user/tasks/uTaskDetails_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../model/task_model.dart';
import '../../../services/uTasks_updateDelete.dart';
import '../request/widgets/waste_type_grid.dart'; // reuse the grid
import '../widgets/status_chip.dart'; // your chips

class UTaskDetailsPage extends StatefulWidget {
  final String taskId;           // <-- pass this via context.push('/uTaskDetails', extra: taskId)
  const UTaskDetailsPage({super.key, required this.taskId});

  @override
  State<UTaskDetailsPage> createState() => _UTaskDetailsPageState();
}

class _UTaskDetailsPageState extends State<UTaskDetailsPage> {
  final _svc = UTasksUpdateDeleteService();

  // local editors
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _size;
  String? _urgency;
  DateTime? _dateTime;
  Set<String> _waste = {};

  bool _editMode = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _canEdit(TaskModel t) {
    // Allow edit while pending and not driver-assigned and QR not used
    if (t.status == "completed" || t.status == "cancelled") return false;
    if (t.driverAssigned == true) return false;
    if (t.qrCodeUsed == true) return false;
    return true;
  }

  // Same size multipliers you used on Request page
  static const Map<String, double> _sizeMultiplier = {
    "Tiny (1-2 items)": 1.0,
    "Small (3-5 items)": 1.5,
    "Medium (6-10 items)": 2.0,
    "Large (11-20 items)": 3.0,
    "XL (20+ items)": 5.0,
    "Mountain (50+ items)": 8.0,
    "A lot": 10.0,
  };

  int _recalcEcoPoints(Set<String> waste, String? size) {
    // reuse the points from your wasteTypeLookup
    final base = waste.fold<int>(
      0, (sum, label) => sum + (wasteTypeLookup[label]?.points ?? 0),
    );
    final mult = _sizeMultiplier[size] ?? 1.0;
    return (base * mult).round();
    // creation = floor(eco/2), completion = eco - creation (handled by service)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Task Details"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<TaskModel>(
        stream: _svc.streamTaskById(widget.taskId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text("Error loading task ❌"));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final task = snap.data!;

          // prime editors once when task arrives or edit toggled
          if (!_editMode) {
            _addressCtrl.text = task.address;
            _notesCtrl.text = task.notes;
            _size = task.size;
            _urgency = task.urgency;
            _dateTime = task.pickupDateTime;
            _waste = {...task.wasteTypes};
          }

          final canEdit = _canEdit(task);
          final statusColor = StatusChipTheme.colorFor(task);

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER CARD
                _HeaderSummaryCard(task: task),

                SizedBox(height: 12.h),

                // STATUS + POINTS + QR USED
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    StatusChip(text: task.userDeleted || task.status=="cancelled" ? "Cancelled" : task.status, color: statusColor),
                    EcoPointsChip(points: task.taskPoints),
                    if (task.qrCodeUsed) OutlinedChip(label: "QR Scanned", color: Colors.teal, icon: Icons.qr_code_2),
                    if (task.driverAssigned) OutlinedChip(label: "Driver Assigned", color: Colors.indigo, icon: Icons.person),
                  ],
                ),

                SizedBox(height: 16.h),

                // DATE / TIME / ADDRESS (chips)
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    if (task.pickupDateTime != null)
                      OutlinedChip(
                        label: DateFormat("EEE d, MMM").format(task.pickupDateTime!),
                        color: Colors.blueGrey,
                        icon: Icons.calendar_month_outlined,
                      ),
                    if (task.pickupDateTime != null)
                      OutlinedChip(
                        label: DateFormat("h:mm a").format(task.pickupDateTime!),
                        color: Colors.blueGrey,
                        icon: Icons.access_time,
                      ),
                    OutlinedChip(
                      label: task.address,
                      color: Colors.black87,
                      icon: Icons.location_on,
                    ),
                    if (task.driverName != null && task.driverName!.isNotEmpty)
                      OutlinedChip(
                        label: task.driverName!,
                        color: Colors.black87,
                        icon: Icons.person,
                      ),
                  ],
                ),

                SizedBox(height: 18.h),

                // PROGRESS STEPPER (read-only on user side, live)
                _ProgressStepper(progress: task.progressStages),

                SizedBox(height: 18.h),

                // QR CODE (user shows this to driver)
                _QrBlock(
                  qrData: task.qrCodeData,
                  scanned: task.qrCodeUsed,
                ),

                SizedBox(height: 18.h),

                // EDIT SECTION (only when allowed)
                if (canEdit) _buildEditableSection(task),

                // ACTIONS
                SizedBox(height: 18.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: !canEdit ? null : () async {
                          final newEco = _recalcEcoPoints(_waste, _size);
                          await _svc.updateTaskWithRecalc(
                            original: task,
                            updates: {
                              "wasteTypes": _waste.toList(),
                              "size": _size,
                              "urgency": _urgency,
                              "pickupDateTime": _dateTime,
                              "address": _addressCtrl.text.trim(),
                              "notes": _notesCtrl.text.trim(),
                              "newEcoPoints": newEco, // service will handle split + user delta
                            },
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Task updated ✅")),
                            );
                          }
                          setState(() => _editMode = false);
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text("Save Changes"),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                        ),
                        onPressed: () async {
                          await _svc.cancelTaskAndRevokeCreation(task);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Task cancelled. Points revoked.")),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text("Cancel Task"),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditableSection(TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          title: const Text("Edit task"),
          contentPadding: EdgeInsets.zero,
          value: _editMode,
          onChanged: (v) => setState(() => _editMode = v),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: !_editMode
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Waste Types", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp)),
                    SizedBox(height: 8.h),
                    WasteTypeGrid(
                      initialSelected: _waste,
                      onChanged: (set) => setState(() => _waste = set),
                    ),
                    SizedBox(height: 12.h),
                    // quick editors
                    _MiniEditors(
                      size: _size,
                      urgency: _urgency,
                      dateTime: _dateTime,
                      onSize: (s) => setState(() => _size = s),
                      onUrgency: (u) => setState(() => _urgency = u),
                      onDateTime: (dt) => setState(() => _dateTime = dt),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(
                        labelText: "Pickup Address",
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _notesCtrl,
                      minLines: 2,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: "Notes",
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ---------- pieces (kept compact & pretty) ----------

class _HeaderSummaryCard extends StatelessWidget {
  const _HeaderSummaryCard({required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0,3))],
      ),
      child: Row(
        children: [
          Container(
            width: 42.w, height: 42.w,
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.eco, color: Colors.green),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.wasteTypes.join(", "),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text("#${task.taskId.substring(task.taskId.length - 6)}",
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrBlock extends StatelessWidget {
  const _QrBlock({required this.qrData, required this.scanned});
  final String qrData;
  final bool scanned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2),
              SizedBox(width: 8.w),
              const Text("QR Code", style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (scanned)
                Chip(
                  label: const Text("Scanned"),
                  visualDensity: VisualDensity.compact,
                  labelStyle: const TextStyle(color: Colors.white),
                  backgroundColor: Colors.teal,
                ),
            ],
          ),
          SizedBox(height: 12.h),
          // 👉 Customize size, style, embeddedImage, etc.
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: QrImageView(
              data: qrData,
              size: 180.w,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle),
            ),
          ),
          SizedBox(height: 8.h),
          Text("Show this code to the driver at pickup", style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ProgressStepper extends StatelessWidget {
  const _ProgressStepper({required this.progress});
  final Map<String, dynamic> progress;

  bool _isTrue(String k) => (progress[k] ?? false) == true;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ["accepted", Icons.check_circle],
      ["enRoute", Icons.directions_car],
      ["atLocation", Icons.my_location],
      ["collected", Icons.delete_outline],
      ["atLandfill", Icons.factory_outlined],
      ["completed", Icons.verified_rounded],
    ];
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: steps.map((s) {
          final on = _isTrue(s[0] as String);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(s[1] as IconData, color: on ? Colors.green : Colors.grey.shade400),
              SizedBox(height: 4.h),
              Text(
                (s[0] as String)
                    .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}')
                    .trim(), // at Landfill, at Location, etc.
                style: TextStyle(fontSize: 10.sp, color: on ? Colors.green : Colors.grey),
              )
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// small editors for size/urgency/date in one row
class _MiniEditors extends StatelessWidget {
  const _MiniEditors({
    required this.size,
    required this.urgency,
    required this.dateTime,
    required this.onSize,
    required this.onUrgency,
    required this.onDateTime,
  });

  final String? size;
  final String? urgency;
  final DateTime? dateTime;
  final ValueChanged<String?> onSize;
  final ValueChanged<String?> onUrgency;
  final ValueChanged<DateTime?> onDateTime;

  @override
  Widget build(BuildContext context) {
    final urgencies = const [
      "ASAP ( now !!! 😱)",
      "Urgent (Today! 🔥)",
      "Soon (1-2 days 🙏)",
      "Within 3-4 days (No rush, but soon ⏳)",
      "Whenever (I'm zen 🧘)",
    ];
    final sizes = _UTaskDetailsPageState._sizeMultiplier.keys.toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: size,
                decoration: const InputDecoration(labelText: "Size", border: OutlineInputBorder()),
                items: sizes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: onSize,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: urgency,
                decoration: const InputDecoration(labelText: "Urgency", border: OutlineInputBorder()),
                items: urgencies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: onUrgency,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              initialDate: dateTime ?? now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            );
            if (d == null) return;
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(dateTime ?? now),
            );
            if (t == null) return;
            onDateTime(DateTime(d.year, d.month, d.day, t.hour, t.minute));
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(
            dateTime == null
                ? "Pick date & time"
                : "${DateFormat('EEE d, MMM').format(dateTime!)} · ${DateFormat('h:mm a').format(dateTime!)}",
          ),
        ),
      ],
    );
  }
}
