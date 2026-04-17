import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../core/utils/helpers.dart';

class PostAnnouncementScreen extends StatefulWidget {
  const PostAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends State<PostAnnouncementScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _priority = 'normal';
  bool _posting = false;
  File? _image;

  Future<String?> _uploadImage(File file) async {
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 40,
        minWidth: 400,
        minHeight: 400,
      );
      final bytes = compressed ?? await file.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      Helpers.showSnackBar(context, 'Please fill in all fields', isError: true);
      return;
    }
    final user = context.read<AuthProvider>().currentUserModel;
    if (user == null) return;
    setState(() => _posting = true);
    try {
      String imageUrl = '';
      if (_image != null) imageUrl = await _uploadImage(_image!) ?? '';
      await context.read<AnnouncementProvider>().addAnnouncement(
            AnnouncementModel(
              id: '',
              postedBy: user.uid,
              postedByName: user.name,
              title: _titleCtrl.text.trim(),
              body: _bodyCtrl.text.trim(),
              priority: _priority,
              imageUrl: imageUrl,
              createdAt: DateTime.now(),
            ),
          );
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() { _priority = 'normal'; _image = null; });
      if (mounted) Helpers.showSnackBar(context, 'Announcement posted!');
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await context.read<AnnouncementProvider>().deleteAnnouncement(id);
      if (mounted) Helpers.showSnackBar(context, 'Announcement deleted');
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compose area
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1040),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34D399).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.campaign,
                        color: Color(0xFF34D399), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('New Announcement',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              _field(_titleCtrl, 'Title', Icons.title, maxLines: 1),
              const SizedBox(height: 12),
              _field(_bodyCtrl, 'Message body...', Icons.notes, maxLines: 4),
              const SizedBox(height: 16),
              // Image picker
              GestureDetector(
                onTap: () async {
                  if (_image != null) { setState(() => _image = null); return; }
                  final source = await showModalBottomSheet<ImageSource>(
                    context: context,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                    builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(height: 8),
                      const Text('Add Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
                      ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
                      const SizedBox(height: 8),
                    ])),
                  );
                  if (source == null) return;
                  final picked = await ImagePicker().pickImage(source: source, imageQuality: 70);
                  if (picked != null) setState(() => _image = File(picked.path));
                },
                child: Container(
                  height: _image != null ? 140 : 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _image != null ? const Color(0xFF34D399) : Colors.white.withOpacity(0.2)),
                  ),
                  child: _image != null
                      ? Stack(fit: StackFit.expand, children: [
                          ClipRRect(borderRadius: BorderRadius.circular(12), child: kIsWeb
                              ? Image.network(_image!.path, fit: BoxFit.cover)
                              : Image.file(_image!, fit: BoxFit.cover)),
                          Positioned(top: 6, right: 6, child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18))),
                        ])
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: Colors.white38),
                          const SizedBox(width: 8),
                          Text('Attach Image (optional)', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                        ]),
                ),
              ),
              const SizedBox(height: 16),
              // Priority selector
              Row(
                children: [
                  Text('Priority:',
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(width: 12),
                  ...[
                    ('normal', const Color(0xFF34D399)),
                    ('urgent', const Color(0xFFFBBF24)),
                    ('critical', const Color(0xFFFF4444)),
                  ].map((e) {
                    final selected = _priority == e.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _priority = e.$1),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? e.$2.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: selected
                                  ? e.$2
                                  : Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(e.$1,
                            style: GoogleFonts.inter(
                                color: selected ? e.$2 : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF059669)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _posting ? null : _post,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _posting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                    label: Text('Post Announcement',
                        style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Past announcements
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Posted Announcements',
                  style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<AnnouncementModel>>(
            stream: context
                .read<AnnouncementProvider>()
                .getAnnouncementsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF818CF8)));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Text('No announcements yet',
                      style: GoogleFonts.inter(color: Colors.white38)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final a = items[i];
                  final priorityColor = a.priority == 'critical'
                      ? const Color(0xFFFF4444)
                      : a.priority == 'urgent'
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF34D399);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1040),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: priorityColor.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(a.title,
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(a.priority,
                                        style: GoogleFonts.inter(
                                            color: priorityColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(a.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                      color: Colors.white60, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(Helpers.formatDateTime(a.createdAt),
                                  style: GoogleFonts.inter(
                                      color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white38, size: 20),
                          onPressed: () => _delete(a.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF0F0A2A),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: Colors.white54, size: 20)
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF34D399), width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
