import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/routine.dart';
import '../models/exercise_ref.dart';
import '../services/video_service.dart';

class PoseVideoViewerScreen extends StatefulWidget {
  final Routine routine;
  final int initialExerciseIndex;

  const PoseVideoViewerScreen({
    Key? key,
    required this.routine,
    this.initialExerciseIndex = 0,
  }) : super(key: key);

  @override
  State<PoseVideoViewerScreen> createState() => _PoseVideoViewerScreenState();
}

class _PoseVideoViewerScreenState extends State<PoseVideoViewerScreen> {
  late PageController _pageController;
  final VideoService _videoService = VideoService();
  final Map<String, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialExerciseIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize controllers for current and adjacent videos
      for (int i = _currentIndex - 1; i <= _currentIndex + 1; i++) {
        if (i >= 0 && i < widget.routine.exerciseRefs.length) {
          await _initializeController(i);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeController(int index) async {
    final exerciseRef = widget.routine.exerciseRefs[index];
    try {
      final videoUrl = await _videoService.getPoseVideoUrl(
        widget.routine.routineId,
        exerciseRef.exerciseId,
      );
      
      if (videoUrl != null) {
        final controller = VideoPlayerController.network(videoUrl);
        await controller.initialize();
        controller.setLooping(true);
        _controllers[exerciseRef.exerciseId] = controller;
        
        if (index == _currentIndex) {
          controller.play();
        }
      }
    } catch (e) {
      print('Error loading pose video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPageChanged,
              itemCount: widget.routine.exerciseRefs.length,
              itemBuilder: (context, index) {
                final exerciseRef = widget.routine.exerciseRefs[index];
                final controller = _controllers[exerciseRef.exerciseId];

                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                }

                if (controller == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam_off,
                          color: Colors.white54,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No pose video available yet',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Exercise ${index + 1}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(controller),
                    // Exercise info overlay
                    Positioned(
                      bottom: 80,
                      left: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exercise ${index + 1}/${widget.routine.exerciseRefs.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${exerciseRef.sets} sets',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            // Back button overlay
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int index) async {
    // Stop current video
    final currentExerciseRef = widget.routine.exerciseRefs[_currentIndex];
    _controllers[currentExerciseRef.exerciseId]?.pause();

    // Play new video
    final newExerciseRef = widget.routine.exerciseRefs[index];
    final controller = _controllers[newExerciseRef.exerciseId];
    if (controller != null) {
      controller.play();
    }

    // Update controllers for new adjacent videos
    _currentIndex = index;
    _initializeControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }
} 