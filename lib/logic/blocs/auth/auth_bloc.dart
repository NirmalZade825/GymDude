import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
 
  final String baseUrl = 'http://192.168.1.42:3000'; 

  AuthBloc() : super(AuthState.initial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<SocialLoginRequested>(_onSocialLoginRequested);
    on<ProfileCompleted>(_onProfileCompleted);
    on<UpdateGoals>(_onUpdateGoals);
    on<LogoutRequested>(_onLogoutRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  Future<void> _onUpdateGoals(UpdateGoals event, Emitter<AuthState> emit) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-goals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': state.email,
          'targetCalories': event.targetCalories,
          'targetProtein': event.targetProtein,
          'waterGoal': event.waterGoal,
        }),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('target_calories', event.targetCalories);
        await prefs.setInt('target_protein', event.targetProtein);
        await prefs.setDouble('water_goal', event.waterGoal);
        
        emit(state.copyWith(
          targetCalories: event.targetCalories,
          targetProtein: event.targetProtein,
          waterGoal: event.waterGoal,
        ));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error updating goals: $e');
    }
  }

  Future<void> _onProfileCompleted(ProfileCompleted event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_profile_complete', true);
    await prefs.setString('user_full_name', event.fullName);
    await prefs.setInt('user_age', event.age);
    await prefs.setDouble('user_weight', event.weight);
    await prefs.setDouble('user_height', event.height);
    await prefs.setString('user_gender', event.gender);
    await prefs.setDouble('user_activity_level', event.activityLevel);
    
    emit(state.copyWith(
      isProfileComplete: true,
      fullName: event.fullName,
      age: event.age,
      weight: event.weight,
      height: event.height,
      gender: event.gender,
      activityLevel: event.activityLevel,
    ));
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final fullName = prefs.getString('user_full_name');
    final age = prefs.getInt('user_age');
    final weight = prefs.getDouble('user_weight');
    final height = prefs.getDouble('user_height');
    final gender = prefs.getString('user_gender');
    final activityLevel = prefs.getDouble('user_activity_level') ?? 1.2;
    final targetCalories = prefs.getInt('target_calories') ?? 2500;
    final targetProtein = prefs.getInt('target_protein') ?? 180;
    final waterGoal = prefs.getDouble('water_goal') ?? 3.0;
    final isComplete = prefs.getBool('is_profile_complete') ?? false;

    if (email != null) {
      emit(AuthState(
        status: AuthStatus.authenticated,
        email: email,
        fullName: fullName,
        age: age,
        weight: weight,
        height: height,
        gender: gender,
        activityLevel: activityLevel,
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        waterGoal: waterGoal,
        isProfileComplete: isComplete,
      ));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }


// login
  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': event.email, 'password': event.password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['user'];
        final isComplete = userData['isProfileComplete'] ?? false;
        final fullName = userData['fullName'];
        final age = userData['age'];
        final weight = (userData['weight'] as num?)?.toDouble();
        final height = (userData['height'] as num?)?.toDouble();
        final gender = userData['gender'];
        final activityLevel = (userData['activityLevel'] as num?)?.toDouble() ?? 1.2;
        final targetCalories = userData['targetCalories'] ?? 2500;
        final targetProtein = userData['targetProtein'] ?? 180;
        
        // Save session locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', event.email);
        await prefs.setBool('is_profile_complete', isComplete);
        if (fullName != null) await prefs.setString('user_full_name', fullName);
        if (age != null) await prefs.setInt('user_age', age);
        if (weight != null) await prefs.setDouble('user_weight', weight);
        if (height != null) await prefs.setDouble('user_height', height);
        if (gender != null) await prefs.setString('user_gender', gender);
        await prefs.setDouble('user_activity_level', activityLevel);
        await prefs.setInt('target_calories', targetCalories);
        await prefs.setInt('target_protein', targetProtein);
        await prefs.setDouble('water_goal', (userData['waterGoal'] as num?)?.toDouble() ?? 3.0);

        emit(AuthState(
          status: AuthStatus.authenticated,
          email: event.email,
          fullName: fullName,
          age: age,
          weight: weight,
          height: height,
          gender: gender,
          activityLevel: activityLevel,
          targetCalories: targetCalories,
          targetProtein: targetProtein,
          waterGoal: (userData['waterGoal'] as num?)?.toDouble() ?? 3.0,
          isProfileComplete: isComplete,
        ));
      } else {
        emit(AuthState(
          status: AuthStatus.error,
          errorMessage: data['message'] ?? 'Login failed',
        ));
      }
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }


  //registration
  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': event.email, 'password': event.password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        // After registration, move to registrationSuccess state instead of auto-authenticating
        emit(const AuthState(status: AuthStatus.registrationSuccess));
      } else {
        emit(AuthState(
          status: AuthStatus.error,
          errorMessage: data['message'] ?? 'Registration failed',
        ));
      }
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSocialLoginRequested(SocialLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState(status: AuthStatus.loading));
    await Future.delayed(const Duration(seconds: 1));
    emit(const AuthState(status: AuthStatus.authenticated));
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_full_name');
    await prefs.remove('user_age');
    await prefs.remove('user_weight');
    await prefs.remove('user_height');
    await prefs.remove('user_gender');
    await prefs.remove('user_activity_level');
    await prefs.remove('is_profile_complete');
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onUpdateProfileRequested(UpdateProfileRequested event, Emitter<AuthState> emit) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': state.email,
          'fullName': event.fullName,
          'age': event.age,
          'weight': event.weight,
          'height': event.height,
          'gender': event.gender,
          'activityLevel': event.activityLevel,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_full_name', event.fullName);
        await prefs.setInt('user_age', event.age);
        await prefs.setDouble('user_weight', event.weight);
        await prefs.setDouble('user_height', event.height);
        await prefs.setString('user_gender', event.gender);
        await prefs.setDouble('user_activity_level', event.activityLevel);

        emit(state.copyWith(
          fullName: event.fullName,
          age: event.age,
          weight: event.weight,
          height: event.height,
          gender: event.gender,
          activityLevel: event.activityLevel,
        ));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error updating profile: $e');
    }
  }
}
