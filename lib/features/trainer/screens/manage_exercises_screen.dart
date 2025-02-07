import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/exercise_ref.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import '../services/exercise_service.dart';
import '../widgets/exercise_card.dart';
import 'exercise_form_screen.dart';

class ManageExercisesScreen extends StatefulWidget {
  final Routine routine;

  const ManageExercisesScreen({
    Key? key,
    required this.routine,
  }) : super(key: key);

  @override
  State<ManageExercisesScreen> createState() => _ManageExercisesScreenState();
}

class _ManageExercisesScreenState extends State<ManageExercisesScreen> {
  final _routineService = RoutineService();
  final _exerciseService = ExerciseService();
  List<Exercise> _exercises = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await Future.wait(
        widget.routine.exerciseRefs.map((ref) async {
          final exercise = await _exerciseService.getExerciseById(ref.exerciseId);
          if (exercise == null) throw 'Exercise not found: ${ref.exerciseId}';
          return exercise;
        }),
      );

      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exercises: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addExercise() async {
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseFormScreen(
          onSave: (exercise) async {
            // Add exercise to exercises collection
            final savedExercise = await _exerciseService.createExercise(
              trainerId: widget.routine.trainerId,
              name: exercise.name,
              defaultSets: exercise.defaultSets,
              localVideoPath: null, // Handle video separately if needed
            );

            // Add exercise reference to routine
            final order = widget.routine.exerciseRefs.length;
            await _routineService.addExerciseToRoutine(
              widget.routine.routineId,
              savedExercise,
              order,
              exercise.defaultSets,
            );

            setState(() {
              _exercises.add(savedExercise);
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _exercises.add(result);
      });
    }
  }

  Future<void> _editExercise(Exercise exercise) async {
    final result = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseFormScreen(
          exercise: exercise,
          onSave: (updatedExercise) async {
            // Update exercise in exercises collection
            await _exerciseService.updateExercise(updatedExercise);

            // Update exercise ref in routine if sets changed
            final ref = widget.routine.exerciseRefs
                .firstWhere((ref) => ref.exerciseId == exercise.exerciseId);
            if (ref.sets != updatedExercise.defaultSets) {
              await _routineService.updateExerciseSets(
                widget.routine.routineId,
                exercise.exerciseId,
                updatedExercise.defaultSets,
              );
            }

            setState(() {
              final index = _exercises.indexWhere(
                (e) => e.exerciseId == exercise.exerciseId,
              );
              if (index != -1) {
                _exercises[index] = updatedExercise;
              }
            });
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final index = _exercises.indexWhere(
          (e) => e.exerciseId == exercise.exerciseId,
        );
        if (index != -1) {
          _exercises[index] = result;
        }
      });
    }
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: const Text('Are you sure you want to delete this exercise?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        // Remove exercise reference from routine
        await _routineService.removeExerciseFromRoutine(
          widget.routine.routineId,
          exercise.exerciseId,
        );

        // Delete exercise from exercises collection
        await _exerciseService.deleteExercise(exercise.exerciseId);

        setState(() {
          _exercises.removeWhere((e) => e.exerciseId == exercise.exerciseId);
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reorderExercises(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    try {
      setState(() {
        final item = _exercises.removeAt(oldIndex);
        _exercises.insert(newIndex, item);
      });

      // Create new exercise refs with updated order
      final newRefs = _exercises.asMap().entries.map((entry) {
        final exercise = entry.value;
        final currentRef = widget.routine.exerciseRefs
            .firstWhere((ref) => ref.exerciseId == exercise.exerciseId);
        
        return ExerciseRef(
          exerciseId: exercise.exerciseId,
          order: entry.key,
          sets: currentRef.sets,
        );
      }).toList();

      // Update routine with new order
      await _routineService.reorderExercises(
        widget.routine.routineId,
        newRefs,
      );
    } catch (e) {
      // Reload exercises on error to ensure UI matches server state
      await _loadExercises();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reordering exercises: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Exercises'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? const Center(
                  child: Text('No exercises in this routine'),
                )
              : ReorderableListView.builder(
                  itemCount: _exercises.length,
                  onReorder: _reorderExercises,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    final ref = widget.routine.exerciseRefs
                        .firstWhere((ref) => ref.exerciseId == exercise.exerciseId);
                    
                    return ExerciseCard(
                      key: ValueKey(exercise.exerciseId),
                      exercise: exercise,
                      sets: ref.sets,
                      onEdit: () => _editExercise(exercise),
                      onDelete: () => _deleteExercise(exercise),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        child: const Icon(Icons.add),
      ),
    );
  }
}
