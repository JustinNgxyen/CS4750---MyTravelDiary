import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models.dart';
import 'storage_service.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _storageService = StorageService();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');

  CollectionReference<Map<String, dynamic>> get _memories =>
      _db.collection('memories');

  // ─────────────────────────────────────────
  // TRIPS
  // ─────────────────────────────────────────

  Stream<List<Trip>> tripsStream() {
    return _trips
        .where('userId', isEqualTo: _uid)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Trip.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<String> addTrip(Trip trip) async {
    final ref = await _trips.add(trip.toMap());
    return ref.id;
  }

  Future<void> updateTrip(Trip trip) async {
    await _trips.doc(trip.id).update(trip.toMap());
  }

  /// Deletes a trip, all its memory documents, all their Storage
  /// media files, and the trip's own Storage folder.
  Future<void> deleteTrip(String tripId) async {
    // 1. Fetch all memories for this trip
    final memoriesSnap = await _memories
        .where('userId', isEqualTo: _uid)
        .where('tripId', isEqualTo: tripId)
        .get();

    // 2. Delete each memory's Storage file if it has one
    for (final doc in memoriesSnap.docs) {
      final mediaUrl = doc.data()['mediaUrl'] as String?;
      if (mediaUrl != null) {
        await _storageService.deleteMemoryMedia(mediaUrl: mediaUrl);
      }
    }

    // 3. Delete all memory documents in a batch
    final batch = _db.batch();
    for (final doc in memoriesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_trips.doc(tripId));
    await batch.commit();

    // 4. Delete the entire trip Storage folder
    //    (covers cover image + any leftover files)
    await _storageService.deleteTripStorage(tripId);
  }

  // ─────────────────────────────────────────
  // MEMORIES
  // ─────────────────────────────────────────

  Stream<List<Memory>> memoriesStream(String tripId) {
    return _memories
        .where('userId', isEqualTo: _uid)
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Memory.fromMap(doc.id, doc.data()))
        .toList());
  }

  Stream<List<Memory>> allMemoriesStream() {
    return _memories
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => Memory.fromMap(doc.id, doc.data()))
        .toList());
  }

  Stream<int> totalMemoriesCountStream(List<String> tripIds) {
    if (tripIds.isEmpty) return Stream.value(0);
    return _memories
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs
        .where((doc) => tripIds.contains(doc.data()['tripId']))
        .length);
  }

  Future<String> addMemory(Memory memory) async {
    final ref = await _memories.add(memory.toMap());
    return ref.id;
  }

  Future<void> updateMemory(Memory memory) async {
    await _memories.doc(memory.id).update(memory.toMap());
  }

  /// Deletes a memory document and its associated Storage file.
  Future<void> deleteMemory(String memoryId, {String? mediaUrl}) async {
    // Delete Storage file first if there is one
    if (mediaUrl != null) {
      await _storageService.deleteMemoryMedia(mediaUrl: mediaUrl);
    }
    await _memories.doc(memoryId).delete();
  }
}