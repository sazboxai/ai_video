import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String locationId;
  final String trainerId;
  final String name;
  final List<String> photoUrls;
  final List<String> equipment;
  final List<RoutineProgram> routinePrograms;
  final DateTime createdAt;
  final DateTime updatedAt;

  Location({
    required this.locationId,
    required this.trainerId,
    required this.name,
    this.photoUrls = const [],
    this.equipment = const [],
    this.routinePrograms = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'trainerId': trainerId,
      'name': name,
      'photoUrls': photoUrls,
      'equipment': equipment,
      'routinePrograms': routinePrograms.map((program) => program.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      locationId: json['locationId'] as String,
      trainerId: json['trainerId'] as String,
      name: json['name'] as String,
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      equipment: (json['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
      routinePrograms: (json['routinePrograms'] as List<dynamic>?)
          ?.map((e) => RoutineProgram.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Location copyWith({
    String? locationId,
    String? trainerId,
    String? name,
    List<String>? photoUrls,
    List<String>? equipment,
    List<RoutineProgram>? routinePrograms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      locationId: locationId ?? this.locationId,
      trainerId: trainerId ?? this.trainerId,
      name: name ?? this.name,
      photoUrls: photoUrls ?? this.photoUrls,
      equipment: equipment ?? this.equipment,
      routinePrograms: routinePrograms ?? this.routinePrograms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RoutineProgram {
  final String programId;
  final String title;
  final String markdownContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoutineProgram({
    required this.programId,
    required this.title,
    required this.markdownContent,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'programId': programId,
      'title': title,
      'markdownContent': markdownContent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RoutineProgram.fromJson(Map<String, dynamic> json) {
    return RoutineProgram(
      programId: json['programId'] as String,
      title: json['title'] as String,
      markdownContent: json['markdownContent'] as String,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  RoutineProgram copyWith({
    String? programId,
    String? title,
    String? markdownContent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoutineProgram(
      programId: programId ?? this.programId,
      title: title ?? this.title,
      markdownContent: markdownContent ?? this.markdownContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
