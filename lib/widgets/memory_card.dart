import 'package:flutter/material.dart';
import '../data/models.dart';

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final VoidCallback onTap;

  const MemoryCard({
    super.key,
    required this.memory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = memory.mediaType == 'video' ? Icons.videocam : Icons.photo;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Center(
                child: Text(memory.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(memory.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '${memory.dateLabel} • ${memory.mediaType.toUpperCase()}',
                    style: TextStyle(color: Colors.white.withOpacity(0.75)),
                  ),
                ],
              ),
            ),
            Icon(icon),
          ],
        ),
      ),
    );
  }
}