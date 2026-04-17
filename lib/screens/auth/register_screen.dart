import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/aurora_background.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _role    = 'student';
  String _gender  = 'boys';
  String? _block;
  String? _room;
  bool _obscure   = true;
  bool _isLoading = false;

  List<String> get _blocks => blocksForGender(_gender);

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_block == null || _room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select block and room'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final emailErr = await Validators.checkEmailUnique(_emailCtrl.text.trim());
      if (emailErr != null) { _showError(emailErr); return; }

      final phoneErr = await Validators.checkPhoneUnique(_phoneCtrl.text.trim());
      if (phoneErr != null) { _showError(phoneErr); return; }

      final capErr = await Validators.checkRoomCapacity(_block!, _room!, _gender);
      if (capErr != null) { _showError(capErr); return; }

      await context.read<AuthProvider>().register(
        _nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text.trim(),
        _role, _room!, _block!, _phoneCtrl.text.trim(),
      );
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
          title: Text('Create Account',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1040),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(_nameCtrl, 'Full Name', Icons.person_outline,
                        validator: (v) => Validators.required(v, 'Name')),
                    const SizedBox(height: 14),
                    _field(_emailCtrl, 'Email', Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => Validators.email(v, role: _role)),
                    const SizedBox(height: 14),
                    _field(_passCtrl, 'Password', Icons.lock_outline,
                        obscure: _obscure, validator: Validators.password,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )),
                    const SizedBox(height: 14),
                    _field(_phoneCtrl, 'Phone', Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone),
                    const SizedBox(height: 14),

                    // Gender toggle
                    _label('Hostel Type'),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _genderChip('boys', 'Boys Hostel', Icons.male)),
                      const SizedBox(width: 12),
                      Expanded(child: _genderChip('girls', 'Girls Hostel', Icons.female)),
                    ]),
                    const SizedBox(height: 14),

                    // Block dropdown
                    _label('Block'),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _block,
                      hint: 'Select Block',
                      items: _blocks,
                      itemLabel: (b) {
                        final cap = sharingForBlock(b);
                        return cap != null ? '$b ($cap sharing)' : b;
                      },
                      onChanged: (v) => setState(() { _block = v; _room = null; }),
                    ),
                    const SizedBox(height: 14),

                    // Room dropdown
                    _label('Room Number'),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _room,
                      hint: _block == null ? 'Select block first' : 'Select Room',
                      items: _block != null ? roomsForBlock(_block!) : [],
                      itemLabel: (r) => '$_block-$r  (Floor ${r[0]})',
                      onChanged: _block != null ? (v) => setState(() => _room = v) : null,
                    ),
                    const SizedBox(height: 14),

                    // Role dropdown
                    _label('Role'),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _role,
                      hint: 'Select Role',
                      items: const ['student', 'warden', 'doctor', 'admin'],
                      itemLabel: (r) => r[0].toUpperCase() + r.substring(1),
                      onChanged: (v) => setState(() => _role = v!),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFF472B6), Color(0xFF818CF8)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text('Create Account',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('Already have an account? Sign In',
                          style: GoogleFonts.inter(
                              color: const Color(0xFFF472B6), fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(color: Colors.white60, fontSize: 12));

  Widget _genderChip(String value, String label, IconData icon) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() { _gender = value; _block = null; _room = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF818CF8).withOpacity(0.2) : const Color(0xFF0F0A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? const Color(0xFF818CF8) : Colors.white.withOpacity(0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? const Color(0xFF818CF8) : Colors.white54, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: selected ? const Color(0xFF818CF8) : Colors.white54,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    void Function(T?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
          dropdownColor: const Color(0xFF1A0A2E),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(itemLabel(item)),
          )).toList(),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF0F0A2A),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF472B6), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
