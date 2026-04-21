import 'package:flutter/material.dart';
import '../data/models.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
  });

  /// Appends the year to the dateRange string e.g. "Feb 2 – Feb 4, 2025"
  String get _dateWithYear {
    final year = trip.startDate.year.toString();
    // Avoid doubling the year if it's already in the string
    if (trip.dateRange.contains(year)) return trip.dateRange;
    if (trip.dateRange.isEmpty) return year;
    return '${trip.dateRange}, $year';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF162033),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or emoji fallback
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: trip.coverImageUrl != null
                  ? Image.network(
                trip.coverImageUrl!,
                width: 62,
                height: 62,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _EmojiCover(trip: trip),
              )
                  : _EmojiCover(trip: trip),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trip.location,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateWithYear,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.58),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C7C7).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trip.mood,
                      style: const TextStyle(
                        color: Color(0xFF7EE7E7),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiCover extends StatelessWidget {
  final Trip trip;
  const _EmojiCover({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFF22C7C7).withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child:
        Text(trip.coverEmoji, style: const TextStyle(fontSize: 30)),
      ),
    );
  }
}