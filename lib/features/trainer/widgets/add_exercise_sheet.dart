import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../services/routine_service.dart';
import '../services/video_service.dart';
import '../services/auth_service.dart';

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

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: source);
      if (video != null) {
        setState(() {
          _videoPath = video.path;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error picking video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
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
      // Get current trainer ID
      final trainerId = _authService.currentUser?.uid;
      if (trainerId == null) {
        throw 'User not authenticated';
      }

      Exercise exercise;
      if (_isEditing) {
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
      setState(() => _errorMessage = 'Error saving exercise: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving exercise: $e')),
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
                      : () => _pickVideo(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: _isUploading
                      ? null
                      : () => _pickVideo(ImageSource.gallery),
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