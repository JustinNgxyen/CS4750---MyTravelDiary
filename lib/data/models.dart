import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
// Trip model
// ─────────────────────────────────────────
class Trip {
  final String id;
  final String userId;
  final String title;
  final String location;
  final String dateRange;  // computed display string e.g. "Feb 2 – Feb 4"
  final String mood;
  final String coverEmoji;
  final String coverLabel;
  final DateTime startDate;
  final DateTime? endDate;
  final String? coverImageUrl;
  final String? notes;

  const Trip({
    required this.id,
    required this.userId,
    required this.title,
    required this.location,
    required this.dateRange,
    required this.mood,
    required this.coverEmoji,
    required this.coverLabel,
    required this.startDate,
    this.endDate,
    this.coverImageUrl,
    this.notes,
  });

  factory Trip.fromMap(String id, Map<String, dynamic> map) {
    return Trip(
      id: id,
      userId: map['userId'] as String,
      title: map['title'] as String,
      location: map['location'] as String,
      dateRange: map['dateRange'] as String,
      mood: map['mood'] as String,
      coverEmoji: map['coverEmoji'] as String,
      coverLabel: map['coverLabel'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      coverImageUrl: map['coverImageUrl'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'location': location,
      'dateRange': dateRange,
      'mood': mood,
      'coverEmoji': coverEmoji,
      'coverLabel': coverLabel,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (notes != null) 'notes': notes,
    };
  }
}

// ─────────────────────────────────────────
// Memory model
// ─────────────────────────────────────────
class Memory {
  final String id;
  final String userId;
  final String tripId;
  final String title;
  final DateTime memoryDate;
  final String note;
  final String mediaType;
  final String emoji;
  final String? mediaUrl;

  const Memory({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.title,
    required this.memoryDate,
    required this.note,
    required this.mediaType,
    required this.emoji,
    this.mediaUrl,
  });

  /// Consistent display string e.g. "Aug 13, 2025"
  String get dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[memoryDate.month - 1]} ${memoryDate.day}, ${memoryDate.year}';
  }

  factory Memory.fromMap(String id, Map<String, dynamic> map) {
    DateTime date;
    if (map['memoryDate'] != null) {
      date = (map['memoryDate'] as Timestamp).toDate();
    } else {
      date = DateTime.now();
    }
    return Memory(
      id: id,
      userId: map['userId'] as String? ?? '',
      tripId: map['tripId'] as String,
      title: map['title'] as String,
      memoryDate: date,
      note: map['note'] as String,
      mediaType: map['mediaType'] as String,
      emoji: map['emoji'] as String,
      mediaUrl: map['mediaUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tripId': tripId,
      'title': title,
      'memoryDate': Timestamp.fromDate(memoryDate),
      'note': note,
      'mediaType': mediaType,
      'emoji': emoji,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };
  }
}