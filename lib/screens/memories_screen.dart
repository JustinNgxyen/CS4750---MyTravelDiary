import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/firestore_service.dart';
import '../widgets/memory_card.dart';
import 'add_memory_screen.dart';
import 'memories_details_screen.dart';

class MemoriesScreen extends StatelessWidget {
  final Trip trip;
  const MemoriesScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddMemoryScreen(trip: trip)),
        ),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: firestoreService.memoriesStream(trip.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final memories = [...(snapshot.data ?? [])]
            ..sort((a, b) => b.memoryDate.compareTo(a.memoryDate));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Trip header ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C7C7), Color(0xFF0F7C8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Text(trip.coverEmoji,
                        style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.title,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(trip.location,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            '${memories.length} memor${memories.length == 1 ? 'y' : 'ies'} saved',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text('Memory Timeline',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Container(
                  height: 3, width: 40, color: const Color(0xFF22C7C7)),
              const SizedBox(height: 12),

              // ── Empty state ──────────────────────────────────────
              if (memories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162033),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          size: 38, color: Color(0xFF22C7C7)),
                      const SizedBox(height: 10),
                      const Text('No memories yet',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(
                        'Start building your trip journal by adding your first memory.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.72)),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AddMemoryScreen(trip: trip)),
                        ),
                        child: const Text('Add Memory'),
                      ),
                    ],
                  ),
                ),

              // ── Memory list ──────────────────────────────────────
              ...memories.map(
                    (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MemoryCard(
                    memory: m,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MemoryDetailScreen(memory: m),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}