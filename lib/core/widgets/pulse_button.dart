import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PulseButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onLongPress;
  final double size;

  const PulseButton({
    Key? key,
    required this.label,
    this.color = const Color(0xFFFF4444),
    this.onLongPress,
    this.size = 80,
  }) : super(key: key);

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnims;
  late List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      ),
    );

    _scaleAnims = _controllers
        .map((c) => Tween<double>(begin: 1.0, end: 2.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    _opacityAnims = _controllers
        .map((c) => Tween<double>(begin: 0.6, end: 0.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) _controllers[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: SizedBox(
        width: widget.size * 2.2,
        height: widget.size * 2.2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 3 pulsing rings
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _controllers[i],
                builder: (context, _) => Transform.scale(
                  scale: _scaleAnims[i].value,
                  child: Opacity(
                    opacity: _opacityAnims[i].value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: widget.color, width: 2),
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Main button
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
