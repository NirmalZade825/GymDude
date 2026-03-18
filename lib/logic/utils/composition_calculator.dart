class CompositionChange {
  final double muscleChange;
  final double fatChange;

  CompositionChange({required this.muscleChange, required this.fatChange});
}

class BodyCompositionCalculator {

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

    
    return CompositionChange(
      muscleChange: muscleChange / 7700, 
      fatChange: fatChange / 7700, 
    );
  }
}
