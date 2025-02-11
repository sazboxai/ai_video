class RoutineGenerationParams {
  final int numberOfDays;
  final int durationMinutes;
  final String fitnessGoal;
  final List<String> selectedEquipment;

  RoutineGenerationParams({
    required this.numberOfDays,
    required this.durationMinutes,
    required this.fitnessGoal,
    required this.selectedEquipment,
  });

  Map<String, dynamic> toJson() {
    return {
      'numberOfDays': numberOfDays,
      'durationMinutes': durationMinutes,
      'fitnessGoal': fitnessGoal,
      'selectedEquipment': selectedEquipment,
    };
  }
}
