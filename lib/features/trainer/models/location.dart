import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String locationId;
  final String trainerId;
  final String name;
  final List<String> photoUrls;
  final List<String> equipment;
  final List<String> routineProgramIds;
  final DateTime? lastEquipmentScanTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Location({
    required this.locationId,
    required this.trainerId,
    required this.name,
    this.photoUrls = const [],
    this.equipment = const [],
    this.routineProgramIds = const [],
    this.lastEquipmentScanTime,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'trainerId': trainerId,
      'name': name,
      'photoUrls': photoUrls,
      'equipment': equipment,
      'routineProgramIds': routineProgramIds,
      'lastEquipmentScanTime': lastEquipmentScanTime != null
          ? Timestamp.fromDate(lastEquipmentScanTime!)
          : null,
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

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      locationId: json['locationId'] as String,
      trainerId: json['trainerId'] as String,
      name: json['name'] as String,
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      equipment: List<String>.from(json['equipment'] ?? []),
      routineProgramIds: List<String>.from(json['routineProgramIds'] ?? []),
      lastEquipmentScanTime: _parseDateTime(json['lastEquipmentScanTime']),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Location copyWith({
    String? locationId,
    String? trainerId,
    String? name,
    List<String>? photoUrls,
    List<String>? equipment,
    List<String>? routineProgramIds,
    DateTime? lastEquipmentScanTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      locationId: locationId ?? this.locationId,
      trainerId: trainerId ?? this.trainerId,
      name: name ?? this.name,
      photoUrls: photoUrls ?? this.photoUrls,
      equipment: equipment ?? this.equipment,
      routineProgramIds: routineProgramIds ?? this.routineProgramIds,
      lastEquipmentScanTime: lastEquipmentScanTime ?? this.lastEquipmentScanTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
