import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';

class RoutinePlayerScreen extends StatefulWidget {
  final Routine routine;
  
  const RoutinePlayerScreen({
    super.key,
    required this.routine,
  });

  @override
  State<RoutinePlayerScreen> createState() => _RoutinePlayerScreenState();
}

class _RoutinePlayerScreenState extends State<RoutinePlayerScreen> {
  final _exerciseService = ExerciseService();
  late PageController _pageController;
  List<VideoPlayerController> _controllers = [];
  List<Exercise> _exercises = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadExercisesAndInitialize();
  }

  Future<void> _loadExercisesAndInitialize() async {
    try {
      // Load exercises first
      _exercises = await Future.wait(
        widget.routine.exerciseRefs.map((ref) async {
          final exercise = await _exerciseService.getExerciseById(ref.exerciseId);
          if (exercise == null) {
            throw 'Exercise not found: ${ref.exerciseId}';
          }
          return exercise;
        }),
      );

      // Then initialize controllers for exercises with videos
      _controllers = await Future.wait(
        _exercises
            .where((exercise) => exercise.videoUrl != null)
            .map((exercise) async {
          final controller = VideoPlayerController.network(exercise.videoUrl!);
          await controller.initialize();
          controller.setLooping(true); // Loop videos
          return controller;
        }),
      );

      // Start playing the first video
      if (_controllers.isNotEmpty) {
        _controllers.first.play();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load routine: $e';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      // Pause the previous video
      if (_currentIndex < _controllers.length) {
        _controllers[_currentIndex].pause();
      }
      _currentIndex = index;
      // Play the new video
      if (_currentIndex < _controllers.length) {
        _controllers[_currentIndex].play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.routine.title,
          style: const TextStyle(
            color: Colors.white,
            shadows: [Shadow(blurRadius: 4)],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _exercises.isEmpty
                  ? const Center(child: Text('No exercises in this routine'))
                  : PageView.builder(
                      scrollDirection: Axis.vertical,
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _exercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _exercises[index];
                        final ref = widget.routine.exerciseRefs[index];
                        
                        return _ExerciseVideoPage(
                          exercise: exercise,
                          controller: exercise.videoUrl != null
                              ? _controllers[_controllers.indexWhere(
                                  (c) => c.dataSource == exercise.videoUrl)]
                              : null,
                          sets: ref.sets,
                          currentIndex: index,
                          totalExercises: _exercises.length,
                        );
                      },
                    ),
    );
  }
}

class _ExerciseVideoPage extends StatelessWidget {
  final Exercise exercise;
  final VideoPlayerController? controller;
  final int sets;
  final int currentIndex;
  final int totalExercises;

  const _ExerciseVideoPage({
    required this.exercise,
    required this.controller,
    required this.sets,
    required this.currentIndex,
    required this.totalExercises,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video or placeholder
        if (controller != null)
          GestureDetector(
            onTap: () {
              if (controller!.value.isPlaying) {
                controller!.pause();
              } else {
                controller!.play();
              }
            },
            child: VideoPlayer(controller!),
          )
        else
          Container(
            color: Colors.black,
            child: Center(
              child: Text(
                'No video available for\n${exercise.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

        // Play/Pause overlay
        if (controller != null && !controller!.value.isPlaying)
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),

        // Exercise info overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$sets sets',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (currentIndex + 1) / totalExercises,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Exercise ${currentIndex + 1} of $totalExercises',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    shadows: const [Shadow(blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}