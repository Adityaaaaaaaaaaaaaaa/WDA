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
    _NavItem(icon: Icons.home, label: "Home", route: "/uhome"),
    _NavItem(icon: Icons.map, label: "Map", route: "/umap"),
    _NavItem(icon: Icons.task_alt, label: "Tasks", route: "/utasks"),
    _NavItem(icon: Icons.add_box, label: "Request", route: "/urequest"),
    _NavItem(icon: Icons.person, label: "Profile", route: "/uprofile"),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
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
                  // Navigate using GoRouter
                  if (item.route.isNotEmpty) {
                    context.push(item.route);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: selected ? Colors.green.shade100 : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22.sp,
                        color: selected
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.green.shade700
                              : Colors.grey.shade500,
                        ),
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
