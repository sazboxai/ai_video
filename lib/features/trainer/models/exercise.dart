import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String exerciseId;
  final String trainerId;
  final String name;
  final int defaultSets;
  final String? videoUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    required this.exerciseId,
    required this.trainerId,
    required this.name,
    required this.defaultSets,
    this.videoUrl,
    this.thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'trainerId': trainerId,
      'name': name,
      'defaultSets': defaultSets,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      exerciseId: json['exerciseId'] as String,
      trainerId: json['trainerId'] as String,
      name: json['name'] as String,
      defaultSets: json['defaultSets'] as int,
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Exercise copyWith({
    String? exerciseId,
    String? trainerId,
    String? name,
    int? defaultSets,
    String? videoUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exercise(
      exerciseId: exerciseId ?? this.exerciseId,
      trainerId: trainerId ?? this.trainerId,
      name: name ?? this.name,
      defaultSets: defaultSets ?? this.defaultSets,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
