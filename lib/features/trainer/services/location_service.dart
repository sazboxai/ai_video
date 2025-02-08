import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/location.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all locations for a trainer
  Stream<List<Location>> getTrainerLocations(String trainerId) {
    return _firestore
        .collection('locations')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Location.fromJson(doc.data()))
            .toList());
  }

  // Get a single location by ID
  Future<Location?> getLocationById(String locationId) async {
    final doc = await _firestore.collection('locations').doc(locationId).get();
    if (doc.exists) {
      return Location.fromJson(doc.data()!);
    }
    return null;
  }

  // Create a new location
  Future<Location> createLocation({
    required String trainerId,
    required String name,
    List<String> equipment = const [],
    List<String> photoUrls = const [],
  }) async {
    final docRef = _firestore.collection('locations').doc();
    final location = Location(
      locationId: docRef.id,
      trainerId: trainerId,
      name: name,
      equipment: equipment,
      photoUrls: photoUrls,
      routinePrograms: const [],
    );

    await docRef.set(location.toJson());
    return location;
  }

  // Update an existing location
  Future<void> updateLocation({
    required String locationId,
    required String name,
    required List<String> equipment,
    required List<String> photoUrls,
    required List<RoutineProgram> routinePrograms,
  }) async {
    await _firestore.collection('locations').doc(locationId).update({
      'name': name,
      'equipment': equipment,
      'photoUrls': photoUrls,
      'routinePrograms': routinePrograms.map((p) => p.toJson()).toList(),
    });
  }

  // Delete a location
  Future<void> deleteLocation(String locationId) async {
    // Delete all photos from storage first
    final location = await getLocationById(locationId);
    if (location != null) {
      for (final photoUrl in location.photoUrls) {
        try {
          await _storage.refFromURL(photoUrl).delete();
        } catch (e) {
          print('Error deleting photo: $e');
        }
      }
    }

    // Delete the location document
    await _firestore.collection('locations').doc(locationId).delete();
  }

  // Upload a photo for a location
  Future<String> uploadLocationPhoto(String locationId, File photoFile) async {
    final ref = _storage
        .ref()
        .child('location_photos')
        .child(locationId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = await ref.putFile(
      photoFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final photoUrl = await uploadTask.ref.getDownloadURL();

    // Add the photo URL to the location's photoUrls array
    await _firestore.collection('locations').doc(locationId).update({
      'photoUrls': FieldValue.arrayUnion([photoUrl]),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return photoUrl;
  }

  // Delete a photo from a location
  Future<void> deleteLocationPhoto(String locationId, String photoUrl) async {
    // Delete from storage
    await _storage.refFromURL(photoUrl).delete();

    // Remove from location document
    await _firestore.collection('locations').doc(locationId).update({
      'photoUrls': FieldValue.arrayRemove([photoUrl]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Add a routine program to a location
  Future<void> addRoutineProgram(
    String locationId,
    String title,
    String markdownContent,
  ) async {
    final program = RoutineProgram(
      programId: _firestore.collection('locations').doc().id,
      title: title,
      markdownContent: markdownContent,
    );

    await _firestore.collection('locations').doc(locationId).update({
      'routinePrograms': FieldValue.arrayUnion([program.toJson()]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update a routine program
  Future<void> updateRoutineProgram(
    String locationId,
    RoutineProgram program,
  ) async {
    final location = await getLocationById(locationId);
    if (location == null) return;

    final updatedPrograms = location.routinePrograms.map((p) {
      if (p.programId == program.programId) {
        return program;
      }
      return p;
    }).toList();

    await _firestore.collection('locations').doc(locationId).update({
      'routinePrograms': updatedPrograms.map((p) => p.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Delete a routine program
  Future<void> deleteRoutineProgram(
    String locationId,
    String programId,
  ) async {
    final location = await getLocationById(locationId);
    if (location == null) return;

    final updatedPrograms = location.routinePrograms
        .where((p) => p.programId != programId)
        .toList();

    await _firestore.collection('locations').doc(locationId).update({
      'routinePrograms': updatedPrograms.map((p) => p.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
