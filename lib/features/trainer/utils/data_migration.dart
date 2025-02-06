import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../models/exercise_ref.dart';

class DataMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateToExerciseCollection() async {
    try {
      // Get all routines
      final routinesSnapshot = await _firestore.collection('routines').get();
      
      // For each routine
      for (final routineDoc in routinesSnapshot.docs) {
        final oldData = routineDoc.data();
        final exercises = (oldData['exercises'] as List<dynamic>?)?.map(
          (e) => Exercise.fromJson(e as Map<String, dynamic>)
        ).toList() ?? [];

        // Create exercise refs
        final exerciseRefs = <ExerciseRef>[];
        
        // For each exercise in the routine
        for (var i = 0; i < exercises.length; i++) {
          final exercise = exercises[i];
          
          // Create new exercise document
          await _firestore.collection('exercises').doc(exercise.exerciseId).set({
            ...exercise.toJson(),
            'trainerId': oldData['trainerId'],
            'defaultSets': exercise.defaultSets,
          });

          // Create exercise ref
          exerciseRefs.add(ExerciseRef(
            exerciseId: exercise.exerciseId,
            order: i,
            sets: exercise.defaultSets,
          ));
        }

        // Update routine with exercise refs
        await routineDoc.reference.update({
          'exercises': FieldValue.delete(),
          'exerciseRefs': exerciseRefs.map((ref) => ref.toJson()).toList(),
        });
      }

      print('Migration completed successfully!');
    } catch (e) {
      print('Error during migration: $e');
      rethrow;
    }
  }

  Future<void> rollbackMigration() async {
    try {
      // Delete all exercises
      final exercisesSnapshot = await _firestore.collection('exercises').get();
      for (final doc in exercisesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Remove exerciseRefs from routines
      final routinesSnapshot = await _firestore.collection('routines').get();
      for (final doc in routinesSnapshot.docs) {
        await doc.reference.update({
          'exerciseRefs': FieldValue.delete(),
        });
      }

      print('Rollback completed successfully!');
    } catch (e) {
      print('Error during rollback: $e');
      rethrow;
    }
  }
}
