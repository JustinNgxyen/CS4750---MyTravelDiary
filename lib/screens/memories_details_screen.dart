import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/firestore_service.dart';
import 'edit_memory_screen.dart';

class MemoryDetailScreen extends StatefulWidget {
  final Memory memory;
  const MemoryDetailScreen({super.key, required this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  late Memory _memory;
  bool _deleting = false;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _memory = widget.memory;
  }

  Future<void> _deleteMemory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete memory?'),
        content: Text(
          'This will permanently delete "${_memory.title}" and any photos or videos. This cannot be undone.',
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
      // Pass mediaUrl so Storage file gets deleted too
      await _firestoreService.deleteMemory(
        _memory.id,
        mediaUrl: _memory.mediaUrl,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete memory.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  // ── Media header ─────────────────────────────────
                  _memory.mediaUrl != null
                      ? GestureDetector(
                    onTap: () => _showFullscreen(
                        context, _memory.mediaUrl!),
                    child: Image.network(
                      _memory.mediaUrl!,
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 320,
                          color: const Color(0xFF162033),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF22C7C7)),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) =>
                          _emojiFallback(_memory),
                    ),
                  )
                      : _emojiFallback(_memory),

                  // ── Back / Edit / Delete buttons ─────────────────
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
                            icon:
                            const Icon(Icons.arrow_back_ios_new),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black45),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () async {
                                  final updated =
                                  await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditMemoryScreen(
                                          memory: _memory),
                                    ),
                                  );
                                  if (updated == true && mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined),
                                style: IconButton.styleFrom(
                                    backgroundColor: Colors.black45),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed:
                                _deleting ? null : _deleteMemory,
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                style: IconButton.styleFrom(
                                    backgroundColor: Colors.black45),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_memory.mediaUrl != null)
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen,
                                size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Tap to expand',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // ── Content ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _memory.title,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_memory.emoji,
                            style: const TextStyle(fontSize: 32)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        _Chip(
                          icon: Icons.calendar_today_outlined,
                          label: _memory.dateLabel,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          icon: _memory.mediaType == 'video'
                              ? Icons.videocam_outlined
                              : Icons.photo_outlined,
                          label: _memory.mediaType.toUpperCase(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (_memory.note.isNotEmpty) ...[
                      const Text(
                        'Note',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF22C7C7)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF162033),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Text(
                          _memory.note,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ] else
                      Text(
                        'No note added for this memory.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 15),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),

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

  Widget _emojiFallback(Memory memory) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF22C7C7), Color(0xFF0F7C8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(memory.emoji,
            style: const TextStyle(fontSize: 100)),
      ),
    );
  }

  void _showFullscreen(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullscreenPhoto(url: url)),
    );
  }
}

class _FullscreenPhoto extends StatelessWidget {
  final String url;
  const _FullscreenPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF22C7C7)),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.black45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C7C7).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF22C7C7)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7EE7E7),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}