import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../services/routine_service.dart';
import '../services/video_service.dart';
import '../services/auth_service.dart';
import '../screens/video_editor_screen.dart';
import '../utils/exercise_constants.dart';

class AddExerciseSheet extends StatefulWidget {
  final String routineId;
  final Function(Exercise) onExerciseAdded;
  final Exercise? exercise;

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

  // New controllers for equipment and labels
  final _equipmentController = TextEditingController();
  final _labelController = TextEditingController();
  List<String> _selectedEquipment = [];
  List<String> _selectedLabels = [];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.exercise!.name;
      _selectedEquipment = List.from(widget.exercise!.equipment);
      _selectedLabels = List.from(widget.exercise!.labels);
      
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

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _equipmentController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _addEquipment(String equipment) {
    if (!_selectedEquipment.contains(equipment)) {
      setState(() {
        _selectedEquipment.add(equipment);
        _equipmentController.clear();
      });
    }
  }

  void _removeEquipment(String equipment) {
    setState(() {
      _selectedEquipment.remove(equipment);
    });
  }

  void _addLabel(String label) {
    if (!_selectedLabels.contains(label)) {
      setState(() {
        _selectedLabels.add(label);
        _labelController.clear();
      });
    }
  }

  void _removeLabel(String label) {
    setState(() {
      _selectedLabels.remove(label);
    });
  }

  Future<void> _showVideoSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Video Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1), // Optional: limit video duration
      );

      if (pickedFile != null) {
        final videoFile = File(pickedFile.path);
        
        // Navigate to video editor
        final editedVideoPath = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => VideoEditorScreen(
              videoFile: videoFile,
              onVideoEdited: (path) {
                Navigator.pop(context, path);
              },
            ),
          ),
        );

        if (editedVideoPath != null && mounted) {
          setState(() {
            _videoPath = editedVideoPath;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      print('Error picking video: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to pick video: $e';
        });
      }
    }
  }

  Future<void> _saveExercise() async {
    final name = _nameController.text.trim();
    final setsText = _setsController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter an exercise name');
      return;
    }

    final sets = int.tryParse(setsText);
    if (sets == null || sets <= 0) {
      setState(() => _errorMessage = 'Please enter a valid number of sets');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isUploading = true;
    });

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        throw 'User not authenticated';
      }

      Exercise exercise;
      if (_isEditing) {
        // Update existing exercise
        exercise = widget.exercise!.copyWith(
          name: name,
          equipment: _selectedEquipment,
          labels: _selectedLabels,
          updatedAt: DateTime.now(),
        );
        
        if (_videoPath != null) {
          exercise = await _exerciseService.updateExerciseVideo(
            exercise,
            _videoPath!,
          );
        }
        
        await _exerciseService.updateExercise(exercise);
        
        // Update sets in routine
        await _routineService.updateExerciseSets(
          widget.routineId,
          exercise.exerciseId,
          sets,
        );
      } else {
        // Create new exercise
        if (_videoPath == null) {
          throw 'Please select a video';
        }

        final result = await _exerciseService.createExercise(
          name: name,
          trainerId: userId,
          localVideoPath: _videoPath!,
          equipment: _selectedEquipment,
          labels: _selectedLabels,
        );

        exercise = result.exercise;

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
      child: SingleChildScrollView(
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
            
            // Equipment Section
            Text(
              'Equipment (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return ExerciseConstants.predefinedEquipment;
                }
                return ExerciseConstants.predefinedEquipment.where((equipment) =>
                    equipment.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: _addEquipment,
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                _equipmentController.text = textEditingController.text;
                return TextField(
                  controller: _equipmentController,
                  focusNode: focusNode,
                  onChanged: (value) => textEditingController.text = value,
                  decoration: InputDecoration(
                    labelText: 'Add Equipment',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_equipmentController.text.isNotEmpty) {
                          _addEquipment(_equipmentController.text);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            if (_selectedEquipment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _selectedEquipment.map((equipment) {
                  return Chip(
                    label: Text(equipment),
                    onDeleted: () => _removeEquipment(equipment),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            
            // Labels Section
            Text(
              'Labels (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return ExerciseConstants.predefinedLabels;
                }
                return ExerciseConstants.predefinedLabels.where((label) =>
                    label.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: _addLabel,
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                _labelController.text = textEditingController.text;
                return TextField(
                  controller: _labelController,
                  focusNode: focusNode,
                  onChanged: (value) => textEditingController.text = value,
                  decoration: InputDecoration(
                    labelText: 'Add Label',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_labelController.text.isNotEmpty) {
                          _addLabel(_labelController.text);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            if (_selectedLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _selectedLabels.map((label) {
                  return Chip(
                    label: Text(label),
                    onDeleted: () => _removeLabel(label),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            Center(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _showVideoSourceDialog,
                icon: const Icon(Icons.video_call),
                label: const Text('Add Video'),
              ),
            ),
            if (_videoPath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Video selected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (_isEditing && _videoPath == null && widget.exercise!.videoUrl != null) ...[
              const SizedBox(height: 8),
              Text(
                'Current video will be kept',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : _saveExercise,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : Text(_isEditing ? 'Update Exercise' : 'Add Exercise'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}