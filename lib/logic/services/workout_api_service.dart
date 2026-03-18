import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WorkoutApiService {
  // Backend config
  static const String _baseUrl = 'http://192.168.1.42:3000';

  Future<bool> logWorkout({
    required String email,
    required String exerciseName,
    required String muscleGroup,
    required String level,
    required String date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/log-workout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'exerciseName': exerciseName,
          'muscleGroup': muscleGroup,
          'level': level,
          'date': date,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Failed to log workout: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error in logWorkout: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDailyWorkouts(String email, String date) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/daily-workout/$email/$date'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to get daily workouts: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error in getDailyWorkouts: $e');
      return null;
    }
  }
}
