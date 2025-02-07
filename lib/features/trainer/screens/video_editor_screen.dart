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
  final String videoPath;
  final Function(String) onVideoEdited;

  const VideoEditorScreen({
    Key? key,
    required this.videoPath,
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
      final source = Source.fromVideo(videoPath);

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
        final originalFile = File(videoPath);
        
        if (await editedFile.exists()) {
          print('Found edited video at: $normalizedArtifactPath');
          await originalFile.writeAsBytes(await editedFile.readAsBytes());
          print('Copied edited video to original path: ${originalFile.path}');
          
          // Handle the edited video using the original path
          onVideoEdited(originalFile.path);
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
        title: const Text('Edit Video'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ready to edit your video',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openEditor(context),
              child: const Text('Start Editing'),
            ),
          ],
        ),
      ),
    );
  }
}
