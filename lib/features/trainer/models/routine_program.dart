import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineProgram {
  final String id;
  final String trainerId;
  final String name;
  final String description;
  final List<String> equipment;
  final String outline;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoutineProgram({
    required this.id,
    required this.trainerId,
    required this.name,
    required this.description,
    required this.equipment,
    required this.outline,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trainerId': trainerId,
      'name': name,
      'description': description,
      'equipment': equipment,
      'outline': outline,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }

  factory RoutineProgram.fromMap(Map<String, dynamic> map, String documentId) {
    return RoutineProgram(
      id: documentId,
      trainerId: map['trainerId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      equipment: List<String>.from(map['equipment'] ?? []),
      outline: map['outline'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  RoutineProgram copyWith({
    String? id,
    String? trainerId,
    String? name,
    String? description,
    List<String>? equipment,
    String? outline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoutineProgram(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      name: name ?? this.name,
      description: description ?? this.description,
      equipment: equipment ?? this.equipment,
      outline: outline ?? this.outline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
