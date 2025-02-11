import 'package:cloud_functions/cloud_functions.dart';
import '../models/routine_generation_params.dart';

class AIRoutineService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> generateRoutine(RoutineGenerationParams params) async {
    try {
      final result = await _functions.httpsCallable('generateWorkoutRoutine').call({
        'numberOfDays': params.numberOfDays,
        'durationMinutes': params.durationMinutes,
        'fitnessGoal': params.fitnessGoal,
        'selectedEquipment': params.selectedEquipment,
      });

      final data = result.data as Map<String, dynamic>;
      
      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      return {
        'title': data['title'],
        'description': data['description'],
        'outline': data['outline'],
      };
    } catch (e) {
      throw Exception('Failed to generate routine: $e');
    }
  }
}
