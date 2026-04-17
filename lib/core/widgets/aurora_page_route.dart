import 'package:flutter/material.dart';

class AuroraPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AuroraPageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInOutCubic));
            final oldFadeTween = Tween<double>(begin: 1.0, end: 0.0)
                .chain(CurveTween(curve: Curves.easeInOutCubic));

            return FadeTransition(
              opacity: secondaryAnimation.drive(oldFadeTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                ),
              ),
            );
          },
        );
}
