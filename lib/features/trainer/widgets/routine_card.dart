import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../screens/routine_player_screen.dart';
import '../screens/edit_routine_screen.dart';

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback? onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    this.onDelete,
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
              // View Button
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
                        routine: routine,
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
                Text(
                  '${routine.exercises.length} exercises',
                  style: Theme.of(context).textTheme.bodySmall,
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

    if (shouldDelete == true && onDelete != null) {
      onDelete!();
    }
  }
} 