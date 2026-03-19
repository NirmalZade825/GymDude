import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class NutritionInfo {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final String unit;
  final double baseAmount;

  NutritionInfo({
    this.name = 'Unknown Food',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    this.unit = 'grams',
    this.baseAmount = 100,
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
  
  static const String _baseUrl = 'http://192.168.1.42:3000';

 
  static String get _hfToken => dotenv.env['HF_TOKEN'] ?? '';
  static const String _hfApiUrl =
      'https://api-inference.huggingface.co/models/rajistics/finetuned-indian-food';
  
  static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  
  static const double _confidenceThreshold = 0.35;

  // The 20 food categories in this dataset
  static const List<String> indianFoodLabels = [
    'Burger', 'Butter Naan', 'Chai', 'Chapati', 'Chole Bhature',
    'Dal Makhani', 'Dhokla', 'Fried Rice', 'Idli', 'Jalebi',
    'Kaathi Rolls', 'Kadai Paneer', 'Kulfi', 'Masala Dosa', 'Momos',
    'Paani Puri', 'Pakode', 'Pav Bhaji', 'Pizza', 'Samosa',
  ];


  Future<Map<String, dynamic>> scanFoodWithGemini(File imageFile) async {
    try {
      if (_geminiApiKey.isEmpty || _geminiApiKey == 'your_gemini_api_key_here') {
        throw Exception('GEMINI_API_KEY is missing. Please add it to your .env file.');
      }

      final model = GenerativeModel(
        model: 'gemini-pro-vision',
        apiKey: _geminiApiKey,
      );

      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
            "You are a nutritional expert. Analyze the provided image of food and return the identification and nutritional information for exactly ONE serving in a structured JSON format. "
            "The JSON must have the following keys: "
            "1. 'foodName' (string, name of the food) "
            "2. 'calories' (integer, total calories) "
            "3. 'protein' (number, grams of protein) "
            "4. 'carbs' (number, grams of carbohydrates) "
            "5. 'fats' (number, grams of fats) "
            "Return ONLY the JSON block, no other text."
          ),
          DataPart('image/jpeg', bytes),
        ]),
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) {
        throw Exception('Gemini returned an empty response.');
      }

      // Extract JSON from the response 
      final jsonString = text.contains('```json') 
          ? text.split('```json')[1].split('```')[0].trim()
          : text.trim();

      final Map<String, dynamic> data = jsonDecode(jsonString);
      return data;
    } catch (e) {
      debugPrint('Error in scanFoodWithGemini: $e');
      rethrow;
    }
  }


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
          final String label = topPrediction['label'] as String;
          final double score = (topPrediction['score'] as num).toDouble();

          debugPrint('Indian food scan → label: $label, score: $score');

          if (score < _confidenceThreshold) {
            throw Exception(
              'LOW_CONFIDENCE:Could not identify the food with enough certainty (${(score * 100).toStringAsFixed(0)}%). '
              'Try a clearer image or enter manually.',
            );
          }

          return formatLabel(label);
        } else {
          throw Exception('No food identified in the image.');
        }
      } else if (response.statusCode == 503) {
        // Model is cold-starting — wait and retry once
        final errorData = jsonDecode(response.body);
        final waitTime = (errorData['estimated_time'] ?? 10).toInt();
        debugPrint('HF Model loading. Waiting $waitTime seconds...');
        await Future.delayed(Duration(seconds: waitTime));
        return scanFoodImage(imageFile);
      } else {
        throw Exception('HF API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in scanFoodImage: $e');
      rethrow;
    }
  }


  Future<List<NutritionInfo>> searchNutritionInfo(String foodQuery) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/nutrition?query=${Uri.encodeComponent(foodQuery)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (data is List) {
          return data.map((item) => NutritionInfo(
            name: item['name'] ?? 'Unknown',
            calories: (item['calories'] ?? 0).toInt(),
            protein: (item['protein'] ?? 0).toDouble(),
            carbs: (item['carbs'] ?? 0).toDouble(),
            fats: (item['fats'] ?? 0).toDouble(),
            unit: item['unit'] ?? 'grams',
            baseAmount: (item['baseAmount'] ?? 100).toDouble(),
          )).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching nutrition: $e');
    }

    // Fallback default response 
    return [];
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
