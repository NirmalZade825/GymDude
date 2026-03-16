import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error, registrationSuccess }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;
  final String? email;
  final String? fullName;
  final int? age;
  final double? weight;
  final double? height;
  final int targetCalories;
  final int targetProtein;
  final bool isProfileComplete;

  const AuthState({
    required this.status,
    this.errorMessage,
    this.email,
    this.fullName,
    this.age,
    this.weight,
    this.height,
    this.targetCalories = 2500,
    this.targetProtein = 180,
    this.isProfileComplete = false,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? email,
    String? fullName,
    int? age,
    double? weight,
    double? height,
    int? targetCalories,
    int? targetProtein,
    bool? isProfileComplete,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, email, fullName, age, weight, height, targetCalories, targetProtein, isProfileComplete];
}
