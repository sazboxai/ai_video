import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/routine.dart';

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
  late PageController _pageController;
  late List<VideoPlayerController> _controllers;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    // Initialize controllers for exercises with videos
    _controllers = widget.routine.exercises
        .where((e) => e.videoUrl != null)
        .map((e) => VideoPlayerController.network(e.videoUrl!))
        .toList();

    // Initialize all controllers
    for (var controller in _controllers) {
      await controller.initialize();
      controller.setLooping(true);
    }

    // Start playing the first video
    if (_controllers.isNotEmpty) {
      _controllers.first.play();
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Pause previous video
    if (_currentIndex < _controllers.length) {
      _controllers[_currentIndex].pause();
    }
    // Play current video
    if (index < _controllers.length) {
      _controllers[index].play();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video PageView
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _controllers.length,
            itemBuilder: (context, index) {
              return _VideoPlayerItem(
                controller: _controllers[index],
                exercise: widget.routine.exercises
                    .where((e) => e.videoUrl != null)
                    .elementAt(index),
              );
            },
          ),
          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerItem extends StatelessWidget {
  final VideoPlayerController controller;
  final Exercise exercise;

  const _VideoPlayerItem({
    required this.controller,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          controller.value.isInitialized
              ? VideoPlayer(controller)
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
          // Exercise Info Overlay
          Positioned(
            left: 16,
            bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${exercise.sets} sets',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 