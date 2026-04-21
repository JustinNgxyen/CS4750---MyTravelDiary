import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../widgets/memory_card.dart';
import 'memories_screen.dart';
import 'add_memory_screen.dart';
import 'memories_details_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  late TextEditingController _notesController;
  bool _editingNotes = false;
  bool _savingNotes = false;
  bool _uploadingCover = false;
  bool _deleting = false;
  String? _localCoverPath;

  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.trip.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Returns dateRange with year appended e.g. "Feb 2 – Feb 4, 2025"
  String get _dateWithYear {
    final year = widget.trip.startDate.year.toString();
    if (widget.trip.dateRange.contains(year)) return widget.trip.dateRange;
    if (widget.trip.dateRange.isEmpty) return year;
    return '${widget.trip.dateRange}, $year';
  }

  Future<void> _changeCoverImage() async {
    final file = await _storageService.pickPhoto();
    if (file == null) return;
    setState(() {
      _localCoverPath = file.path;
      _uploadingCover = true;
    });
    try {
      final url = await _storageService.uploadTripCover(
        tripId: widget.trip.id,
        file: file,
      );
      await _firestoreService.updateTrip(Trip(
        id: widget.trip.id,
        userId: widget.trip.userId,
        title: widget.trip.title,
        location: widget.trip.location,
        dateRange: widget.trip.dateRange,
        mood: widget.trip.mood,
        coverEmoji: widget.trip.coverEmoji,
        coverLabel: widget.trip.coverLabel,
        startDate: widget.trip.startDate,
        endDate: widget.trip.endDate,
        coverImageUrl: url,
        notes: widget.trip.notes,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover image updated!')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _localCoverPath = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update cover image.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _savingNotes = true);
    try {
      await _firestoreService.updateTrip(Trip(
        id: widget.trip.id,
        userId: widget.trip.userId,
        title: widget.trip.title,
        location: widget.trip.location,
        dateRange: widget.trip.dateRange,
        mood: widget.trip.mood,
        coverEmoji: widget.trip.coverEmoji,
        coverLabel: widget.trip.coverLabel,
        startDate: widget.trip.startDate,
        endDate: widget.trip.endDate,
        coverImageUrl: widget.trip.coverImageUrl,
        notes: _notesController.text.trim(),
      ));
      if (mounted) setState(() => _editingNotes = false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save notes.')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNotes = false);
    }
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text(
          'This will permanently delete "${widget.trip.title}" and all its memories. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await _firestoreService.deleteTrip(widget.trip.id);
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete trip.')),
        );
      }
    }
  }

  Widget _buildCoverHeader() {
    final trip = widget.trip;
    Widget coverWidget;
    if (_localCoverPath != null) {
      coverWidget = Image.file(File(_localCoverPath!),
          height: 280, width: double.infinity, fit: BoxFit.cover);
    } else if (trip.coverImageUrl != null) {
      coverWidget = Image.network(trip.coverImageUrl!,
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiCover(trip));
    } else {
      coverWidget = _emojiCover(trip);
    }

    return Stack(
      children: [
        SizedBox(height: 280, width: double.infinity, child: coverWidget),
        if (_uploadingCover)
          Container(
            height: 280,
            color: Colors.black45,
            child: const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ),
        Positioned(
          bottom: 52,
          right: 16,
          child: GestureDetector(
            onTap: _uploadingCover ? null : _changeCoverImage,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Edit cover',
                      style:
                      TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emojiCover(Trip trip) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF22C7C7), Color(0xFF0F7C8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
          child: Text(trip.coverEmoji,
              style: const TextStyle(fontSize: 90))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  _buildCoverHeader(),

                  // Back + delete buttons
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black38),
                          ),
                          IconButton(
                            onPressed: _deleting ? null : _deleteTrip,
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black38),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content card
                  Container(
                    margin: const EdgeInsets.only(top: 240),
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B1220),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.title,
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(trip.location,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.78))),
                        const SizedBox(height: 4),
                        // ── Date with year ─────────────────────
                        Text(
                          _dateWithYear,
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 12),

                        // Chips
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C7C7)
                                    .withOpacity(0.14),
                                borderRadius:
                                BorderRadius.circular(999),
                              ),
                              child: Text(trip.mood,
                                  style: const TextStyle(
                                      color: Color(0xFF7EE7E7),
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius:
                                BorderRadius.circular(999),
                              ),
                              child: Text(trip.coverLabel,
                                  style: TextStyle(
                                      color:
                                      Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            MemoriesScreen(trip: trip))),
                                child: const Text('View Memories'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            AddMemoryScreen(trip: trip))),
                                child: const Text('Add Memory'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Trip summary
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Trip Summary',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                            if (!_editingNotes)
                              IconButton(
                                onPressed: () => setState(
                                        () => _editingNotes = true),
                                icon: const Icon(Icons.edit_outlined,
                                    size: 20),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                            height: 3,
                            width: 40,
                            color: const Color(0xFF22C7C7)),
                        const SizedBox(height: 12),

                        if (_editingNotes)
                          Column(
                            children: [
                              TextField(
                                controller: _notesController,
                                maxLines: 5,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText:
                                  'What made this trip memorable?',
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(
                                            () => _editingNotes = false),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: _savingNotes
                                        ? null
                                        : _saveNotes,
                                    child: _savingNotes
                                        ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child:
                                        CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                        : const Text('Save'),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF162033),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color:
                                  Colors.white.withOpacity(0.06)),
                            ),
                            child: Text(
                              _notesController.text.isNotEmpty
                                  ? _notesController.text
                                  : 'Tap the edit icon to add a trip summary.',
                              style: TextStyle(
                                height: 1.5,
                                color: _notesController.text.isNotEmpty
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Preview memories
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Preview Memories',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                            TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          MemoriesScreen(trip: trip))),
                              child: const Text('See all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                            height: 3,
                            width: 40,
                            color: const Color(0xFF22C7C7)),
                        const SizedBox(height: 12),

                        StreamBuilder(
                          stream: _firestoreService
                              .memoriesStream(trip.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final memories = [
                              ...(snapshot.data ?? [])
                            ]..sort((a, b) =>
                                b.memoryDate.compareTo(a.memoryDate));

                            if (memories.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF162033),
                                  borderRadius:
                                  BorderRadius.circular(22),
                                  border: Border.all(
                                      color: Colors.white
                                          .withOpacity(0.06)),
                                ),
                                child: Text(
                                  'No memories yet. Add your first one.',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.75)),
                                ),
                              );
                            }
                            return Column(
                              children: memories
                                  .take(2)
                                  .map((m) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 10),
                                child: MemoryCard(
                                  memory: m,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MemoryDetailScreen(
                                              memory: m),
                                    ),
                                  ),
                                ),
                              ))
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Loading overlay while deleting
          if (_deleting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}