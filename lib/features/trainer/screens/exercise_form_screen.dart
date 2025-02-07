import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import 'package:image_picker/image_picker.dart';

class ExerciseFormScreen extends StatefulWidget {
  final Exercise? exercise;
  final Function(Exercise) onSave;

  const ExerciseFormScreen({
    Key? key,
    this.exercise,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ExerciseFormScreen> createState() => _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends State<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseService = ExerciseService();
  
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  String? _localVideoPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
    _setsController = TextEditingController(
      text: widget.exercise?.sets.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.camera);
    
    if (video != null) {
      setState(() {
        _localVideoPath = video.path;
      });
    }
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final exercise = await _exerciseService.createExercise(
        name: _nameController.text,
        sets: int.parse(_setsController.text),
        order: widget.exercise?.order ?? 0,
        localVideoPath: _localVideoPath,
      );

      widget.onSave(exercise);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise == null ? 'Add Exercise' : 'Edit Exercise'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                  TextFormField(
                    controller: _setsController,
                    decoration: const InputDecoration(
                      labelText: 'Number of Sets',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of sets';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 1) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: Text(_localVideoPath != null
                        ? 'Change Video'
                        : 'Record Exercise Video'),
                  ),
                  if (_localVideoPath != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Video recorded successfully!',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveExercise,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Exercise'),
                  ),
                ],
              ),
            ),
    );
  }
}
