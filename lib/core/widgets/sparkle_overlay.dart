import 'dart:math';
import 'package:flutter/material.dart';

class _Particle {
  Offset position;
  Offset velocity;
  double radius;
  double life; // 1.0 → 0.0
  Color color;

  _Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
  }) : life = 1.0;
}

class _SparkleController extends ChangeNotifier {
  final List<_Particle> _particles = [];
  final Random _rng = Random();
  bool _ticking = false;

  static const _colors = [
    Color(0xFFF472B6),
    Color(0xFFFF9DD6),
    Color(0xFFFFB6E1),
  ];

  void burst(Offset position) {
    for (int i = 0; i < 8; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 1.0 + _rng.nextDouble() * 2.0;
      _particles.add(_Particle(
        position: position,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        radius: 1.0 + _rng.nextDouble() * 1.5,
        color: _colors[_rng.nextInt(_colors.length)],
      ));
    }
    _startTick();
  }

  void _startTick() {
    if (_ticking) return;
    _ticking = true;
    _tick();
  }

  void _tick() {
    if (_particles.isEmpty) { _ticking = false; return; }
    for (final p in _particles) {
      p.position += p.velocity;
      p.velocity = Offset(p.velocity.dx * 0.92, p.velocity.dy * 0.92 + 0.18);
      p.life -= 0.045;
    }
    _particles.removeWhere((p) => p.life <= 0);
    notifyListeners();
    if (_particles.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 16), _tick);
    } else {
      _ticking = false;
    }
  }

  List<_Particle> get particles => _particles;
}

class SparkleOverlay extends StatefulWidget {
  final Widget child;
  const SparkleOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<SparkleOverlay> createState() => _SparkleOverlayState();
}

class _SparkleOverlayState extends State<SparkleOverlay> {
  final _controller = _SparkleController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _controller.burst(e.position),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => CustomPaint(
          foregroundPainter: _SparklePainter(_controller.particles),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final List<_Particle> particles;
  _SparklePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(p.position, p.radius * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => true;
}
