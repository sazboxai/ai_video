import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';

class RoutineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all routines for a trainer
  Stream<List<Routine>> getTrainerRoutines(String trainerId) {
    return _firestore
        .collection('routines')
        .where('trainerId', isEqualTo: trainerId)
        // Remove orderBy until index is created
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Routine.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Create a new routine
  Future<String> createRoutine(Routine routine) async {
    try {
      final docRef = await _firestore.collection('routines').add(routine.toMap());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create routine: $e';
    }
  }

  // Delete a routine
  Future<void> deleteRoutine(String routineId) async {
    try {
      await _firestore.collection('routines').doc(routineId).delete();
    } catch (e) {
      throw 'Failed to delete routine: $e';
    }
  }

  // Update a routine
  Future<void> updateRoutine(Routine routine) async {
    try {
      await _firestore.collection('routines').doc(routine.id).update(routine.toMap());
    } catch (e) {
      throw 'Failed to update routine: $e';
    }
  }
} 