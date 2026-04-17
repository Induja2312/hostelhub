import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuroraTextField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;

  const AuroraTextField({
    Key? key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  State<AuroraTextField> createState() => _AuroraTextFieldState();
}

class _AuroraTextFieldState extends State<AuroraTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFFF472B6).withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _obscure,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(
              color: const Color(0xFFFFFFFF).withOpacity(0.4), fontSize: 14),
          filled: true,
          fillColor: const Color(0xFF1E1040),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon,
                  color: _isFocused
                      ? const Color(0xFFF472B6)
                      : const Color(0xFFFFFFFF).withOpacity(0.4),
                  size: 20)
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFFFFFFFF).withOpacity(0.4),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: const Color(0xFFFFFFFF).withOpacity(0.3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFF472B6), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFFF6B6B), width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
