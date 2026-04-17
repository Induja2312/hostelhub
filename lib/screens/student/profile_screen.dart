import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/aurora_background.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _roomCtrl;
  late TextEditingController _blockCtrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUserModel;
    _nameCtrl  = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _roomCtrl  = TextEditingController(text: user?.roomNumber ?? '');
    _blockCtrl = TextEditingController(text: user?.hostelBlock ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _roomCtrl.dispose();
    _blockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = context.read<AuthProvider>().currentUserModel!;
      await context.read<AuthProvider>().updateProfile(user.uid, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'roomNumber': _roomCtrl.text.trim(),
        'hostelBlock': _blockCtrl.text.trim(),
      });
      setState(() => _editing = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated!')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;
    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : '?';

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('My Profile',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          actions: [
            if (!_editing)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () => setState(() => _editing = true),
              )
            else
              TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save',
                        style: GoogleFonts.inter(
                            color: const Color(0xFFF472B6), fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(children: [
              // Avatar
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF472B6), Color(0xFF818CF8)]),
                ),
                child: Center(
                  child: Text(initial,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF818CF8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.5)),
                ),
                child: Text((user?.role ?? '').toUpperCase(),
                    style: GoogleFonts.inter(
                        color: const Color(0xFF818CF8),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Text(user?.email ?? '',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 28),

              // Fields card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1040),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(children: [
                  _field('Full Name', _nameCtrl, Icons.person_outline,
                      enabled: _editing,
                      validator: (v) => Validators.required(v, 'Name')),
                  const SizedBox(height: 14),
                  _field('Phone', _phoneCtrl, Icons.phone_outlined,
                      enabled: _editing,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: _field('Block', _blockCtrl, Icons.apartment_outlined,
                          enabled: _editing,
                          validator: (v) => Validators.required(v, 'Block')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field('Room', _roomCtrl, Icons.meeting_room_outlined,
                          enabled: _editing,
                          validator: (v) => Validators.required(v, 'Room')),
                    ),
                  ]),
                ]),
              ),

              if (_editing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      final u = context.read<AuthProvider>().currentUserModel;
                      _nameCtrl.text  = u?.name ?? '';
                      _phoneCtrl.text = u?.phone ?? '';
                      _roomCtrl.text  = u?.roomNumber ?? '';
                      _blockCtrl.text = u?.hostelBlock ?? '';
                      setState(() => _editing = false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(color: Colors.white54)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF472B6), Color(0xFF818CF8)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Save Changes',
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {bool enabled = true,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(
          color: enabled ? Colors.white : Colors.white54, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: enabled
            ? const Color(0xFF0F0A2A)
            : const Color(0xFF0F0A2A).withOpacity(0.5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF472B6), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
