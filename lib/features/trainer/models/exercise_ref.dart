import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseRef {
  final String exerciseId;
  final int order;
  final int sets;

  ExerciseRef({
    required this.exerciseId,
    required this.order,
    required this.sets,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'order': order,
      'sets': sets,
    };
  }

  factory ExerciseRef.fromJson(Map<String, dynamic> json) {
    return ExerciseRef(
      exerciseId: json['exerciseId'] as String,
      order: json['order'] as int,
      sets: json['sets'] as int,
    );
  }

  ExerciseRef copyWith({
    String? exerciseId,
    int? order,
    int? sets,
  }) {
    return ExerciseRef(
      exerciseId: exerciseId ?? this.exerciseId,
      order: order ?? this.order,
      sets: sets ?? this.sets,
    );
  }
}
