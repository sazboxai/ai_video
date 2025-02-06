import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../models/exercise_ref.dart';
import 'exercise_service.dart';

class RoutineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExerciseService _exerciseService = ExerciseService();

  // Get all routines for a trainer
  Stream<List<Routine>> getTrainerRoutines(String trainerId) {
    return _firestore
        .collection('routines')
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Routine.fromJson({...doc.data(), 'routineId': doc.id}))
              .toList();
        });
  }

  // Get a single routine by ID with resolved exercises
  Future<Routine?> getRoutineById(String routineId) async {
    try {
      final doc = await _firestore.collection('routines').doc(routineId).get();
      if (!doc.exists) return null;
      return Routine.fromJson({...doc.data()!, 'routineId': doc.id});
    } catch (e) {
      throw 'Failed to get routine: $e';
    }
  }

  // Create a new routine
  Future<String> createRoutine(Routine routine) async {
    try {
      final docRef = await _firestore.collection('routines').add(routine.toJson());
      return docRef.id;
    } catch (e) {
      throw 'Failed to create routine: $e';
    }
  }

  // Update routine details
  Future<void> updateRoutine(Routine routine) async {
    try {
      await _firestore
          .collection('routines')
          .doc(routine.routineId)
          .update(routine.toJson());
    } catch (e) {
      throw 'Failed to update routine: $e';
    }
  }

  // Add exercise to routine
  Future<void> addExerciseToRoutine(String routineId, Exercise exercise, int order, int sets) async {
    try {
      final routine = await getRoutineById(routineId);
      if (routine == null) throw 'Routine not found';

      final exerciseRef = ExerciseRef(
        exerciseId: exercise.exerciseId,
        order: order,
        sets: sets,
      );

      final updatedRoutine = routine.copyWith(
        exerciseRefs: [...routine.exerciseRefs, exerciseRef],
      );

      await updateRoutine(updatedRoutine);
    } catch (e) {
      throw 'Failed to add exercise to routine: $e';
    }
  }

  // Remove exercise from routine
  Future<void> removeExerciseFromRoutine(String routineId, String exerciseId) async {
    try {
      final routine = await getRoutineById(routineId);
      if (routine == null) throw 'Routine not found';

      final updatedRoutine = routine.copyWith(
        exerciseRefs: routine.exerciseRefs
            .where((ref) => ref.exerciseId != exerciseId)
            .toList(),
      );

      await updateRoutine(updatedRoutine);
    } catch (e) {
      throw 'Failed to remove exercise from routine: $e';
    }
  }

  // Reorder exercises in routine
  Future<void> reorderExercises(String routineId, List<ExerciseRef> newOrder) async {
    try {
      final routine = await getRoutineById(routineId);
      if (routine == null) throw 'Routine not found';

      final updatedRoutine = routine.copyWith(exerciseRefs: newOrder);
      await updateRoutine(updatedRoutine);
    } catch (e) {
      throw 'Failed to reorder exercises: $e';
    }
  }

  // Delete routine
  Future<void> deleteRoutine(String routineId) async {
    try {
      await _firestore.collection('routines').doc(routineId).delete();
    } catch (e) {
      throw 'Failed to delete routine: $e';
    }
  }

  // Get exercises for a routine
  Future<List<Exercise>> getRoutineExercises(Routine routine) async {
    try {
      final exerciseIds = routine.exerciseRefs.map((ref) => ref.exerciseId).toList();
      return await _exerciseService.getExercisesByIds(exerciseIds);
    } catch (e) {
      throw 'Failed to get routine exercises: $e';
    }
  }

  // Update exercise sets
  Future<void> updateExerciseSets(
    String routineId,
    String exerciseId,
    int sets,
  ) async {
    final routine = await getRoutineById(routineId);
    if (routine == null) throw 'Routine not found';

    final updatedRefs = routine.exerciseRefs.map((ref) {
      if (ref.exerciseId == exerciseId) {
        return ExerciseRef(
          exerciseId: ref.exerciseId,
          order: ref.order,
          sets: sets,
        );
      }
      return ref;
    }).toList();

    await _firestore.collection('routines').doc(routineId).update({
      'exerciseRefs': updatedRefs.map((ref) => ref.toJson()).toList(),
    });
  }
}