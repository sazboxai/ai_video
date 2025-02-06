import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/video_service.dart';

class EditExerciseSheet extends StatefulWidget {
  final Exercise exercise;
  final Function(Exercise) onUpdate;

  const EditExerciseSheet({
    super.key,
    required this.exercise,
    required this.onUpdate,
  });

  @override
  State<EditExerciseSheet> createState() => _EditExerciseSheetState();
}

class _EditExerciseSheetState extends State<EditExerciseSheet> {
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  final VideoService _videoService = VideoService();
  bool _isLoading = false;
  String? _videoPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _setsController = TextEditingController(text: widget.exercise.sets.toString());
  }

  Future<void> _pickVideo() async {
    final path = await _videoService.pickVideo();
    if (path != null) {
      setState(() => _videoPath = path);
    }
  }

  Future<void> _recordVideo() async {
    final path = await _videoService.recordVideo();
    if (path != null) {
      setState(() => _videoPath = path);
    }
  }

  Future<void> _updateExercise() async {
    if (_nameController.text.isEmpty || _setsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? videoUrl = widget.exercise.videoUrl;
      
      // Upload new video if selected
      if (_videoPath != null) {
        videoUrl = await _videoService.uploadVideo(
          _videoPath!,
          _nameController.text,
          'trainerId', // Get from AuthService
        );
      }

      final updatedExercise = widget.exercise.copyWith(
        name: _nameController.text,
        sets: int.parse(_setsController.text),
        videoUrl: videoUrl,
      );

      widget.onUpdate(updatedExercise);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Exercise Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _setsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of Sets',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
              ElevatedButton.icon(
                onPressed: _recordVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Record'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_videoPath != null)
            const Text('New video selected', style: TextStyle(color: Colors.green)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateExercise,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Update Exercise'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    super.dispose();
  }
} 