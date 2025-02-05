import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VideoService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> recordVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 1),
    );
    return video?.path;
  }

  Future<String?> pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 1),
    );
    return video?.path;
  }

  Future<String> uploadVideo(String videoPath, String exerciseName, String trainerId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref()
          .child('exercise_videos')
          .child(trainerId)
          .child('${exerciseName}_$timestamp.mp4');

      // Set proper metadata for video streaming
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'Cache-Control': 'public, max-age=31536000',
        },
        cacheControl: 'public, max-age=31536000',
      );

      // Upload the file
      final uploadTask = ref.putFile(
        File(videoPath),
        metadata,
      );

      // Wait for upload to complete
      await uploadTask.whenComplete(() => null);

      // Get a download URL that supports range requests
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload video: $e';
    }
  }
} 