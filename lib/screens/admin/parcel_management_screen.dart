import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/parcel_model.dart';
import '../../providers/parcel_provider.dart';
import '../../core/utils/helpers.dart';

class ParcelManagementScreen extends StatefulWidget {
  const ParcelManagementScreen({Key? key}) : super(key: key);

  @override
  State<ParcelManagementScreen> createState() => _ParcelManagementScreenState();
}

class _ParcelManagementScreenState extends State<ParcelManagementScreen> {
  String _filter = 'all';

  void _showAddSheet() {
    final senderCtrl  = TextEditingController();
    final trackCtrl   = TextEditingController();
    String? selectedStudentId;
    String? selectedStudentName;
    String? selectedRoom;
    String? selectedCourier;
    XFile? pickedImage;
    bool uploading = false;

    const couriers = ['FedEx', 'DHL', 'UPS', 'DTDC', 'BlueDart', 'India Post', 'Amazon', 'Flipkart', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1040),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFFBBF24), size: 20),
                ),
                const SizedBox(width: 10),
                Text('Log New Parcel',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .snapshots(),
                builder: (ctx, snap) {
                  final students = snap.data?.docs ?? [];
                  return _dropdown<String>(
                    value: selectedStudentId,
                    hint: 'Select Student *',
                    items: students.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text('${d['name']} — Room ${d['roomNumber']}',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      final doc = students.firstWhere((d) => d.id == val);
                      final d = doc.data() as Map<String, dynamic>;
                      setModal(() {
                        selectedStudentId   = val;
                        selectedStudentName = d['name'];
                        selectedRoom        = d['roomNumber'];
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(senderCtrl, 'Sender Name')),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown<String>(
                    value: selectedCourier,
                    hint: 'Courier',
                    items: couriers.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                    )).toList(),
                    onChanged: (val) => setModal(() => selectedCourier = val),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _field(trackCtrl, 'Tracking Number'),
              const SizedBox(height: 12),
              // Photo picker
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(
                      source: ImageSource.camera, imageQuality: 75);
                  if (picked != null) setModal(() => pickedImage = picked);
                },
                child: Container(
                  height: pickedImage != null ? 160 : 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0A2A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.network(pickedImage!.path, fit: BoxFit.cover, width: double.infinity)
                              : Image.file(File(pickedImage!.path), fit: BoxFit.cover, width: double.infinity))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 20),
                          const SizedBox(width: 8),
                          Text('Take Parcel Photo (optional)',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                        ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: uploading ? null : () async {
                      if (selectedStudentName == null) {
                        Helpers.showSnackBar(context, 'Please select a student', isError: true);
                        return;
                      }
                      setModal(() => uploading = true);
                      try {
                        String imageUrl = '';
                        if (pickedImage != null) {
                          final compressed = await FlutterImageCompress.compressWithFile(
                            File(pickedImage!.path).absolute.path,
                            quality: 40,
                            minWidth: 400,
                            minHeight: 400,
                          );
                          final bytes = compressed ?? await File(pickedImage!.path).readAsBytes();
                          imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                        }
                        await context.read<ParcelProvider>().addParcel(ParcelModel(
                          id: '',
                          studentId: selectedStudentId ?? '',
                          studentName: selectedStudentName!,
                          roomNumber: selectedRoom ?? '',
                          senderName: senderCtrl.text.trim(),
                          courierName: selectedCourier ?? '',
                          trackingNumber: trackCtrl.text.trim(),
                          status: 'arrived',
                          imageUrl: imageUrl,
                          arrivedAt: DateTime.now(),
                        ));
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          Helpers.showSnackBar(context, 'Parcel logged successfully');
                        }
                      } catch (e) {
                        if (ctx.mounted) Helpers.showSnackBar(context, e.toString(), isError: true);
                      } finally {
                        setModal(() => uploading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: uploading
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.add, color: Colors.white),
                    label: Text(uploading ? 'Uploading...' : 'Log Parcel',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF1A1040),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0F0A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFBBF24), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextFormField(
      controller: ctrl,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0F0A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFBBF24), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter + FAB row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            _FilterChip('All',       'all',       const Color(0xFFFBBF24), _filter, (v) => setState(() => _filter = v)),
            const SizedBox(width: 8),
            _FilterChip('Arrived',   'arrived',   const Color(0xFF60A5FA), _filter, (v) => setState(() => _filter = v)),
            const SizedBox(width: 8),
            _FilterChip('Collected', 'collected', const Color(0xFF34D399), _filter, (v) => setState(() => _filter = v)),
            const Spacer(),
            GestureDetector(
              onTap: _showAddSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('Log', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<ParcelModel>>(
            stream: context.read<ParcelProvider>().getAllParcels(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFBBF24)));
              }
              var parcels = snapshot.data ?? [];
              if (_filter != 'all') parcels = parcels.where((p) => p.status == _filter).toList();

              if (parcels.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 52),
                    const SizedBox(height: 12),
                    Text('No parcels found', style: GoogleFonts.inter(color: Colors.white38)),
                  ]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: parcels.length,
                itemBuilder: (context, i) {
                  final p = parcels[i];
                  final isArrived = p.status == 'arrived';
                  final statusColor = isArrived ? const Color(0xFF60A5FA) : const Color(0xFF34D399);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1040),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFFBBF24), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.studentName,
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                            Text('Room ${p.roomNumber}',
                                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                          ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.4)),
                          ),
                          child: Text(p.status,
                              style: GoogleFonts.inter(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.local_shipping_outlined, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text('${p.courierName.isEmpty ? 'Unknown courier' : p.courierName}',
                            style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                        if (p.trackingNumber.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text('· ${p.trackingNumber}',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.access_time, color: Colors.white38, size: 13),
                        const SizedBox(width: 4),
                        Text('Arrived: ${Helpers.formatDateTime(p.arrivedAt)}',
                            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                        if (p.collectedAt != null) ...[
                          const SizedBox(width: 8),
                          Text('· Collected: ${Helpers.formatDate(p.collectedAt!)}',
                              style: GoogleFonts.inter(color: const Color(0xFF34D399), fontSize: 11)),
                        ],
                      ]),
                      if (isArrived) ...[
                        const SizedBox(height: 12),
                        if (p.imageUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: p.imageUrl.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(p.imageUrl.split(',').last),
                                    height: 140, width: double.infinity, fit: BoxFit.cover)
                                : Image.network(p.imageUrl,
                                    height: 140, width: double.infinity, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await context.read<ParcelProvider>().markAsCollected(p.id);
                              if (context.mounted) Helpers.showSnackBar(context, 'Marked as collected');
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: const Color(0xFF34D399).withOpacity(0.6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check, color: Color(0xFF34D399), size: 16),
                            label: Text('Mark as Collected',
                                style: GoogleFonts.inter(color: const Color(0xFF34D399),
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, value, selected;
  final Color color;
  final ValueChanged<String> onTap;
  const _FilterChip(this.label, this.value, this.color, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.white.withOpacity(0.2)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: active ? color : Colors.white54,
                fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
