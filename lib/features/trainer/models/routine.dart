import 'package:cloud_firestore/cloud_firestore.dart';

class Routine {
  final String id;
  final String trainerId;
  final String title;
  final String description;
  final int viewCount;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Exercise> exercises;

  Routine({
    required this.id,
    required this.trainerId,
    required this.title,
    required this.description,
    this.viewCount = 0,
    this.likeCount = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trainerId': trainerId,
      'title': title,
      'description': description,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map, String id) {
    return Routine(
      id: id,
      trainerId: map['trainerId'],
      title: map['title'],
      description: map['description'],
      viewCount: map['viewCount'] ?? 0,
      likeCount: map['likeCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      exercises: (map['exercises'] as List)
          .map((e) => Exercise.fromMap(e))
          .toList(),
    );
  }
}

class Exercise {
  final String name;
  final int sets;
  final String? videoUrl;  // Remote URL after upload
  final String? videoPath; // Local path while recording
  final int order;

  Exercise({
    required this.name,
    required this.sets,
    this.videoUrl,
    this.videoPath,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'videoUrl': videoUrl,
      'order': order,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'],
      sets: map['sets'],
      videoUrl: map['videoUrl'],
      order: map['order'],
    );
  }
} 