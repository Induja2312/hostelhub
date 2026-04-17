import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_provider.dart';
import '../../models/medical_visit_model.dart';
import '../../core/widgets/aurora_background.dart';
import '../../core/utils/helpers.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1040),
        title: Text('Logout', style: GoogleFonts.inter(color: Colors.white)),
        content: Text('Are you sure?', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Logout', style: GoogleFonts.inter(color: const Color(0xFF34D399)))),
        ],
      ),
    );
    if (confirm == true && mounted) await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUserModel;

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF34D399).withOpacity(0.2),
                ),
                child: const Icon(Icons.medical_services, color: Color(0xFF34D399), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clinic Portal',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(user?.name ?? 'Doctor',
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.logout, color: Colors.white70), onPressed: _logout),
          ],
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFF34D399),
            labelColor: const Color(0xFF34D399),
            unselectedLabelColor: Colors.white38,
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: Column(
          children: [
            _StatsBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _VisitList(status: 'pending'),
                  _VisitList(status: 'accepted'),
                  _VisitList(status: 'completed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('medical_visits').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final pending   = docs.where((d) => (d.data() as Map)['status'] == 'pending').length;
        final accepted  = docs.where((d) => (d.data() as Map)['status'] == 'accepted').length;
        final completed = docs.where((d) => (d.data() as Map)['status'] == 'completed').length;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1040),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              _StatItem(pending.toString(),   'Pending',   const Color(0xFFFBBF24)),
              Container(width: 1, height: 32, color: Colors.white12),
              _StatItem(accepted.toString(),  'Accepted',  const Color(0xFF60A5FA)),
              Container(width: 1, height: 32, color: Colors.white12),
              _StatItem(completed.toString(), 'Completed', const Color(0xFF34D399)),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count, label;
  final Color color;
  const _StatItem(this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(count, style: GoogleFonts.inter(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
        ]),
      );
}

class _VisitList extends StatelessWidget {
  final String status;
  const _VisitList({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicalVisitModel>>(
      stream: context.read<MedicalProvider>().getAllVisitsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF34D399)));
        }
        final visits = (snapshot.data ?? []).where((v) => v.status == status).toList();

        if (visits.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(status == 'completed' ? Icons.check_circle_outline : Icons.inbox_outlined,
                  color: Colors.white24, size: 52),
              const SizedBox(height: 12),
              Text('No $status requests', style: GoogleFonts.inter(color: Colors.white38)),
            ]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: visits.length,
          itemBuilder: (context, i) => _VisitCard(visit: visits[i]),
        );
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  final MedicalVisitModel visit;
  const _VisitCard({required this.visit});

  Color get _urgencyColor {
    switch (visit.urgency) {
      case 'critical': return const Color(0xFFFF4444);
      case 'urgent':   return const Color(0xFFFBBF24);
      default:         return const Color(0xFF34D399);
    }
  }

  void _showSheet(BuildContext context) {
    final instrCtrl = TextEditingController(text: visit.doctorInstruction);
    DateTime? appointmentTime = visit.appointmentTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1040),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(visit.studentName,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('Room ${visit.roomNumber}',
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _urgencyColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _urgencyColor.withOpacity(0.5)),
                      ),
                      child: Text(visit.urgency.toUpperCase(),
                          style: GoogleFonts.inter(color: _urgencyColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('SYMPTOMS', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                      const SizedBox(height: 6),
                      Text(visit.symptoms, style: GoogleFonts.inter(color: Colors.white, fontSize: 14)),
                      if (visit.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('NOTES', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Text(visit.notes, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Appointment time picker
                  Text('APPOINTMENT TIME *',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: appointmentTime ?? DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(appointmentTime ?? DateTime.now()),
                      );
                      if (time == null) return;
                      setModal(() => appointmentTime = DateTime(
                          date.year, date.month, date.day, time.hour, time.minute));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appointmentTime != null
                              ? const Color(0xFF34D399).withOpacity(0.6)
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.calendar_today,
                            color: appointmentTime != null ? const Color(0xFF34D399) : Colors.white38,
                            size: 18),
                        const SizedBox(width: 12),
                        Text(
                          appointmentTime == null
                              ? 'Select appointment date & time'
                              : '${appointmentTime!.day}/${appointmentTime!.month}/${appointmentTime!.year}  ${appointmentTime!.hour.toString().padLeft(2,'0')}:${appointmentTime!.minute.toString().padLeft(2,'0')}',
                          style: GoogleFonts.inter(
                            color: appointmentTime != null ? Colors.white : Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('INSTRUCTIONS / PRESCRIPTION',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: instrCtrl,
                    maxLines: 4,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Take paracetamol 500mg twice daily...',
                      hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0F0A2A),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF34D399), width: 1.5)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visit.status == 'pending')
                    _ActionBtn(
                      label: 'Accept & Set Appointment',
                      icon: Icons.check_circle_outline,
                      colors: const [Color(0xFF34D399), Color(0xFF059669)],
                      onTap: () async {
                        if (appointmentTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select an appointment time'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        await context.read<MedicalProvider>().acceptVisit(
                            visit.id, instrCtrl.text.trim(), appointmentTime!);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          Helpers.showSnackBar(context, 'Appointment set!');
                        }
                      },
                    ),
                  if (visit.status == 'accepted') ...[
                    _ActionBtn(
                      label: 'Update Appointment & Instructions',
                      icon: Icons.edit_outlined,
                      colors: const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                      onTap: () async {
                        await context.read<MedicalProvider>().updateInstruction(
                            visit.id, instrCtrl.text.trim(), appointmentTime);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          Helpers.showSnackBar(context, 'Updated!');
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _ActionBtn(
                      label: 'Mark as Completed',
                      icon: Icons.done_all,
                      colors: const [Color(0xFF34D399), Color(0xFF059669)],
                      onTap: () async {
                        await context.read<MedicalProvider>().completeVisit(
                            visit.id, instrCtrl.text.trim());
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          Helpers.showSnackBar(context, 'Visit completed');
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1040),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _urgencyColor.withOpacity(0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _urgencyColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.medical_services_outlined, color: _urgencyColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(visit.studentName,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                Text('Room ${visit.roomNumber}',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _urgencyColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _urgencyColor.withOpacity(0.5)),
              ),
              child: Text(visit.urgency.toUpperCase(),
                  style: GoogleFonts.inter(color: _urgencyColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(visit.symptoms,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          if (visit.doctorInstruction.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF34D399).withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.notes, color: Color(0xFF34D399), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(visit.doctorInstruction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: const Color(0xFF34D399), fontSize: 12)),
                ),
              ]),
            ),
          ],
          if (visit.appointmentTime != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, color: Color(0xFF60A5FA), size: 13),
              const SizedBox(width: 4),
              Text(
                'Appt: ${visit.appointmentTime!.day}/${visit.appointmentTime!.month}/${visit.appointmentTime!.year}  ${visit.appointmentTime!.hour.toString().padLeft(2,'0')}:${visit.appointmentTime!.minute.toString().padLeft(2,'0')}',
                style: GoogleFonts.inter(color: const Color(0xFF60A5FA), fontSize: 12),
              ),
            ]),
          ],
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.access_time, color: Colors.white38, size: 13),
            const SizedBox(width: 4),
            Text(Helpers.formatDateTime(visit.createdAt),
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
            const Spacer(),
            Text('Tap to manage →',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: Icon(icon, color: Colors.white, size: 18),
          label: Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
