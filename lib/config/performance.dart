import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

// Global Navigator key (needed for precaching context)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

const List<String> kHomeBgAssets = [
  'assets/signup.png',
];

// Runs at startup to apply system-level tweaks
Future<void> perfBootstrap() async {
  try {
    GestureBinding.instance.resamplingEnabled = true;
  } catch (_) {}
  _setAdaptiveRefresh(high: true);
  final cache = PaintingBinding.instance.imageCache;
  cache.maximumSize = 200;            
  cache.maximumSizeBytes = 120 << 20;
  assert(() {
    debugPrintBeginFrameBanner = false;
    debugPrintEndFrameBanner = false;
    return true;
  }());
  WidgetsBinding.instance.scheduleWarmUpFrame();
  HttpOverrides.global = _HttpTuningOverrides();
  JankMonitor.attach();
}

// Lifecycle observer to clear/shrink caches when backgrounded
class PerfLifecycle with WidgetsBindingObserver {
  void attach() => WidgetsBinding.instance.addObserver(this);
  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      final cache = PaintingBinding.instance.imageCache;
      cache.clear();          
      cache.clearLiveImages();
      cache.maximumSize = 120;
      cache.maximumSizeBytes = 80 << 20;
    }
    if (state == AppLifecycleState.resumed) {
      final cache = PaintingBinding.instance.imageCache;
      cache.maximumSize = 200;
      cache.maximumSizeBytes = 120 << 20;
    }
  }
}

final perfObserver = PerfLifecycle();

// Scroll behavior tweak
class TightScrollBehavior extends MaterialScrollBehavior {
  const TightScrollBehavior();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

// Adaptive refresh rate (Android)
Future<void> _setAdaptiveRefresh({bool high = true}) async {
  try {
    final modes = await FlutterDisplayMode.supported;
    if (modes.isEmpty) return;
    modes.sort((a, b) => b.refreshRate.compareTo(a.refreshRate));
    final best = modes.first;
    final native60 = modes.firstWhere(
      (m) => m.refreshRate.round() == 60, orElse: () => modes.last,
    );
    await FlutterDisplayMode.setPreferredMode(high ? best : native60);
  } catch (_) {}
}

// HTTP connection tuning
class _HttpTuningOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final c = super.createHttpClient(context);
    c.autoUncompress = true;                         
    c.maxConnectionsPerHost = 6;
    c.connectionTimeout = const Duration(seconds: 30);
    c.idleTimeout = const Duration(seconds: 30);
    return c;
  }
}

/// Precache home-screen background images
Future<void> precacheHomeImages() async {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;

  final double logicalWidth = MediaQuery.of(ctx).size.width;
  final double devicePixelRatio = MediaQuery.of(ctx).devicePixelRatio;
  final int decodeWidth = (logicalWidth * devicePixelRatio).clamp(600, 1440).toInt();

  for (final path in kHomeBgAssets) {
    final provider = ResizeImage(AssetImage(path), width: decodeWidth);
    await precacheImage(provider, ctx);
  }
}


class JankMonitor {
  static final ValueNotifier<bool> isStressed = ValueNotifier(false);
  static final List<int> _rasterMs = <int>[];

  static void attach() {
    try {
      SchedulerBinding.instance.addTimingsCallback((timings) {
        for (final t in timings) {
          _rasterMs.add(t.rasterDuration.inMilliseconds);
          if (_rasterMs.length > 30) _rasterMs.removeAt(0);
        }
        if (_rasterMs.isEmpty) return;
        final avg = _rasterMs.reduce((a, b) => a + b) / _rasterMs.length;
        final stressed = avg > 20;
        if (isStressed.value != stressed) isStressed.value = stressed;
      });
    } catch (_) {}
  }
}

