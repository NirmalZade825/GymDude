import 'package:equatable/equatable.dart';

enum SplashStatus { initial, loading, completed }

class SplashState extends Equatable {
  final SplashStatus status;
  final double progress;

  const SplashState({
    required this.status,
    required this.progress,
  });

  factory SplashState.initial() => const SplashState(
        status: SplashStatus.initial,
        progress: 0.0,
      );

  @override
  List<Object> get props => [status, progress];
}
