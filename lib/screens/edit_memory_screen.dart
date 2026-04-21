import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EditMemoryScreen extends StatefulWidget {
  final Memory memory;
  const EditMemoryScreen({super.key, required this.memory});

  @override
  State<EditMemoryScreen> createState() => _EditMemoryScreenState();
}

class _EditMemoryScreenState extends State<EditMemoryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late DateTime _memoryDate;
  late String _mediaType;
  late String _emoji;
  XFile? _newMediaFile;
  bool _isLoading = false;

  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.memory.title);
    _noteController =
        TextEditingController(text: widget.memory.note);
    _memoryDate = widget.memory.memoryDate;
    _mediaType = widget.memory.mediaType;
    _emoji = widget.memory.emoji;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _memoryDate,
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
    if (picked != null) setState(() => _memoryDate = picked);
  }

  Future<void> _pickMedia() async {
    final file = _mediaType == 'video'
        ? await _storageService.pickVideo()
        : await _storageService.pickPhoto();
    if (file != null) setState(() => _newMediaFile = file);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String? mediaUrl = widget.memory.mediaUrl;

      // Upload new media if one was picked
      if (_newMediaFile != null) {
        mediaUrl = await _storageService.uploadMemoryMedia(
          tripId: widget.memory.tripId,
          memoryId: widget.memory.id,
          file: _newMediaFile!,
        );
      }

      await _firestoreService.updateMemory(Memory(
        id: widget.memory.id,
        userId: uid,
        tripId: widget.memory.tripId,
        title: _titleController.text.trim(),
        memoryDate: _memoryDate,
        note: _noteController.text.trim(),
        mediaType: _mediaType,
        emoji: _emoji,
        mediaUrl: mediaUrl,
      ));

      if (mounted) Navigator.pop(context, true); // true = was updated
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save changes. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current media preview — new local file takes priority over existing URL
    final hasNewFile = _newMediaFile != null;
    final hasExistingUrl = widget.memory.mediaUrl != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Memory'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Media preview ──────────────────────────────────────
          GestureDetector(
            onTap: _pickMedia,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: hasNewFile
                  ? Image.file(
                File(_newMediaFile!.path),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : hasExistingUrl
                  ? Image.network(
                widget.memory.mediaUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _emojiPlaceholder(),
              )
                  : _emojiPlaceholder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickMedia,
            icon: const Icon(Icons.image_outlined),
            label: Text(hasNewFile || hasExistingUrl
                ? 'Change Photo / Video'
                : 'Add Photo / Video'),
          ),

          const SizedBox(height: 16),

          // ── Title ──────────────────────────────────────────────
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
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
                  Text(_formatDate(_memoryDate),
                      style: const TextStyle(fontSize: 16)),
                  const Spacer(),
                  Icon(Icons.chevron_right,
                      color: Colors.white.withOpacity(0.4)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Note ───────────────────────────────────────────────
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          const SizedBox(height: 12),

          // ── Media type ─────────────────────────────────────────
          DropdownButtonFormField<String>(
            value: _mediaType,
            items: const [
              DropdownMenuItem(value: 'photo', child: Text('Photo')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
            ],
            onChanged: (v) => setState(() {
              _mediaType = v ?? 'photo';
              _emoji = _mediaType == 'video' ? '🎥' : '📸';
            }),
            decoration: const InputDecoration(labelText: 'Media type'),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _emojiPlaceholder() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF22C7C7), Color(0xFF0F7C8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(_emoji, style: const TextStyle(fontSize: 72)),
      ),
    );
  }
}