import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A modern dropdown with glow and glassy effects
class EnhancedDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final IconData icon;
  final Function(String?) onChanged;
  final Color color;

  const EnhancedDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(color),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: value,
        decoration: _inputDecoration(label, icon, color),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        iconEnabledColor: color.withOpacity(0.7),
      ),
    );
  }
}

/// A simple dropdown without extras
class SimpleDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final IconData icon;
  final Function(String?) onChanged;

  const SimpleDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(Colors.orange),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: value,
        decoration: _inputDecoration(label, icon, Colors.orange),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        iconEnabledColor: Colors.orange.shade700,
      ),
    );
  }
}

/// Enhanced Date picker field
class EnhancedDateField extends StatelessWidget {
  final DateTime? date;
  final Function(DateTime) onPicked;

  const EnhancedDateField({
    super.key,
    required this.date,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(Colors.blue),
      child: TextFormField(
        readOnly: true,
        decoration: _inputDecoration("Pick a Date 📅", Icons.calendar_today, Colors.blue)
            .copyWith(hintText: "When chaos strikes..."),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.blue.shade600,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) onPicked(picked);
        },
        controller: TextEditingController(
          text: date != null ? "${date!.day}/${date!.month}/${date!.year}" : "",
        ),
      ),
    );
  }
}

/// Enhanced Time picker field
class EnhancedTimeField extends StatelessWidget {
  final TimeOfDay? time;
  final Function(TimeOfDay) onPicked;

  const EnhancedTimeField({
    super.key,
    required this.time,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(Colors.purple),
      child: TextFormField(
        readOnly: true,
        decoration: _inputDecoration("Pick a Time ⏰", Icons.access_time, Colors.purple)
            .copyWith(hintText: "When magic happens..."),
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.purple.shade600,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) onPicked(picked);
        },
        controller: TextEditingController(
          text: time != null ? time!.format(context) : "",
        ),
      ),
    );
  }
}

/// Enhanced text input with hint and glow
class EnhancedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hintText;
  final int maxLines;

  const EnhancedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hintText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _boxDecoration(Colors.green),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: _inputDecoration(label, icon, Colors.green)
            .copyWith(hintText: hintText),
      ),
    );
  }
}

/// Shared box decoration
BoxDecoration _boxDecoration(Color color) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(18.r),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.2),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

/// Shared input decoration
InputDecoration _inputDecoration(String label, IconData icon, Color color) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Container(
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Icon(icon, color: color, size: 20.sp),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18.r),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
  );
}
