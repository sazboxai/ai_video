import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class VideoUploadResult {
  final String videoUrl;
  final String? thumbnailUrl;

  VideoUploadResult({
    required this.videoUrl,
    this.thumbnailUrl,
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
      final videoFile = File(videoPath);
      
      // Check if video exists
      if (!await videoFile.exists()) {
        throw 'Video file not found';
      }

      // Check video size (50MB limit)
      final videoSize = await videoFile.length();
      print('[DEBUG] Video size: ${(videoSize / 1024 / 1024).toStringAsFixed(2)}MB');
      
      if (videoSize > 50 * 1024 * 1024) {
        throw 'Video size exceeds 50MB limit';
      }

      // Upload video first - using path that matches storage rules
      final videoRef = _storage.ref()
          .child('exercise_videos')
          .child(exerciseId)
          .child('video.mp4');
      
      print('[DEBUG] Starting video upload to ${videoRef.fullPath}');

      try {
        // Simplified metadata
        final metadata = SettableMetadata(contentType: 'video/mp4');
        
        // Create a temporary file with a shorter path
        final tempDir = await getTemporaryDirectory();
        final tempVideoFile = File('${tempDir.path}/temp_video.mp4');
        await videoFile.copy(tempVideoFile.path);
        
        // Upload the temp file
        await videoRef.putFile(tempVideoFile, metadata);
        print('[DEBUG] Video upload completed');
        
        // Clean up temp file
        if (await tempVideoFile.exists()) {
          await tempVideoFile.delete();
        }
      } catch (e) {
        print('[ERROR] Video upload error: $e');
        if (e.toString().contains('storage/unauthorized')) {
          throw 'Unauthorized: Please check if you are logged in';
        } else {
          throw e.toString();
        }
      }

      final videoUrl = await videoRef.getDownloadURL();

      // Try to generate and upload thumbnail
      String? thumbnailUrl;
      try {
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: '${(await getTemporaryDirectory()).path}/thumb.jpg',
          imageFormat: ImageFormat.JPEG,
          quality: 75,
        );

        if (thumbnailPath != null) {
          final thumbnailRef = _storage.ref()
              .child('exercise_thumbnails')
              .child(exerciseId)
              .child('thumbnail.jpg');
              
          await thumbnailRef.putFile(
            File(thumbnailPath),
            SettableMetadata(contentType: 'image/jpeg'),
          );
          thumbnailUrl = await thumbnailRef.getDownloadURL();
          print('[DEBUG] Thumbnail uploaded successfully');
        }
      } catch (e) {
        print('[DEBUG] Thumbnail error (non-fatal): $e');
        // Continue without thumbnail
      }

      return VideoUploadResult(
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      print('[ERROR] Final error in uploadVideo: $e');
      throw e.toString();
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
      print('Error deleting video files: $e');
    }
  }
}