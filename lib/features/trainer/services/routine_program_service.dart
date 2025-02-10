import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/routine_program.dart';

class RoutineProgramService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new routine program
  Future<RoutineProgram> createRoutineProgram({
    required String name,
    required String description,
    required List<String> equipment,
    required String outline,
    required String locationId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    final now = DateTime.now();
    
    // Create the routine program document
    final docRef = await _firestore.collection('routinePrograms').add({
      'name': name,
      'description': description,
      'equipment': equipment,
      'outline': outline,
      'trainerId': user.uid,
      'locationId': locationId,
      'createdAt': now,
      'updatedAt': now,
    });

    // Add the routine program ID to the location
    await _firestore.collection('locations').doc(locationId).update({
      'routineProgramIds': FieldValue.arrayUnion([docRef.id]),
      'updatedAt': now,
    });

    // Return the created routine program
    return RoutineProgram(
      id: docRef.id,
      trainerId: user.uid,
      name: name,
      description: description,
      equipment: equipment,
      outline: outline,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Get a routine program by ID
  Future<RoutineProgram?> getRoutineProgram(String id) async {
    final doc = await _firestore.collection('routinePrograms').doc(id).get();
    if (!doc.exists) return null;
    return RoutineProgram.fromMap(doc.data()!, doc.id);
  }

  // Get all routine programs for a location
  Future<List<RoutineProgram>> getRoutineProgramsForLocation(String locationId) async {
    final snapshot = await _firestore
        .collection('routinePrograms')
        .where('locationId', isEqualTo: locationId)
        .get();

    return snapshot.docs
        .map((doc) => RoutineProgram.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Update a routine program
  Future<void> updateRoutineProgram({
    required String id,
    String? name,
    String? description,
    List<String>? equipment,
    String? outline,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    final updates = <String, dynamic>{
      'updatedAt': DateTime.now(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (equipment != null) updates['equipment'] = equipment;
    if (outline != null) updates['outline'] = outline;

    await _firestore.collection('routinePrograms').doc(id).update(updates);
  }

  // Delete a routine program
  Future<void> deleteRoutineProgram(String id) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    await _firestore.collection('routinePrograms').doc(id).delete();
  }
}
