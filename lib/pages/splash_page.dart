import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/splash/splash_bloc.dart';
import '../logic/blocs/splash/splash_state.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/auth/auth_state.dart';
import './login_page.dart';
import './bottom.dart';
import './profile_setup_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state.status == SplashStatus.completed) {
          final authState = context.read<AuthBloc>().state;
          
          if (authState.status == AuthStatus.authenticated) {
            if (authState.isProfileComplete) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const Bottom()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
              );
            }
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }
        }
      },
      child: const Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _SplashBackground(),
            _SplashContent(),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/splash_bg.png',
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
                Colors.black,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(flex: 2),
          _SplashLogoSection(),
          SizedBox(height: 30),
          _SplashTitleSection(),
          Spacer(flex: 3),
          _SplashLoadingSection(),
          SizedBox(height: 40),
          _SplashFooterSection(),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SplashLogoSection extends StatelessWidget {
  const _SplashLogoSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0FF00).withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset('assets/gym_logo.png'),
      ),
    );
  }
}

class _SplashTitleSection extends StatelessWidget {
  const _SplashTitleSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'GYMDUDE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        Text(
          'ASCEND BEYOND',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

class _SplashLoadingSection extends StatelessWidget {
  const _SplashLoadingSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplashBloc, SplashState>(
      builder: (context, state) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: const Text(
                'INITIALIZING PROFILE...',
                style: TextStyle(
                  color: Color(0xFFC0FF00),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFC0FF00),
                  ),
                  minHeight: 2,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SplashFooterSection extends StatelessWidget {
  const _SplashFooterSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'PREMIUM ACCESS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'V2.4.0',
            style: TextStyle(
              color: Color(0xFFC0FF00),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
