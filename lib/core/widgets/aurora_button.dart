import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuroraButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color>? colors;

  const AuroraButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.colors,
  }) : super(key: key);

  @override
  State<AuroraButton> createState() => _AuroraButtonState();
}

class _AuroraButtonState extends State<AuroraButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120),
        lowerBound: 0.96, upperBound: 1.0, value: 1.0);
    _scale = _ctrl;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors ??
        [const Color(0xFFF472B6), const Color(0xFF818CF8)];
    final enabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: SizedBox(
        height: 52,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled
                    ? colors
                    : colors.map((c) => c.withOpacity(0.45)).toList(),
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: enabled
                  ? [BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))]
                  : [],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              splashFactory: InkSparkle.splashFactory,
              splashColor: Colors.white.withOpacity(0.9),
              highlightColor: Colors.white.withOpacity(0.3),
              onTapDown: enabled ? (_) => _ctrl.reverse() : null,
              onTapUp: enabled ? (_) => _ctrl.forward() : null,
              onTapCancel: enabled ? () => _ctrl.forward() : null,
              onTap: enabled ? widget.onPressed : null,
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.label,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
