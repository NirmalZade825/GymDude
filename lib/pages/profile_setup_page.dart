import 'package:gym_dude/logic/blocs/auth/auth_bloc.dart';
import 'package:gym_dude/logic/blocs/auth/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/onboarding/onboarding_bloc.dart';
import '../logic/blocs/onboarding/onboarding_event.dart';
import '../logic/blocs/onboarding/onboarding_state.dart';
import './bottom.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.status == OnboardingStatus.completed) {
          context.read<AuthBloc>().add(ProfileCompleted(
            fullName: state.fullName,
            age: state.age ?? 0,
            weight: state.weight ?? 0.0,
            height: state.height ?? 0.0,
            gender: state.gender ?? 'Male',
            activityLevel: state.activityLevel,
          ));
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const Bottom()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        _LogoIconSmall(),
                        const SizedBox(width: 8),
                        const Text(
                          'GYMDUDE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Title
                const Text(
                  "Let's get to\nknow you.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                // Progress Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'PROFILE SETUP',
                      style: TextStyle(
                        color: Color(0xFFC0FF00),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Step 2 of 3',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BlocBuilder<OnboardingBloc, OnboardingState>(
                  builder: (context, state) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: state.progress,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC0FF00)),
                        minHeight: 4,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50),
                // Form Fields
                _buildLabel('FULL NAME'),
                _buildField(
                  icon: Icons.person_outline,
                  hint: 'James Carter',
                  onChanged: (val) => context.read<OnboardingBloc>().add(UpdateField(fieldName: 'fullName', value: val)),
                ),
                const SizedBox(height: 30),
                _buildLabel('AGE'),
                _buildField(
                  icon: Icons.calendar_today_outlined,
                  hint: '25',
                  keyboardType: TextInputType.number,
                  onChanged: (val) => context.read<OnboardingBloc>().add(UpdateField(fieldName: 'age', value: val)),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('WEIGHT'),
                    _WeightToggle(),
                  ],
                ),
                _buildField(
                  icon: Icons.monitor_weight_outlined,
                  hint: '82.5',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => context.read<OnboardingBloc>().add(UpdateField(fieldName: 'weight', value: val)),
                ),
                const SizedBox(height: 30),
                _buildLabel('HEIGHT (CM)'),
                _buildField(
                  icon: Icons.height,
                  hint: '180',
                  keyboardType: TextInputType.number,
                  onChanged: (val) => context.read<OnboardingBloc>().add(UpdateField(fieldName: 'height', value: val)),
                ),
                const SizedBox(height: 30),
                _buildLabel('GENDER'),
                _GenderSelector(),
                const SizedBox(height: 30),
                _buildLabel('ACTIVITY LEVEL'),
                _ActivityLevelSelector(),
                const SizedBox(height: 50),
                // Submit Button
                _CompleteProfileButton(),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Step 2 of 3 • You can change this later in settings',
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required String hint,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.white38, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _LogoIconSmall extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFC0FF00),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fitness_center, color: Colors.black, size: 16),
    );
  }
}

class _WeightToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
      final isKg = state.weightUnit == 'KG';
      return Container(
        height: 32,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _toggleItem('KG', isKg, context),
            _toggleItem('LBS', !isKg, context),
          ],
        ),
      );
    });
  }

  Widget _toggleItem(String label, bool active, BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<OnboardingBloc>().add(UpdateField(fieldName: 'weightUnit', value: label)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFC0FF00) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return Row(
          children: [
            _genderItem('Male', state.gender == 'Male', context),
            const SizedBox(width: 12),
            _genderItem('Female', state.gender == 'Female', context),
          ],
        );
      },
    );
  }

  Widget _genderItem(String label, bool active, BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<OnboardingBloc>().add(UpdateField(fieldName: 'gender', value: label)),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFC0FF00) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: active ? Colors.transparent : Colors.white.withOpacity(0.1)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.black : Colors.white60,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityLevelSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final levels = [
      {'label': 'Sedentary', 'value': 1.2},
      {'label': 'Light', 'value': 1.375},
      {'label': 'Moderate', 'value': 1.55},
      {'label': 'Active', 'value': 1.725},
    ];

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: levels.map((level) {
            final active = state.activityLevel == level['value'];
            return GestureDetector(
              onTap: () => context.read<OnboardingBloc>().add(UpdateField(fieldName: 'activityLevel', value: level['value'].toString())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFC0FF00) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: active ? Colors.transparent : Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  level['label'] as String,
                  style: TextStyle(
                    color: active ? Colors.black : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CompleteProfileButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final isFilled = state.progress == 1.0;
        final isLoading = state.status == OnboardingStatus.loading;
        
        return Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: isFilled
                ? const LinearGradient(
                    colors: [Color(0xFFC0FF00), Color(0xFF76BA1B)],
                  )
                : null,
            color: isFilled ? null : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                        color: const Color(0xFFC0FF00).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8)),
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: (isFilled && !isLoading)
                ? () {
                    final email = context.read<AuthBloc>().state.email ?? '';
                    context.read<OnboardingBloc>().add(SubmitOnboarding(email: email));
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFilled ? Colors.transparent : Colors.white.withOpacity(0.05),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                  )
                : Text(
                    'COMPLETE PROFILE',
                    style: TextStyle(
                      color: isFilled ? Colors.black : Colors.white24,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
