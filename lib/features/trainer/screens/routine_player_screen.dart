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
  List<VideoPlayerController> _controllers = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exercisesWithVideos = widget.routine.exercises
          .where((e) => e.videoUrl != null)
          .toList();

      for (var exercise in exercisesWithVideos) {
        try {
          final controller = VideoPlayerController.networkUrl(
            Uri.parse(exercise.videoUrl!),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            httpHeaders: {
              'Range': 'bytes=0-',
            },
          );

          await controller.initialize();
          controller.setLooping(true);
          _controllers.add(controller);
        } catch (e) {
          print('Error initializing video for ${exercise.name}: $e');
          // Try reinitializing with different options
          try {
            final retryController = VideoPlayerController.networkUrl(
              Uri.parse(exercise.videoUrl!),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            );
            await retryController.initialize();
            retryController.setLooping(true);
            _controllers.add(retryController);
          } catch (retryError) {
            print('Retry failed for ${exercise.name}: $retryError');
          }
        }
      }

      if (_controllers.isNotEmpty) {
        _controllers.first.play();
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading videos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    if (_currentIndex < _controllers.length) {
      _controllers[_currentIndex].pause();
    }
    if (index < _controllers.length) {
      _controllers[index].play();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeControllers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controllers.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No videos available in this routine',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    '${_currentIndex + 1}/${_controllers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
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
          controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
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