import 'package:equatable/equatable.dart';

enum OnboardingStatus { initial, loading, completed, error }

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final double progress;
  final String fullName;
  final int? age;
  final double? weight;
  final String weightUnit;
  final double? height;

  const OnboardingState({
    required this.status,
    required this.progress,
    this.fullName = '',
    this.age,
    this.weight,
    this.weightUnit = 'KG',
    this.height,
  });

  factory OnboardingState.initial() => const OnboardingState(
        status: OnboardingStatus.initial,
        progress: 0.0,
      );

  OnboardingState copyWith({
    OnboardingStatus? status,
    double? progress,
    String? fullName,
    int? age,
    double? weight,
    String? weightUnit,
    double? height,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      height: height ?? this.height,
    );
  }

  @override
  List<Object?> get props => [status, progress, fullName, age, weight, weightUnit, height];
}
