import 'dart:io';
import 'package:flutter/material.dart';
import 'package:imgly_editor/imgly_editor.dart';
import 'package:imgly_editor/model/editor_settings.dart';
import 'package:imgly_editor/model/source.dart';
import 'package:imgly_editor/model/editor_result.dart';
import 'package:imgly_editor/model/editor_preset.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class VideoEditorScreen extends StatelessWidget {
  final File videoFile;
  final Function(String) onVideoEdited;

  const VideoEditorScreen({
    Key? key,
    required this.videoFile,
    required this.onVideoEdited,
  }) : super(key: key);

  Future<String> _getExportPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return path.join(directory.path, 'edited_video_$timestamp.mp4');
  }

  String _normalizeFilePath(String filePath) {
    // Remove 'file://' prefix if present
    if (filePath.startsWith('file://')) {
      return filePath.substring(7);
    }
    return filePath;
  }

  Future<void> _openEditor(BuildContext context) async {
    try {
      // Get the SDK license key from environment
      final sdkKey = dotenv.env['VESDK_LICENSE_KEY'];
      if (sdkKey == null) {
        throw Exception('CE.SDK license key not found');
      }

      // Get export path
      final exportPath = await _getExportPath();
      print('Export path: $exportPath');

      // Create editor settings with license
      final settings = EditorSettings(
        license: sdkKey,
        assetBaseUri: 'assets/editor_assets',
        sceneBaseUri: 'assets/editor_assets',
      );

      // Create source from video path
      final source = Source.fromVideo(videoFile.path);

      // Open the editor
      final result = await IMGLYEditor.openEditor(
        source: source,
        settings: settings,
        preset: EditorPreset.video,
        metadata: {
          'export': {
            'video': {
              'filepath': exportPath,
              'format': 'mp4',
              'quality': 'high',
            }
          }
        },
      );

      if (result != null && result.artifact != null) {
        final normalizedArtifactPath = _normalizeFilePath(result.artifact!);
        print('Video edited successfully. Normalized path: $normalizedArtifactPath');
        
        // Copy the edited video to the original path
        final editedFile = File(normalizedArtifactPath);
        
        if (await editedFile.exists()) {
          print('Found edited video at: $normalizedArtifactPath');
          await videoFile.writeAsBytes(await editedFile.readAsBytes());
          print('Copied edited video to original path: ${videoFile.path}');
          
          // Handle the edited video using the original path
          onVideoEdited(videoFile.path);
        } else {
          print('Edited video file not found at: $normalizedArtifactPath');
          throw Exception('Edited video file not found');
        }
      } else {
        print('No result or artifact returned from editor');
        throw Exception('No result from editor');
      }
    } catch (error) {
      print('Error opening video editor: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open video editor: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Video'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ready to edit your video',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openEditor(context),
              child: const Text('Start Editing'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Return the original video file without editing
                onVideoEdited(videoFile.path);
              },
              child: const Text('Use Original'),
            ),
          ],
        ),
      ),
    );
  }
}
