import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;

  const RegisterRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SocialLoginRequested extends AuthEvent {
  final String provider;

  const SocialLoginRequested({required this.provider});

  @override
  List<Object> get props => [provider];
}

class ProfileCompleted extends AuthEvent {
  final String fullName;
  final int age;
  final double weight;
  final double height;
  final String gender;
  final double activityLevel;

  const ProfileCompleted({
    required this.fullName,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
  });

  @override
  List<Object> get props => [fullName, age, weight, height, gender, activityLevel];
}

class UpdateGoals extends AuthEvent {
  final int targetCalories;
  final int targetProtein;
  final double waterGoal;

  const UpdateGoals({required this.targetCalories, required this.targetProtein, required this.waterGoal});

  @override
  List<Object> get props => [targetCalories, targetProtein, waterGoal];
}

class LogoutRequested extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String fullName;
  final int age;
  final double weight;
  final double height;
  final String gender;
  final double activityLevel;

  const UpdateProfileRequested({
    required this.fullName,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
  });

  @override
  List<Object> get props => [fullName, age, weight, height, gender, activityLevel];
}
