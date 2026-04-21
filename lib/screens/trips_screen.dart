import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/firestore_service.dart';
import '../widgets/trip_card.dart';
import 'trips_details_screen.dart';
import 'add_trip_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Trips')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTripScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Trip>>(
        stream: firestoreService.tripsStream(),
        builder: (context, tripsSnapshot) {
          if (tripsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (tripsSnapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }

          final trips = tripsSnapshot.data ?? [];
          final tripIds = trips.map((t) => t.id).toList();
          final recentTrips = trips.take(5).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
            const Text(
            'Travel Journal',
            style:
            TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
          'Track the places you have been and the memories you made.',
          style: TextStyle(
          color: Colors.white.withOpacity(0.72), fontSize: 15),
          ),
          const SizedBox(height: 18),

          // ── Snapshot card ──────────────────────────────────
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
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
          'Your Travel Snapshot',
          style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
          'A quick look at your trips and saved memories.',
          style: TextStyle(
          color: Colors.white.withOpacity(0.85)),
          ),
          const SizedBox(height: 18),
          Row(
          children: [
          Expanded(
          child: _StatBox(
          label: 'Trips',
          value: trips.length.toString(),
          ),
          ),
          const SizedBox(width: 10),
          Expanded(
          child: StreamBuilder<int>(
          stream: firestoreService
              .totalMemoriesCountStream(tripIds),
          builder: (context, memSnapshot) {
          final count = memSnapshot.data ?? 0;
          return _StatBox(
          label: 'Memories',
          value: count.toString(),
          );
          },
          ),
          ),
          const SizedBox(width: 10),
          ],
          ),
          ],
          ),
          ),

          const SizedBox(height: 22),

          const Text(
          'Recent Trips',
          style:
          TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Container(
          height: 3, width: 40, color: const Color(0xFF22C7C7)),
          const SizedBox(height: 12),

          if (trips.isEmpty)
          Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Center(
          child: Text(
          'No trips yet — tap + to add your first!',
          style: TextStyle(
          color: Colors.white.withOpacity(0.5)),
          ),
          ),
          )
          else
          ...recentTrips.map(
          (t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TripCard(
          trip: t,
          onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
          builder: (_) => TripDetailsScreen(trip: t),
          ),
          ),
          ),
          ),
          ),
          ],
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.8), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}