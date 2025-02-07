import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../models/exercise_ref.dart';
import '../services/routine_service.dart';
import '../services/exercise_service.dart';
import '../widgets/add_exercise_sheet.dart';
import '../widgets/exercise_card.dart';

class EditRoutineScreen extends StatefulWidget {
  final String routineId;

  const EditRoutineScreen({
    Key? key,
    required this.routineId,
  }) : super(key: key);

  @override
  State<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends State<EditRoutineScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _routineService = RoutineService();
  final _exerciseService = ExerciseService();

  Routine? _routine;
  Map<String, Exercise> _exercises = {}; // Map exerciseId to Exercise
  String _difficulty = 'Beginner';
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  Future<void> _loadRoutine() async {
    setState(() => _isLoading = true);
    try {
      final routine = await _routineService.getRoutineById(widget.routineId);
      if (routine == null) throw 'Routine not found';

      // Load exercises
      final exercises = await _routineService.getRoutineExercises(routine);
      final exerciseMap = {for (var e in exercises) e.exerciseId: e};

      setState(() {
        _routine = routine;
        _exercises = exerciseMap;
        _difficulty = routine.difficulty;
        _titleController.text = routine.title;
        _descriptionController.text = routine.description;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading routine: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddExerciseSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddExerciseSheet(
        routineId: widget.routineId,
        onExerciseAdded: (exercise) async {
          // Reload the entire routine to get updated exerciseRefs
          await _loadRoutine();
        },
      ),
    );
  }

  Future<void> _saveRoutine() async {
    if (_routine == null) return;
    
    setState(() => _isSaving = true);
    try {
      final updatedRoutine = _routine!.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        difficulty: _difficulty,
      );

      await _routineService.updateRoutine(updatedRoutine);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving routine: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    try {
      await _routineService.removeExerciseFromRoutine(
        widget.routineId,
        exercise.exerciseId,
      );

      setState(() {
        _exercises.remove(exercise.exerciseId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing exercise: $e')),
      );
    }
  }

  Future<void> _editExercise(Exercise exercise) async {
    // Show the AddExerciseSheet in edit mode
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddExerciseSheet(
        routineId: widget.routineId,
        exercise: exercise,
        onExerciseAdded: (updatedExercise) async {
          await _loadRoutine(); // Reload to get updated exercise
        },
      ),
    );
  }

  Future<void> _reorderExercises(int oldIndex, int newIndex) async {
    if (_routine == null) return;
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    try {
      // Get ordered exercises based on routine's exerciseRefs
      final orderedRefs = List<ExerciseRef>.from(_routine!.exerciseRefs);
      
      // Update local state first for responsive UI
      setState(() {
        final ref = orderedRefs.removeAt(oldIndex);
        orderedRefs.insert(newIndex, ref);
        
        // Update the order field for each ref
        for (int i = 0; i < orderedRefs.length; i++) {
          orderedRefs[i] = ExerciseRef(
            exerciseId: orderedRefs[i].exerciseId,
            order: i,
            sets: orderedRefs[i].sets,
          );
        }
        
        // Update routine with new refs
        _routine = _routine!.copyWith(exerciseRefs: orderedRefs);
      });

      // Update routine with new order in Firestore
      await _routineService.reorderExercises(widget.routineId, orderedRefs);
    } catch (e) {
      // Reload routine on error to ensure UI matches server state
      await _loadRoutine();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reordering exercises: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get ordered exercises based on routine's exerciseRefs
    final orderedExercises = _routine?.exerciseRefs
        .map((ref) => _exercises[ref.exerciseId])
        .whereType<Exercise>()
        .toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Routine'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
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
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _difficulty = value);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orderedExercises.length,
              onReorder: _reorderExercises,
              itemBuilder: (context, index) {
                final exercise = orderedExercises[index];
                final ref = _routine!.exerciseRefs
                    .firstWhere((ref) => ref.exerciseId == exercise.exerciseId);
                
                return ExerciseCard(
                  key: ValueKey(exercise.exerciseId),
                  exercise: exercise,
                  sets: ref.sets,
                  index: index,
                  onDelete: () => _deleteExercise(exercise),
                  onEdit: () => _editExercise(exercise),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExerciseSheet,
        child: const Icon(Icons.add),
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