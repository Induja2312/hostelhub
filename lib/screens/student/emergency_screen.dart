import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/emergency_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/aurora_background.dart';
import '../../core/widgets/pulse_button.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  Future<void> _sendAlert(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUserModel;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('emergency_alerts').add(
        EmergencyModel(
          id: '', sentBy: user.uid, senderName: user.name,
          roomNumber: user.roomNumber,
          message: 'URGENT: Emergency declared by ${user.name} in Room ${user.roomNumber}',
          status: 'active', createdAt: DateTime.now(),
        ).toMap(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🚨 Emergency alert sent to wardens!'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
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
          automaticallyImplyLeading: false,
          title: Text('Emergency & SOS',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1040),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(
                    'Hold the SOS button to send an emergency alert instantly to all wardens and security.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 15,
                        height: 1.5),
                  ),
                ),
                const SizedBox(height: 60),
                PulseButton(
                  label: 'SOS\nALERT',
                  color: const Color(0xFFFF4444),
                  size: 90,
                  onLongPress: () => _sendAlert(context),
                ),
                const SizedBox(height: 24),
                Text('Hold the button to activate',
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
