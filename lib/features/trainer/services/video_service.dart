import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class VideoUploadResult {
  final String videoUrl;
  final String thumbnailUrl;

  VideoUploadResult({
    required this.videoUrl,
    required this.thumbnailUrl,
  });
}

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

  Future<VideoUploadResult> uploadVideo(String videoPath, String exerciseId) async {
    try {
      // Generate thumbnail
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );

      if (thumbnailPath == null) {
        throw 'Failed to generate thumbnail';
      }

      // Upload video
      final videoRef = _storage.ref()
          .child('exercise_videos')
          .child(exerciseId)
          .child('video.mp4');

      await videoRef.putFile(File(videoPath));
      final videoUrl = await videoRef.getDownloadURL();

      // Upload thumbnail
      final thumbnailRef = _storage.ref()
          .child('exercise_thumbnails')
          .child(exerciseId)
          .child('thumbnail.jpg');

      await thumbnailRef.putFile(File(thumbnailPath));
      final thumbnailUrl = await thumbnailRef.getDownloadURL();

      return VideoUploadResult(
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      throw 'Failed to upload video: $e';
    }
  }

  Future<void> deleteVideo(String exerciseId) async {
    try {
      // Delete video file
      final videoRef = _storage.ref()
          .child('exercise_videos')
          .child(exerciseId)
          .child('video.mp4');
      await videoRef.delete();

      // Delete thumbnail
      final thumbnailRef = _storage.ref()
          .child('exercise_thumbnails')
          .child(exerciseId)
          .child('thumbnail.jpg');
      await thumbnailRef.delete();
    } catch (e) {
      // If files don't exist, Firebase will throw an error
      // We can safely ignore this as it means the files are already deleted
      if (!e.toString().contains('object-not-found')) {
        throw 'Failed to delete video: $e';
      }
    }
  }
}