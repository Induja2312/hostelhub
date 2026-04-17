import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class AuroraBackground extends StatefulWidget {
  final Widget child;
  const AuroraBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * pi;

        return Stack(
          children: [
            // Deep dark base
            Container(
              width: w,
              height: h,
              color: const Color(0xFF060614),
            ),

            // Orb 1 — large deep purple, drifts top-left to center
            _Orb(
              color: const Color(0xFF7C3AED),
              size: w * 0.85,
              opacity: 0.55,
              x: w * 0.1 + sin(t * 0.4) * w * 0.18,
              y: h * 0.0 + cos(t * 0.35) * h * 0.12,
            ),

            // Orb 2 — pink/magenta, drifts top-right
            _Orb(
              color: const Color(0xFFEC4899),
              size: w * 0.75,
              opacity: 0.45,
              x: w * 0.4 + sin(t * 0.5 + 1.2) * w * 0.2,
              y: h * 0.05 + cos(t * 0.45 + 0.8) * h * 0.15,
            ),

            // Orb 3 — indigo/blue, drifts bottom-left
            _Orb(
              color: const Color(0xFF4F46E5),
              size: w * 0.9,
              opacity: 0.50,
              x: -w * 0.1 + sin(t * 0.3 + 2.5) * w * 0.22,
              y: h * 0.45 + cos(t * 0.38 + 1.5) * h * 0.18,
            ),

            // Orb 4 — cyan/teal, drifts bottom-right
            _Orb(
              color: const Color(0xFF0EA5E9),
              size: w * 0.65,
              opacity: 0.38,
              x: w * 0.5 + sin(t * 0.55 + 3.8) * w * 0.18,
              y: h * 0.6 + cos(t * 0.42 + 2.2) * h * 0.16,
            ),

            // Orb 5 — rose, small accent, fast drift center
            _Orb(
              color: const Color(0xFFF43F5E),
              size: w * 0.45,
              opacity: 0.35,
              x: w * 0.25 + sin(t * 0.7 + 5.0) * w * 0.25,
              y: h * 0.3 + cos(t * 0.65 + 3.0) * h * 0.22,
            ),

            // Soft noise overlay to add texture
            Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                    Colors.black.withOpacity(0.25),
                  ],
                ),
              ),
            ),

            widget.child,
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  final double x;
  final double y;

  const _Orb({
    required this.color,
    required this.size,
    required this.opacity,
    required this.x,
    required this.y,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(opacity),
                color.withOpacity(opacity * 0.4),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
