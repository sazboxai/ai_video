import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise_ref.dart';
import '../services/routine_service.dart';
import '../services/auth_service.dart';
import '../widgets/add_exercise_sheet.dart';

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({Key? key}) : super(key: key);

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _routineService = RoutineService();
  final _authService = AuthService();
  
  String _difficulty = 'Beginner';
  bool _isCreating = false;

  Future<void> _showAddExerciseSheet(String routineId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddExerciseSheet(
        routineId: routineId,
        onExerciseAdded: (exercise) {
          // Removed setState(() => _exercises.add(exercise));
        },
      ),
    );
  }

  Future<void> _createRoutine() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a routine title')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final trainerId = _authService.currentUser?.uid;
      if (trainerId == null) throw 'User not authenticated';

      // Create routine first
      final routine = Routine(
        routineId: DateTime.now().millisecondsSinceEpoch.toString(),
        trainerId: trainerId,
        title: _titleController.text,
        description: _descriptionController.text,
        difficulty: _difficulty,
        exerciseRefs: [], // Start with empty list
      );

      // Save routine and get its ID
      final routineId = await _routineService.createRoutine(routine);

      // Show bottom sheet to add first exercise
      if (mounted) {
        await _showAddExerciseSheet(routineId);
      }

      // Navigate back after creating routine
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating routine: $e')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Routine'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Routine Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
              ),
              items: ['Beginner', 'Intermediate', 'Advanced']
                  .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _difficulty = value);
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _createRoutine,
              child: _isCreating
                  ? const CircularProgressIndicator()
                  : const Text('Create Routine'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}