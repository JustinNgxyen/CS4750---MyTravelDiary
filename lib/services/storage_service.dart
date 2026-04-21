import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Pick from device ─────────────────────────────────────────────
  Future<XFile?> pickPhoto() =>
      _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

  Future<XFile?> pickVideo() =>
      _picker.pickVideo(source: ImageSource.gallery);

  // ── Upload trip cover ────────────────────────────────────────────
  Future<String> uploadTripCover({
    required String tripId,
    required XFile file,
  }) async {
    final ext = file.path.split('.').last;
    final ref = _storage
        .ref()
        .child('users/$_uid/trips/$tripId/cover.$ext');
    final task = await ref.putFile(File(file.path));
    return await task.ref.getDownloadURL();
  }

  /// Deletes ALL files under a trip's folder in Storage.
  /// Call this when deleting a trip.
  Future<void> deleteTripStorage(String tripId) async {
    try {
      final tripRef =
      _storage.ref().child('users/$_uid/trips/$tripId');
      await _deleteFolder(tripRef);
    } catch (_) {
      // If folder doesn't exist or already deleted, ignore
    }
  }

  // ── Upload memory media ──────────────────────────────────────────
  Future<String> uploadMemoryMedia({
    required String tripId,
    required String memoryId,
    required XFile file,
  }) async {
    final ext = file.path.split('.').last;
    final ref = _storage
        .ref()
        .child('users/$_uid/trips/$tripId/memories/$memoryId.$ext');
    final task = await ref.putFile(File(file.path));
    return await task.ref.getDownloadURL();
  }

  /// Deletes the media file for a specific memory.
  /// Call this when deleting a memory.
  /// Pass the mediaUrl from the Memory object so we can get the exact ref.
  Future<void> deleteMemoryMedia({required String mediaUrl}) async {
    try {
      final ref = _storage.refFromURL(mediaUrl);
      await ref.delete();
    } catch (_) {
      // File may not exist — ignore
    }
  }

  // ── Helper: recursively delete all files in a Storage folder ────
  Future<void> _deleteFolder(Reference folderRef) async {
    final result = await folderRef.listAll();
    // Delete all files in this folder
    for (final item in result.items) {
      await item.delete();
    }
    // Recurse into subfolders
    for (final prefix in result.prefixes) {
      await _deleteFolder(prefix);
    }
  }
}