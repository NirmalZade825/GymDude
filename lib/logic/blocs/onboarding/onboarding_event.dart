import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class UpdateField extends OnboardingEvent {
  final String fieldName;
  final dynamic value;

  const UpdateField({required this.fieldName, required this.value});

  @override
  List<Object?> get props => [fieldName, value];
}

class SubmitOnboarding extends OnboardingEvent {
  final String email;

  const SubmitOnboarding({required this.email});

  @override
  List<Object> get props => [email];
}
