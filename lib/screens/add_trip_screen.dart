import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  String title = '';
  String location = '';
  String mood = 'Adventure';
  String coverEmoji = '🧳';
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  XFile? _coverImageFile;
  bool _isLoading = false;

  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  // ── Date helpers ─────────────────────────────────────────────────

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  String get _dateRangeLabel {
    if (endDate == null) return _fmt(startDate);
    if (startDate.year == endDate!.year &&
        startDate.month == endDate!.month &&
        startDate.day == endDate!.day) {
      return _fmt(startDate);
    }
    return '${_fmt(startDate)} – ${_fmt(endDate!)}';
  }

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: startDate,
        end: endDate ?? startDate,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF22C7C7),
            surface: Color(0xFF162033),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() {
        startDate = range.start;
        endDate = range.end;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final file = await _storageService.pickPhoto();
    if (file != null) setState(() => _coverImageFile = file);
  }

  Future<void> _saveTrip() async {
    if (title.trim().isEmpty || location.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a title and location.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final trip = Trip(
        id: '',
        userId: uid,
        title: title.trim(),
        location: location.trim(),
        dateRange: _dateRangeLabel,
        mood: mood,
        coverEmoji: coverEmoji,
        coverLabel: location.trim(),
        startDate: startDate,
        endDate: endDate,
      );

      final tripId = await _firestoreService.addTrip(trip);

      if (_coverImageFile != null) {
        final url = await _storageService.uploadTripCover(
          tripId: tripId,
          file: _coverImageFile!,
        );
        await _firestoreService.updateTrip(Trip(
          id: tripId,
          userId: uid,
          title: title.trim(),
          location: location.trim(),
          dateRange: _dateRangeLabel,
          mood: mood,
          coverEmoji: coverEmoji,
          coverLabel: location.trim(),
          startDate: startDate,
          endDate: endDate,
          coverImageUrl: url,
        ));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save trip. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moods = ['Adventure', 'Relaxed', 'City', 'Food', 'Roadtrip'];
    final emojis = ['🧳', '🏞️', '🌊', '🏙️', '🍜', '🚗', '⛰️', '🌴'];

    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Cover preview ────────────────────────────────────────
          GestureDetector(
            onTap: _pickCoverImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _coverImageFile != null
                  ? Image.file(
                File(_coverImageFile!.path),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C7C7), Color(0xFF0F7C8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(coverEmoji,
                      style: const TextStyle(fontSize: 64)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: _pickCoverImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(_coverImageFile != null
                ? 'Change Cover Image'
                : 'Add Cover Image'),
          ),
          const SizedBox(height: 16),

          TextField(
            decoration: const InputDecoration(labelText: 'Trip title'),
            onChanged: (v) => setState(() => title = v),
          ),
          const SizedBox(height: 12),

          TextField(
            decoration: const InputDecoration(labelText: 'Location'),
            onChanged: (v) => setState(() => location = v),
          ),
          const SizedBox(height: 12),

          // ── Date range picker ────────────────────────────────────
          GestureDetector(
            onTap: _pickDates,
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
                  const Icon(Icons.date_range_outlined,
                      size: 18, color: Color(0xFF22C7C7)),
                  const SizedBox(width: 12),
                  Text(
                    _dateRangeLabel,
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

          DropdownButtonFormField<String>(
            value: mood,
            items: moods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => mood = v ?? 'Adventure'),
            decoration: const InputDecoration(labelText: 'Mood'),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: coverEmoji,
            items: emojis
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => coverEmoji = v ?? '🧳'),
            decoration: const InputDecoration(labelText: 'Cover emoji'),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _saveTrip,
              child: _isLoading
                  ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Text('Save Trip'),
            ),
          ),
        ],
      ),
    );
  }
}