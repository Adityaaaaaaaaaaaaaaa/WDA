import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/AppBar.dart';
import '../../../widgets/uNavBar.dart';
import '../widgets/profile_header.dart';
import '../widgets/eco_points_section.dart';
import '../widgets/achievements_section.dart';
import '../controllers/profile_controller.dart';

class UProfilePage extends ConsumerStatefulWidget {
  const UProfilePage({super.key});

  @override
  ConsumerState<UProfilePage> createState() => _UProfilePageState();
}

class _UProfilePageState extends ConsumerState<UProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Handle navigation and refresh after editing
  Future<void> _openEditProfile(BuildContext context) async {
    final result = await context.push('/EditProfile');
    if (result == true && mounted) {
      debugPrint('\x1B[34mProfile updated → refreshing UI\x1B[0m');
      ref.read(profileControllerProvider.notifier).refreshProfile();

      // Replay the entrance animation to show refresh visually
      _animController
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: const UAppBar(title: "My Profile"),
      backgroundColor: const Color(0xFFF1F8E9),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            "Failed to load profile: $e",
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text("No profile data available."));
          }

          final userData = {
            'displayName': profile.name,
            'phone': profile.phone,
            'photoUrl': profile.photoUrl,
          };

          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openEditProfile(context),
                      child: ProfileHeader(userData: userData),
                    ),
                    SizedBox(height: 20.h),
                    const EcoPointsSection(),
                    SizedBox(height: 20.h),
                    const AchievementsSection(),
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const UNavBar(currentIndex: 4),
    );
  }
}
