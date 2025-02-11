import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import '../services/auth_service.dart';
import '../screens/create_routine_screen.dart';
import '../screens/routine_player_screen.dart';
import '../screens/edit_routine_screen.dart';

class MyRoutinesScreen extends StatelessWidget {
  final RoutineService _routineService = RoutineService();
  final AuthService _authService = AuthService();

  MyRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in'));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Routines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreateRoutine(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Routine>>(
        stream: _routineService.getTrainerRoutines(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final routines = snapshot.data ?? [];

          if (routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No routines yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _navigateToCreateRoutine(context),
                    child: const Text('Create Your First Routine'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return RoutineCard(
                routine: routine,
                onDelete: () async {
                  try {
                    await _routineService.deleteRoutine(routine.routineId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Routine deleted')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToCreateRoutine(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateRoutineScreen(),
      ),
    );
  }
}

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(routine.title),
            subtitle: Text(
              routine.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 0),
          ButtonBar(
            children: [
              // Play Button
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                tooltip: 'Play Routine',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoutinePlayerScreen(
                        routine: routine,
                      ),
                    ),
                  );
                },
              ),
              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Routine',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditRoutineScreen(
                        routineId: routine.routineId,
                      ),
                    ),
                  );
                },
              ),
              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete Routine',
                onPressed: () => _showDeleteDialog(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_outlined),
                    const SizedBox(width: 4),
                    Text('${routine.viewCount}'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.favorite_border),
                    const SizedBox(width: 4),
                    Text('${routine.likeCount}'),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  '${routine.exerciseRefs.length} exercises',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: const Text(
          'Are you sure you want to delete this routine? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      onDelete();
    }
  }
}