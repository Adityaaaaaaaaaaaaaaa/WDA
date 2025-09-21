import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class DNavBar extends StatelessWidget {
  final int currentIndex;

  const DNavBar({super.key, required this.currentIndex});

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.home_rounded, label: "Home", route: "/dHome"),
    _NavItem(icon: Icons.work_rounded, label: "Jobs", route: "/dJobs"),
    _NavItem(icon: Icons.map_rounded, label: "Map", route: "/dMap"),
    _NavItem(icon: Icons.qr_code_rounded, label: "QR", route: "/dQr"),
    _NavItem(icon: Icons.person_rounded, label: "Profile", route: "/dProfile"),
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
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = i == currentIndex;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(30.r),
                onTap: () => context.push(item.route),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue.shade100.withOpacity(0.7) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: selected ? 24.sp : 20.sp,
                          color: selected ? Colors.blue.shade700 : Colors.grey.shade600),
                      SizedBox(height: 4.h),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? Colors.blue.shade700 : Colors.grey.shade600,
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
  const _NavItem({required this.icon, required this.label, required this.route});
}
