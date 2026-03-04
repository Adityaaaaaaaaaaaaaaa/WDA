import 'package:flutter/material.dart';

enum PageWeight { light, medium, heavy }

typedef _Builder = Widget Function(Widget child, Animation<double> a);

const Cubic _kEmphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
const Cubic _kEmphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

class TransitionSpec {
  final Duration duration;
  final Curve curveIn;   
  final Curve curveOut;  
  // ignore: library_private_types_in_public_api
  final _Builder builder;

  const TransitionSpec(this.duration, this.curveIn, this.curveOut, this.builder);

  factory TransitionSpec.from(PageWeight w, {required bool stressed}) {
    if (stressed) {
      return TransitionSpec(
        const Duration(milliseconds: 220),
        _kEmphasizedDecelerate,
        _kEmphasizedAccelerate,
        (child, a) => FadeTransition(opacity: a, child: child),
      );
    }

    switch (w) {
      case PageWeight.heavy:
        return TransitionSpec(
          const Duration(milliseconds: 260),
          _kEmphasizedDecelerate,
          _kEmphasizedAccelerate,
          (child, a) {
            final fade  = CurvedAnimation(parent: a, curve: Curves.easeOut);
            final scale = Tween<double>(begin: 0.985, end: 1.0).animate(a);
            final slide = Tween<Offset>(begin: const Offset(0, 0.008), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(a);
            return FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: SlideTransition(position: slide, child: child),
              ),
            );
          },
        );

      case PageWeight.medium:
        return TransitionSpec(
          const Duration(milliseconds: 200),
          _kEmphasizedDecelerate,
          _kEmphasizedAccelerate,
          (child, a) {
            final slide = Tween<Offset>(begin: const Offset(0.015, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(a);
            return FadeTransition(
              opacity: a,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );

      case PageWeight.light:
        return TransitionSpec(
          const Duration(milliseconds: 160),
          _kEmphasizedDecelerate,
          _kEmphasizedAccelerate,
          (child, a) {
            final scale = Tween<double>(begin: 0.995, end: 1.0).animate(a);
            return FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
        );
    }
  }
}

const Map<String, PageWeight> kRouteWeights = {
  '/splash': PageWeight.light,
  '/onboarding': PageWeight.light,
  '/signup': PageWeight.light,
  '/userRole': PageWeight.light,
  '/userSetup': PageWeight.light,
  '/driverSetup': PageWeight.light,
  '/uHome': PageWeight.light,
  '/uRequest': PageWeight.heavy,
  '/uTasks': PageWeight.medium,
  '/uTaskDetails': PageWeight.medium,
  '/uMap': PageWeight.heavy,
  '/dHome': PageWeight.light,
  '/dJobs': PageWeight.light,
  '/dJobDetail': PageWeight.heavy,
  '/dMap': PageWeight.heavy,
  '/dQr': PageWeight.light,
  '/dProfile': PageWeight.medium,
  '/uProfile': PageWeight.medium,
  '/achievements': PageWeight.medium,
  '/settings': PageWeight.light,
};
