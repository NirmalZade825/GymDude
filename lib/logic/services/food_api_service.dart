import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fats;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}

class FoodLogItem {
  final String id;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final int servings;
  final String date;

  FoodLogItem({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.servings,
    required this.date,
  });

  factory FoodLogItem.fromJson(Map<String, dynamic> json) {
    return FoodLogItem(
      id: json['_id'] ?? '',
      foodName: json['foodName'] ?? '',
      calories: json['calories'] ?? 0,
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fats: (json['fats'] ?? 0).toDouble(),
      servings: json['servings'] ?? 1,
      date: json['date'] ?? '',
    );
  }
}

class DailyNutritionResult {
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final List<FoodLogItem> logs;

  DailyNutritionResult({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.logs,
  });

  factory DailyNutritionResult.fromJson(Map<String, dynamic> json) {
    var logsList = json['logs'] as List? ?? [];
    List<FoodLogItem> parsedLogs = logsList.map((i) => FoodLogItem.fromJson(i)).toList();

    return DailyNutritionResult(
      totalCalories: json['totalCalories'] ?? 0,
      totalProtein: (json['totalProtein'] ?? 0).toDouble(),
      totalCarbs: (json['totalCarbs'] ?? 0).toDouble(),
      totalFats: (json['totalFats'] ?? 0).toDouble(),
      logs: parsedLogs,
    );
  }
}

class FoodApiService {
  // Backend config
  static const String _baseUrl = 'http://192.168.1.42:3000';

  // Hugging Face config
  static const String _hfToken = ''; 
  static const String _hfApiUrl = 'https://api-inference.huggingface.co/models/nateraw/food';

  /// Scans the image using Hugging Face AI and returns the recognized food name
  Future<String> scanFoodImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      final response = await http.post(
        Uri.parse(_hfApiUrl),
        headers: {
          'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(response.body);
        
        if (result.isNotEmpty) {
          final topPrediction = result.first;
          final String predictedLabel = topPrediction['label'] as String;
          return formatLabel(predictedLabel);
        } else {
          throw Exception('No food identified');
        }
      } else if (response.statusCode == 503) {
        // Model is loading, wait and retry once
        final errorData = jsonDecode(response.body);
        final waitTime = (errorData['estimated_time'] ?? 5).toInt();
        debugPrint('HF Model loading. Waiting $waitTime seconds...');
        await Future.delayed(Duration(seconds: waitTime));
        return scanFoodImage(imageFile); // Retry
      } else {
        throw Exception('HF API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in scanFoodImage: $e');
      rethrow;
    }
  }

  /// Fetches nutrition info for a given food string from our backend database.
  Future<NutritionInfo> getNutritionInfo(String foodQuery) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/nutrition?query=${Uri.encodeComponent(foodQuery)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return NutritionInfo(
          calories: (data['calories'] ?? 0).toInt(),
          protein: (data['protein'] ?? 0).toDouble(),
          carbs: (data['carbs'] ?? 0).toDouble(),
          fats: (data['fats'] ?? 0).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching nutrition: $e');
    }

    // Fallback default response if backend fails completely
    return NutritionInfo(calories: 250, protein: 10, carbs: 30, fats: 10);
  }

  static String formatLabel(String rawLabel) {
    if (rawLabel.isEmpty) return rawLabel;
    final words = rawLabel.replaceAll('_', ' ').split(' ');
    final capitalized = words.map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
    return capitalized;
  }

  Future<bool> logFood({
    required String email,
    required String foodName,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
    required int servings,
    required String date,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/log-food'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'foodName': foodName,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fats': fats,
          'servings': servings,
          'date': date,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Failed to log food: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error in logFood: $e');
      return false;
    }
  }

  Future<DailyNutritionResult?> getDailyNutrition(String email, String date) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/daily-nutrition/$email/$date'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return DailyNutritionResult.fromJson(data);
      } else {
        debugPrint('Failed to fetch daily nutrition: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error in getDailyNutrition: $e');
      return null;
    }
  }
}
