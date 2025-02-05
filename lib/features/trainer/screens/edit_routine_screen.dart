import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import '../widgets/exercise_card.dart';
import '../widgets/add_exercise_sheet.dart';

class EditRoutineScreen extends StatefulWidget {
  final Routine routine;

  const EditRoutineScreen({
    super.key,
    required this.routine,
  });

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<Exercise> _exercises;
  bool _isLoading = false;
  final _routineService = RoutineService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.routine.title);
    _descriptionController = TextEditingController(text: widget.routine.description);
    _exercises = List.from(widget.routine.exercises);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final exercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddExerciseSheet(),
    );

    if (exercise != null) {
      setState(() {
        _exercises.add(exercise);
      });
    }
  }

  Future<void> _saveRoutine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedRoutine = Routine(
        id: widget.routine.id,
        trainerId: widget.routine.trainerId,
        title: _titleController.text,
        description: _descriptionController.text,
        exercises: _exercises,
        viewCount: widget.routine.viewCount,
        likeCount: widget.routine.likeCount,
        createdAt: widget.routine.createdAt,
        updatedAt: DateTime.now(),
      );

      await _routineService.updateRoutine(updatedRoutine);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Routine'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveRoutine,
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Exercises',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return ExerciseCard(
                  key: ValueKey(exercise.hashCode),
                  exercise: exercise,
                  onDelete: () {
                    setState(() {
                      _exercises.removeAt(index);
                    });
                  },
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _exercises.removeAt(oldIndex);
                  _exercises.insert(newIndex, item);
                  
                  // Update order numbers
                  for (var i = 0; i < _exercises.length; i++) {
                    final exercise = _exercises[i];
                    _exercises[i] = Exercise(
                      name: exercise.name,
                      sets: exercise.sets,
                      videoUrl: exercise.videoUrl,
                      videoPath: exercise.videoPath,
                      order: i,
                    );
                  }
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
    );
  }
} 