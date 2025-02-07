import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../services/routine_service.dart';
import '../services/video_service.dart';
import '../services/auth_service.dart';
import '../screens/video_editor_screen.dart';

class AddExerciseSheet extends StatefulWidget {
  final String routineId;
  final Function(Exercise) onExerciseAdded;
  final Exercise? exercise; // Exercise to edit, null for new exercise

  const AddExerciseSheet({
    Key? key,
    required this.routineId,
    required this.onExerciseAdded,
    this.exercise,
  }) : super(key: key);

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  final _nameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _exerciseService = ExerciseService();
  final _routineService = RoutineService();
  final _videoService = VideoService();
  final _authService = AuthService();
  
  String? _videoPath;
  bool _isUploading = false;
  String? _errorMessage;
  bool get _isEditing => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.exercise!.name;
      // Get current sets from routine
      _routineService.getRoutineById(widget.routineId).then((routine) {
        if (routine != null && mounted) {
          final ref = routine.exerciseRefs.firstWhere(
            (ref) => ref.exerciseId == widget.exercise!.exerciseId,
          );
          setState(() {
            _setsController.text = ref.sets.toString();
          });
        }
      });
    }
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show dialog to choose between camera and gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Choose video source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Record Video'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      
      if (source == null) return;
      
      final XFile? video = await picker.pickVideo(source: source);
      
      if (video != null) {
        // Show video editor screen
        if (!mounted) return;
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoEditorScreen(
              videoPath: video.path,
              onVideoEdited: (String editedPath) {
                setState(() {
                  _videoPath = editedPath;
                });
                Navigator.pop(context);
              },
            ),
          ),
        );

        if (result == null) {
          // User cancelled editing
          setState(() {
            _videoPath = video.path;
          });
        }
      }
    } catch (e) {
      print('Error picking video: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick video: $e')),
      );
    }
  }

  Future<void> _saveExercise() async {
    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter an exercise name');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name')),
      );
      return;
    }

    final sets = int.tryParse(_setsController.text);
    if (sets == null || sets <= 0) {
      setState(() => _errorMessage = 'Please enter a valid number of sets');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of sets')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Check authentication state
      await _authService.checkAuthState();
      
      // Get current user
      final user = _authService.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      final trainerId = user.uid;

      // Validate video if provided
      if (_videoPath != null) {
        print('[DEBUG] Validating video at path: $_videoPath');
        final videoFile = File(_videoPath!);
        
        if (!await videoFile.exists()) {
          throw 'Selected video file not found';
        }

        final videoSize = await videoFile.length();
        print('[DEBUG] Video size: ${(videoSize / 1024 / 1024).toStringAsFixed(2)}MB');
        
        if (videoSize > 50 * 1024 * 1024) {
          throw 'Video size must be less than 50MB';
        }
      }

      Exercise exercise;
      if (_isEditing) {
        print('[DEBUG] Updating existing exercise: ${widget.exercise!.exerciseId}');
        // Update existing exercise
        exercise = await _exerciseService.updateExercise(
          exerciseId: widget.exercise!.exerciseId,
          name: _nameController.text,
          defaultSets: sets,
          localVideoPath: _videoPath,
        );

        // Update sets in routine
        await _routineService.updateExerciseSets(
          widget.routineId,
          exercise.exerciseId,
          sets,
        );
      } else {
        print('[DEBUG] Creating new exercise');
        // Create new exercise
        exercise = await _exerciseService.createExercise(
          trainerId: trainerId,
          name: _nameController.text,
          defaultSets: sets,
          localVideoPath: _videoPath,
        );

        // Add exercise reference to the routine
        final routine = await _routineService.getRoutineById(widget.routineId);
        if (routine == null) {
          throw 'Routine not found';
        }
        
        final order = routine.exerciseRefs.length; // Add to end of list
        await _routineService.addExerciseToRoutine(
          widget.routineId,
          exercise,
          order,
          sets,
        );
      }

      if (mounted) {
        widget.onExerciseAdded(exercise);
        Navigator.pop(context);
      }
    } catch (e) {
      print('[ERROR] Error in _saveExercise: $e');
      final errorMessage = e.toString();
      String userMessage;
      
      if (errorMessage.contains('storage/unauthorized')) {
        userMessage = 'Please sign out and sign in again, then try uploading the video';
      } else if (errorMessage.contains('Failed to upload video')) {
        userMessage = 'Error uploading video. Please try again with a different video or check your internet connection.';
      } else if (errorMessage.contains('User not authenticated')) {
        userMessage = 'You need to be logged in to upload videos. Please sign in again.';
      } else {
        userMessage = 'Error saving exercise: $e';
      }

      setState(() => _errorMessage = userMessage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? 'Edit Exercise' : 'Add Exercise',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
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
            decoration: const InputDecoration(
              labelText: 'Number of Sets',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          if (!_isEditing || _videoPath != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : _pickVideo,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Record Video'),
                ),
                ElevatedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : _pickVideo,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ],
          if (_isEditing && _videoPath == null && widget.exercise!.videoUrl != null) ...[
            const SizedBox(height: 8),
            Text(
              'Current video will be kept',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ] else if (_videoPath != null) ...[
            const SizedBox(height: 8),
            Text(
              'New video selected',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isUploading ? null : _saveExercise,
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save Changes' : 'Add Exercise'),
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