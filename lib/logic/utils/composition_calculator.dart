class CompositionChange {
  final double muscleChange;
  final double fatChange;

  CompositionChange({required this.muscleChange, required this.fatChange});
}

class BodyCompositionCalculator {
  /// Calculates Basal Metabolic Rate using Mifflin-St Jeor Equation.
  /// gender: 'male' or 'female'
  /// weight: in kg
  /// height: in cm
  /// age: in years
  static double calculateBMR({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  /// Calculates predicted muscle and fat changes based on calorie balance and protein intake.
  /// caloriesIntake: Daily calories consumed
  /// caloriesNeeded: BMR * Activity Level
  /// proteinIntake: Daily protein in grams
  /// currentWeight: Current body weight in kg
  static CompositionChange calculateCompositionChanges({
    required double caloriesIntake,
    required double caloriesNeeded,
    required double proteinIntake,
    required double currentWeight,
  }) {
    final double balance = caloriesIntake - caloriesNeeded;
    double muscleChange = 0;
    double fatChange = 0;

    if (balance > 0) {
      // Surplus
      if (proteinIntake >= 1.6 * currentWeight) {
        muscleChange = balance * 0.35;
        fatChange = balance * 0.65;
      } else {
        muscleChange = balance * 0.15;
        fatChange = balance * 0.85;
      }
    } else if (balance < 0) {
      // Deficit
      final double absoluteBalance = balance.abs();
      fatChange = -(absoluteBalance * 0.8);
      muscleChange = -(absoluteBalance * 0.2);
    }

    // Convert calorie balance to approximate weight change (rough estimate)
    // 1kg of fat ≈ 7700 kcal, 1kg of muscle ≈ 1500-2500 kcal (highly variable)
    // For simplicity in the UI, we might display these as "points" or "grams"
    // converting calories to grams: 1g fat = 9 kcal, 1g muscle/protein = 4 kcal
    // Using a simple 7700 kcal per kg of mass change for display purposes or as requested.
    
    return CompositionChange(
      muscleChange: muscleChange / 7700, // in kg
      fatChange: fatChange / 7700, // in kg
    );
  }
}
