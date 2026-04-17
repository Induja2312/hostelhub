import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/helpers.dart';

class MedicalHelpScreen extends StatefulWidget {
  const MedicalHelpScreen({Key? key}) : super(key: key);

  @override
  State<MedicalHelpScreen> createState() => _MedicalHelpScreenState();
}

class _MedicalHelpScreenState extends State<MedicalHelpScreen>
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Help'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Contacts'),
            Tab(text: 'Request Visit'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _ContactsTab(),
          _RequestVisitTab(),
          _MyRequestsTab(),
        ],
      ),
    );
  }
}

// ── Contacts ──────────────────────────────────────────────────────────────────

class _ContactsTab extends StatelessWidget {
  const _ContactsTab();

  Future<void> _dial(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = [
      _ContactData(Icons.local_hospital_outlined, 'Campus Hospital', '1001', const Color(0xFFFF6B6B)),
      _ContactData(Icons.medical_information_outlined, 'On-Call Doctor', '+1234567890', const Color(0xFF60A5FA)),
      _ContactData(Icons.local_pharmacy_outlined, 'Hostel Pharmacy', '+0987654321', const Color(0xFF34D399)),
      _ContactData(Icons.emergency_outlined, 'Ambulance', '108', const Color(0xFFFBBF24)),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contacts.length,
      itemBuilder: (context, i) {
        final c = contacts[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: c.color.withOpacity(0.15),
              child: Icon(c.icon, color: c.color),
            ),
            title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(c.number),
            trailing: IconButton(
              icon: Icon(Icons.call, color: c.color),
              onPressed: () => _dial(c.number),
            ),
            onTap: () => _dial(c.number),
          ),
        );
      },
    );
  }
}

class _ContactData {
  final IconData icon;
  final String title, number;
  final Color color;
  const _ContactData(this.icon, this.title, this.number, this.color);
}

// ── Request Visit ─────────────────────────────────────────────────────────────

class _RequestVisitTab extends StatefulWidget {
  const _RequestVisitTab();

  @override
  State<_RequestVisitTab> createState() => _RequestVisitTabState();
}

class _RequestVisitTabState extends State<_RequestVisitTab> {
  final _notesCtrl = TextEditingController();
  String? _selectedSymptom;
  final _customSymptomsCtrl = TextEditingController();
  String _urgency = 'normal';
  bool _loading = false;

  static const _symptoms = [
    'Fever', 'Headache', 'Cold & Cough', 'Stomach Pain',
    'Vomiting / Nausea', 'Body Pain', 'Dizziness', 'Injury / Wound',
    'Allergic Reaction', 'Chest Pain', 'Breathing Difficulty', 'Other',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    _customSymptomsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final symptom = _selectedSymptom == 'Other'
        ? _customSymptomsCtrl.text.trim()
        : _selectedSymptom ?? '';
    if (symptom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your symptoms'), backgroundColor: Colors.red),
      );
      return;
    }
    final user = context.read<AuthProvider>().currentUserModel;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('medical_visits').add({
        'studentId': user?.uid,
        'studentName': user?.name,
        'roomNumber': user?.roomNumber,
        'symptoms': symptom,
        'notes': _notesCtrl.text.trim(),
        'urgency': _urgency,
        'status': 'pending',
        'doctorInstruction': '',
        'appointmentTime': null,
        'createdAt': Timestamp.now(),
      });
      if (mounted) {
        _notesCtrl.clear();
        _customSymptomsCtrl.clear();
        setState(() { _urgency = 'normal'; _selectedSymptom = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical visit requested!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        DropdownButtonFormField<String>(
          value: _selectedSymptom,
          decoration: const InputDecoration(
            labelText: 'Primary Symptom *',
            border: OutlineInputBorder(),
          ),
          items: _symptoms
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _selectedSymptom = v),
        ),
        if (_selectedSymptom == 'Other') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customSymptomsCtrl,
            decoration: const InputDecoration(
              labelText: 'Describe your symptoms *',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Additional notes (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Urgency Level', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'normal', label: Text('Normal')),
            ButtonSegment(value: 'urgent', label: Text('Urgent')),
            ButtonSegment(value: 'critical', label: Text('Critical')),
          ],
          selected: {_urgency},
          onSelectionChanged: (s) => setState(() => _urgency = s.first),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit Request'),
        ),
      ]),
    );
  }
}

// ── My Requests ───────────────────────────────────────────────────────────────

class _MyRequestsTab extends StatelessWidget {
  const _MyRequestsTab();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUserModel;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medical_visits')
          .where('studentId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty)
          return const Center(child: Text('No requests yet'));

        final visits = docs.map((d) => d.data() as Map<String, dynamic>).toList()
          ..sort((a, b) {
            final ta = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            final tb = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            return tb.compareTo(ta);
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: visits.length,
          itemBuilder: (context, i) {
            final v = visits[i];
            final status = v['status'] ?? 'pending';
            final instruction = v['doctorInstruction'] ?? '';
            final appointmentTime = v['appointmentTime'] != null
                ? (v['appointmentTime'] as Timestamp).toDate()
                : null;
            final statusColor = status == 'completed'
                ? Colors.green
                : status == 'accepted' ? Colors.blue : Colors.orange;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(v['symptoms'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Chip(
                      label: Text(status.toUpperCase(),
                          style: const TextStyle(fontSize: 10)),
                      backgroundColor: statusColor.withOpacity(0.15),
                      side: BorderSide(color: statusColor.withOpacity(0.4)),
                    ),
                  ]),
                  Text('Urgency: ${v['urgency'] ?? 'normal'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  if (appointmentTime != null) ...[
                    const Divider(height: 16),
                    Row(children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        'Appointment: ${Helpers.formatDateTime(appointmentTime)}',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ],
                  if (instruction.isNotEmpty) ...[
                    const Divider(height: 16),
                    Row(children: [
                      const Icon(Icons.medical_services, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      const Text('Doctor\'s Instructions',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                    const SizedBox(height: 4),
                    Text(instruction, style: const TextStyle(fontSize: 13)),
                  ],
                ]),
              ),
            );
          },
        );
      },
    );
  }
}
