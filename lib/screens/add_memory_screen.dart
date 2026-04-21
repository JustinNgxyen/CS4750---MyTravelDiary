import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class AddMemoryScreen extends StatefulWidget {
  final Trip trip;
  const AddMemoryScreen({super.key, required this.trip});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  String title = '';
  DateTime memoryDate = DateTime.now();
  String note = '';
  String mediaType = 'photo';
  String emoji = '📸';
  bool _isLoading = false;
  XFile? _pickedFile;

  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: memoryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF22C7C7),
            surface: Color(0xFF162033),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => memoryDate = picked);
  }

  Future<void> _pickMedia() async {
    final file = mediaType == 'video'
        ? await _storageService.pickVideo()
        : await _storageService.pickPhoto();
    if (file != null) setState(() => _pickedFile = file);
  }

  Future<void> _saveMemory() async {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final memory = Memory(
        id: '',
        userId: uid,
        tripId: widget.trip.id,
        title: title.trim(),
        memoryDate: memoryDate,
        note: note.trim(),
        mediaType: mediaType,
        emoji: emoji,
      );

      final memoryId = await _firestoreService.addMemory(memory);

      if (_pickedFile != null) {
        final url = await _storageService.uploadMemoryMedia(
          tripId: widget.trip.id,
          memoryId: memoryId,
          file: _pickedFile!,
        );
        await _firestoreService.updateMemory(Memory(
          id: memoryId,
          userId: uid,
          tripId: widget.trip.id,
          title: title.trim(),
          memoryDate: memoryDate,
          note: note.trim(),
          mediaType: mediaType,
          emoji: emoji,
          mediaUrl: url,
        ));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save memory. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Memory')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Trip: ${widget.trip.title}',
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),
          const SizedBox(height: 12),

          TextField(
            decoration: const InputDecoration(labelText: 'Title'),
            onChanged: (v) => setState(() => title = v),
          ),
          const SizedBox(height: 12),

          // ── Date picker ────────────────────────────────────────
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF162033),
                borderRadius: BorderRadius.circular(18),
                border:
                Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: Color(0xFF22C7C7)),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(memoryDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      color: Colors.white.withOpacity(0.4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Note'),
            onChanged: (v) => setState(() => note = v),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: mediaType,
            items: const [
              DropdownMenuItem(value: 'photo', child: Text('Photo')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
            ],
            onChanged: (v) => setState(() {
              mediaType = v ?? 'photo';
              emoji = mediaType == 'video' ? '🎥' : '📸';
              _pickedFile = null;
            }),
            decoration: const InputDecoration(labelText: 'Media type'),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: _isLoading ? null : _pickMedia,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pickedFile != null
                          ? _pickedFile!.name
                          : 'Tap to pick a ${mediaType == 'video' ? 'video' : 'photo'}',
                      style: TextStyle(
                        color: _pickedFile != null
                            ? Colors.white
                            : Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ),
                  Icon(
                    _pickedFile != null
                        ? Icons.check_circle_outline
                        : Icons.upload,
                    color: _pickedFile != null
                        ? const Color(0xFF22C7C7)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _saveMemory,
              child: _isLoading
                  ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}