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
  Future<Exercise> createExercise({
    required String trainerId,
    required String name,
    required int defaultSets,
    String? localVideoPath,
  }) async {
    try {
      // Create exercise document first
      final exerciseId = _firestore.collection('exercises').doc().id;
      String? videoUrl;
      String? thumbnailUrl;

      // Upload video if provided
      if (localVideoPath != null) {
        final uploadResult = await _videoService.uploadVideo(
          localVideoPath,
          exerciseId,
        );
        videoUrl = uploadResult.videoUrl;
        thumbnailUrl = uploadResult.thumbnailUrl;
      }

      // Create exercise
      final exercise = Exercise(
        exerciseId: exerciseId,
        trainerId: trainerId,
        name: name,
        defaultSets: defaultSets,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
      );

      // Save to Firestore
      await _firestore
          .collection('exercises')
          .doc(exerciseId)
          .set(exercise.toJson());

      return exercise;
    } catch (e) {
      throw 'Failed to create exercise: $e';
    }
  }

  // Update exercise details
  Future<Exercise> updateExercise({
    required String exerciseId,
    required String name,
    required int defaultSets,
    String? localVideoPath,
  }) async {
    // Get existing exercise
    final existingExercise = await getExerciseById(exerciseId);
    if (existingExercise == null) {
      throw 'Exercise not found';
    }

    String? videoUrl = existingExercise.videoUrl;
    String? thumbnailUrl = existingExercise.thumbnailUrl;

    // Upload new video if provided
    if (localVideoPath != null) {
      // Delete old video and thumbnail if they exist
      if (existingExercise.videoUrl != null) {
        await _videoService.deleteVideo(exerciseId);
      }

      // Upload new video
      final uploadResult = await _videoService.uploadVideo(
        localVideoPath,
        exerciseId,
      );
      videoUrl = uploadResult.videoUrl;
      thumbnailUrl = uploadResult.thumbnailUrl;
    }

    // Update exercise
    final exercise = Exercise(
      exerciseId: exerciseId,
      trainerId: existingExercise.trainerId,
      name: name,
      defaultSets: defaultSets,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
    );

    // Save to Firestore
    await _firestore
        .collection('exercises')
        .doc(exerciseId)
        .update(exercise.toJson());

    return exercise;
  }

  // Update exercise video
  Future<Exercise> updateExerciseVideo(
    Exercise exercise,
    String localVideoPath,
  ) async {
    try {
      // Delete old video if it exists
      if (exercise.videoUrl != null) {
        await _videoService.deleteVideo(exercise.exerciseId);
      }

      // Upload new video
      final uploadResult = await _videoService.uploadVideo(
        localVideoPath,
        exercise.exerciseId,
      );

      // Update exercise with new video URLs
      final updatedExercise = exercise.copyWith(
        videoUrl: uploadResult.videoUrl,
        thumbnailUrl: uploadResult.thumbnailUrl,
      );

      // Save to Firestore
      await updateExercise(
        exerciseId: updatedExercise.exerciseId,
        name: updatedExercise.name,
        defaultSets: updatedExercise.defaultSets,
      );
      
      return updatedExercise;
    } catch (e) {
      throw 'Failed to update exercise video: $e';
    }
  }

  // Delete exercise and its video
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
