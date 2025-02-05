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

      final uploadTask = ref.putFile(
        File(videoPath),
        SettableMetadata(contentType: 'video/mp4'),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload video: $e';
    }
  }
} 