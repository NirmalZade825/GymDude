import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  // Use your computer's Wi-Fi IP address
  final String baseUrl = 'http://192.168.1.42:3000';

  OnboardingBloc() : super(OnboardingState.initial()) {
    on<UpdateField>(_onUpdateField);
    on<SubmitOnboarding>(_onSubmitOnboarding);
  }

  void _onUpdateField(UpdateField event, Emitter<OnboardingState> emit) {
    OnboardingState newState;

    switch (event.fieldName) {
      case 'fullName':
        newState = state.copyWith(fullName: event.value);
        break;
      case 'age':
        newState = state.copyWith(age: int.tryParse(event.value.toString()));
        break;
      case 'weight':
        newState = state.copyWith(weight: double.tryParse(event.value.toString()));
        break;
      case 'weightUnit':
        newState = state.copyWith(weightUnit: event.value);
        break;
      case 'height':
        newState = state.copyWith(height: double.tryParse(event.value.toString()));
        break;
      default:
        newState = state;
    }

    // Calculate progress
    int filledFields = 0;
    if (newState.fullName.isNotEmpty) filledFields++;
    if (newState.age != null) filledFields++;
    if (newState.weight != null) filledFields++;
    if (newState.height != null) filledFields++;

    double progress = filledFields / 4.0;
    emit(newState.copyWith(progress: progress));
  }

  Future<void> _onSubmitOnboarding(SubmitOnboarding event, Emitter<OnboardingState> emit) async {
    if (state.progress < 1.0) return;

    emit(state.copyWith(status: OnboardingStatus.loading));
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': event.email,
          'fullName': state.fullName,
          'age': state.age,
          'weight': state.weight,
          'height': state.height,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        emit(state.copyWith(status: OnboardingStatus.completed));
      } else {
        emit(state.copyWith(status: OnboardingStatus.error));
      }
    } catch (e) {
      emit(state.copyWith(status: OnboardingStatus.error));
    }
  }
}
