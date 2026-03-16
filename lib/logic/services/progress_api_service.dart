import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class RadarChartData {
  final List<String> labels;
  final List<double> values;

  RadarChartData({required this.labels, required this.values});

  factory RadarChartData.fromJson(Map<String, dynamic> json) {
    return RadarChartData(
      labels: List<String>.from(json['labels'] ?? []),
      values: List<double>.from((json['values'] ?? []).map((x) => (x as num).toDouble())),
    );
  }
}

class ProgressData {
  final int streakDays;
  final double muscleMass;
  final double bodyFat;
  final double muscleMassChange;
  final double bodyFatChange;
  final List<DateTime> activeDates;
  final RadarChartData radarData;
  final List<double> nutritionJourney;

  ProgressData({
    required this.streakDays,
    required this.muscleMass,
    required this.bodyFat,
    required this.muscleMassChange,
    required this.bodyFatChange,
    required this.activeDates,
    required this.radarData,
    required this.nutritionJourney,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      streakDays: json['streakDays'] ?? 0,
      muscleMass: (json['muscleMass'] ?? 0).toDouble(),
      bodyFat: (json['bodyFat'] ?? 0).toDouble(),
      muscleMassChange: (json['muscleMassChange'] ?? 0).toDouble(),
      bodyFatChange: (json['bodyFatChange'] ?? 0).toDouble(),
      activeDates: (json['activeDates'] as List<dynamic>? ?? []).map((d) => DateTime.parse(d)).toList(),
      radarData: RadarChartData.fromJson(json['radarData'] ?? {}),
      nutritionJourney: List<double>.from((json['nutritionJourney'] ?? []).map((x) => (x as num).toDouble())),
    );
  }
}

class ProgressApiService {
  // Configured to match food_api_service
  final String _baseUrl = 'http://192.168.1.42:3000';

  Future<ProgressData?> getProgressData(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/progress/$email'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return ProgressData.fromJson(data);
      } else {
        debugPrint('Failed to fetch progress data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error in getProgressData: $e');
      return null;
    }
  }
}
