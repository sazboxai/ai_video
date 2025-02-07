import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_ref.dart';

class Routine {
  final String routineId;
  final String trainerId;
  final String title;
  final String description;
  final String difficulty;
  final int viewCount;
  final int likeCount;
  final List<ExerciseRef> exerciseRefs;
  final DateTime createdAt;
  final DateTime updatedAt;

  Routine({
    required this.routineId,
    required this.trainerId,
    required this.title,
    String? description,
    String? difficulty,
    this.viewCount = 0,
    this.likeCount = 0,
    required this.exerciseRefs,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.description = description ?? '',
        this.difficulty = difficulty ?? 'Beginner',
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'routineId': routineId,
      'trainerId': trainerId,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'exerciseRefs': exerciseRefs.map((ref) => ref.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    final exerciseRefsJson = json['exerciseRefs'] as List<dynamic>?;
    
    final exerciseRefs = (exerciseRefsJson
        ?.map((e) => ExerciseRef.fromJson(e as Map<String, dynamic>))
        .toList() ?? [])
      ..sort((a, b) => a.order.compareTo(b.order));
    
    return Routine(
      routineId: json['routineId'] as String,
      trainerId: json['trainerId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      exerciseRefs: exerciseRefs,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Routine copyWith({
    String? routineId,
    String? trainerId,
    String? title,
    String? description,
    String? difficulty,
    int? viewCount,
    int? likeCount,
    List<ExerciseRef>? exerciseRefs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      routineId: routineId ?? this.routineId,
      trainerId: trainerId ?? this.trainerId,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      exerciseRefs: exerciseRefs ?? this.exerciseRefs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}