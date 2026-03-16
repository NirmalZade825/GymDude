import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashState.initial()) {
    on<StartSplash>(_onStartSplash);
  }

  Future<void> _onStartSplash(StartSplash event, Emitter<SplashState> emit) async {
    emit(const SplashState(status: SplashStatus.loading, progress: 0.0));
    
    // Simulate loading/initialization
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      emit(SplashState(status: SplashStatus.loading, progress: i / 100));
    }

    emit(const SplashState(status: SplashStatus.completed, progress: 1.0));
  }
}
