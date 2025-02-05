import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/video_service.dart';
import '../services/auth_service.dart';

class AddExerciseSheet extends StatefulWidget {
  const AddExerciseSheet({super.key});

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _videoService = VideoService();
  final _authService = AuthService();
  int _sets = 3;
  String? _videoPath;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _recordVideo() async {
    final videoPath = await _videoService.recordVideo();
    if (videoPath != null) {
      setState(() => _videoPath = videoPath);
    }
  }

  Future<void> _pickVideo() async {
    final videoPath = await _videoService.pickVideo();
    if (videoPath != null) {
      setState(() => _videoPath = videoPath);
    }
  }

  Future<void> _addExercise() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isUploading = true);
    
    try {
      String? videoUrl;
      if (_videoPath != null) {
        videoUrl = await _videoService.uploadVideo(
          _videoPath!,
          _nameController.text,
          _authService.currentUser!.uid,
        );
      }

      final exercise = Exercise(
        name: _nameController.text,
        sets: _sets,
        videoUrl: videoUrl,
        videoPath: _videoPath,
        order: 0, // Will be set when added to the list
      );
      
      Navigator.pop(context, exercise);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Exercise',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an exercise name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Sets:'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    if (_sets > 1) {
                      setState(() => _sets--);
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text('$_sets'),
                IconButton(
                  onPressed: () {
                    setState(() => _sets++);
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _recordVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record'),
                ),
                ElevatedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            if (_videoPath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Video selected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : _addExercise,
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Exercise'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 