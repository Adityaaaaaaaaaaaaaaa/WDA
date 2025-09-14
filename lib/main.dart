import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/firebase_options.dart';
import 'config/performance.dart';
import 'features/auth/signin_page.dart';
import 'features/onboarding/onboarding.dart';
import 'features/setup/driverSetup_page.dart';
import 'features/setup/userSetup_page.dart';
import 'features/setup/user_role_page.dart';
import 'features/splash/splash_screen.dart';
import 'features/user/home/uHome_page.dart';
import 'utils/adaptive_transition.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  perfObserver.attach();
  await perfBootstrap();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  await GoogleSignIn.instance.initialize();
  try {
    if (await File('.env').exists()) {
      await dotenv.load(fileName: ".env");
      debugPrint("\x1B[32m[dotenv] .env file loaded successfully\x1B[0m");
    } else {
      debugPrint("\x1B[33m[dotenv] .env file not found, skipping...\x1B[0m");
    }
  } catch (e) {
    debugPrint("\x1B[31m[dotenv] Failed to load .env: $e\x1B[0m");
  }
  debugPrint = (String? message, {int? wrapWidth}) {};
  runApp(const ProviderScope(child: MyApp()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
    precacheHomeImages();  // fire-and-forget
  });
}

final GoRouter _router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(), //3 page onboarding
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignInPage(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/userRole',
      builder: (context, state) => const UserRolePage(),
    ),
    GoRoute(
      path: '/userSetup',
      builder: (context, state) => const UserSetupPage(),
    ),
    GoRoute(
      path: '/driverSetup',
      builder: (context, state) => const DriverSetupPage(),
    ),
    GoRoute(
      path: '/uHome',
      builder: (context, state) => const UHomePage(),
    ),
  ],
);

// Safe, version-agnostic way to read the current path without poking notifiers.
String _readLocation() {
  try {
    // Newer go_router: RouteMatchList has a `uri` (Uri)
    final cfg = _router.routerDelegate.currentConfiguration;
    final Uri? uri = (cfg as dynamic).uri as Uri?;
    if (uri != null) return uri.path;

    // Some versions expose a `location` (String) instead
    final String? loc = (cfg as dynamic).location as String?;
    if (loc != null) return Uri.parse(loc).path;
  } catch (_) {
    // fall through
  }
  try {
    // Last resort (may notify) — used only if the above fails
    return _router.routeInformationProvider.value.uri.path;
  } catch (_) {
    return '/';
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          scrollBehavior: const TightScrollBehavior(),
          debugShowCheckedModeBanner: false,
          title: 'Waste Disposal App',
          routerConfig: _router,
          builder: (context, child) {
            // ✅ Use the global _router; do NOT use GoRouter.of(context) here
            // Replace these two lines:
            // final routeInfo = _router.routeInformationProvider.value;
            // final location  = routeInfo.uri.path;

            // With this single line:
            final location = _readLocation();   // read-only and safe

            final weight = kRouteWeights[location] ?? PageWeight.light;

            return ValueListenableBuilder<bool>(
              valueListenable: JankMonitor.isStressed,
              builder: (context, stressed, _) {
                final spec = TransitionSpec.from(weight, stressed: stressed);

                return AnimatedSwitcher(
                  duration: spec.duration,
                  switchInCurve: spec.curveIn,
                  switchOutCurve: spec.curveOut,

                  // ✅ Keep only the current child (prevents two Navigators with same GlobalKey)
                  layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),

                  // 'widget' is non-null here; no '!' needed
                  transitionBuilder: (widget, animation) => spec.builder(widget, animation),
                  child: KeyedSubtree(
                    key: ValueKey(location),               // forces switch on route change
                    child: child ?? const SizedBox.shrink(), // guard during router boot
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
