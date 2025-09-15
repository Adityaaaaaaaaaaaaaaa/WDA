import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class UNavBar extends StatelessWidget {
  final int currentIndex;

  const UNavBar({
    super.key,
    required this.currentIndex,
  });

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_rounded, label: "Home", route: "/uHome"),
    _NavItem(icon: Icons.map_rounded, label: "Map", route: "/umap"),
    _NavItem(icon: Icons.task_alt_rounded, label: "Tasks", route: "/utasks"),
    _NavItem(icon: Icons.add_box_rounded, label: "Request", route: "/urequest"),
    _NavItem(icon: Icons.person_rounded, label: "Profile", route: "/uprofile"),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final selected = index == currentIndex;
            final item = _items[index];

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(30.r),
                onTap: () {
                  if (item.route.isNotEmpty) {
                    context.push(item.route);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.green.shade200.withOpacity(0.8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: selected ? 25.sp : 18.sp,
                        color: selected
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                      ),
                      SizedBox(height: 4.h),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? Colors.green.shade700
                              : Colors.grey.shade500,
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
