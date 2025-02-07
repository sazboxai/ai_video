import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import 'video_service.dart';

class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VideoService _videoService = VideoService();

  // Get all exercises for a trainer
  Stream<List<Exercise>> getTrainerExercises(String trainerId) {
    return _firestore
        .collection('exercises')
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Exercise.fromJson(doc.data()!))
              .toList();
        });
  }

  // Get a single exercise by ID
  Future<Exercise?> getExerciseById(String exerciseId) async {
    final doc = await _firestore.collection('exercises').doc(exerciseId).get();
    if (!doc.exists) return null;
    return Exercise.fromJson(doc.data()!);
  }

  // Get multiple exercises by IDs
  Future<List<Exercise>> getExercisesByIds(List<String> exerciseIds) async {
    try {
      if (exerciseIds.isEmpty) return [];
      
      final exercises = await Future.wait(
        exerciseIds.map((id) => getExerciseById(id))
      );
      
      return exercises.whereType<Exercise>().toList();
    } catch (e) {
      throw 'Failed to get exercises: $e';
    }
  }

  // Create a new exercise
  Future<ExerciseCreationResult> createExercise({
    required String name,
    required String trainerId,
    required String localVideoPath,
    List<String> equipment = const [],
    List<String> labels = const [],
  }) async {
    // Create a new document reference
    final exerciseRef = _firestore.collection('exercises').doc();
    final exerciseId = exerciseRef.id;

    print('[DEBUG] Uploading video for new exercise');
    final uploadResult = await _videoService.uploadVideo(localVideoPath, exerciseId);

    final exercise = Exercise(
      exerciseId: exerciseId,
      trainerId: trainerId,
      name: name,
      defaultSets: 3,
      videoUrl: uploadResult.videoUrl,
      thumbnailUrl: uploadResult.thumbnailUrl,
      equipment: equipment,
      labels: labels,
    );

    await exerciseRef.set(exercise.toJson());
    return ExerciseCreationResult(exercise: exercise, videoUrl: uploadResult.videoUrl);
  }

  // Update an exercise
  Future<void> updateExercise(Exercise exercise) async {
    await _firestore
        .collection('exercises')
        .doc(exercise.exerciseId)
        .update(exercise.toJson());
  }

  // Update exercise video
  Future<Exercise> updateExerciseVideo(
    Exercise exercise,
    String localVideoPath,
  ) async {
    print('[DEBUG] Uploading new video for exercise: ${exercise.exerciseId}');
    final uploadResult = await _videoService.uploadVideo(localVideoPath, exercise.exerciseId);

    final updatedExercise = exercise.copyWith(
      videoUrl: uploadResult.videoUrl,
      thumbnailUrl: uploadResult.thumbnailUrl,
      updatedAt: DateTime.now(),
    );

    await updateExercise(updatedExercise);
    return updatedExercise;
  }

  // Delete an exercise
  Future<void> deleteExercise(String exerciseId) async {
    try {
      // Delete video and thumbnail if they exist
      final exercise = await getExerciseById(exerciseId);
      if (exercise?.videoUrl != null) {
        await _videoService.deleteVideo(exerciseId);
      }

      // Delete exercise document
      await _firestore.collection('exercises').doc(exerciseId).delete();
    } catch (e) {
      throw 'Failed to delete exercise: $e';
    }
  }
}

class ExerciseCreationResult {
  final Exercise exercise;
  final String videoUrl;

  ExerciseCreationResult({
    required this.exercise,
    required this.videoUrl,
  });
}
