import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/aurora_background.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (!email.endsWith('@psgtech.ac.in')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Only @psgtech.ac.in emails are allowed'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().forgotPassword(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1040),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: _sent ? _buildSuccess() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF818CF8).withOpacity(0.15),
          ),
          child: const Icon(Icons.lock_reset, color: Color(0xFF818CF8), size: 36),
        ),
        const SizedBox(height: 20),
        Text('Reset Password',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Enter your @psgtech.ac.in email and we\'ll send a reset link.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 28),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'your@psgtech.ac.in',
            hintStyle: GoogleFonts.inter(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0F0A2A),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54, size: 20),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFF472B6), Color(0xFF818CF8)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: _loading ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Send Reset Link',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_outlined,
            color: Color(0xFF34D399), size: 56),
        const SizedBox(height: 16),
        Text('Check your email',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('A password reset link has been sent to\n${_emailCtrl.text.trim()}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => context.pop(),
          child: Text('Back to Sign In',
              style: GoogleFonts.inter(color: const Color(0xFFF472B6))),
        ),
      ],
    );
  }
}
