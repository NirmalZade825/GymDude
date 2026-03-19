import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'dart:ui';


import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/services/progress_api_service.dart';
import '../logic/utils/composition_calculator.dart';

class Progress extends StatefulWidget {
  const Progress({super.key});

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _staggerAnimation;

  final ProgressApiService _apiService = ProgressApiService();
  ProgressData? _progressData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    _staggerAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );

    _loadProgressData();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);
    final email = context.read<AuthBloc>().state.email;
    if (email != null && email.isNotEmpty) {
      final data = await _apiService.getProgressData(email);
      if (mounted) {
        setState(() {
          _progressData = data;
          _isLoading = false;
        });
        _mainController.forward(from: 0);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make appBar transparent for background glows
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'YOUR PROGRESS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              onPressed: _loadProgressData,
            )
        ],
      ),
      extendBodyBehindAppBar: true, 
      body: _isLoading

          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC0FF00)))
          : _progressData == null
              ? const Center(child: Text('Failed to load progress data', style: TextStyle(color: Colors.white)))
              : Stack(
                  children: [
                    // Dynamic Background Glows
                    _buildBackgroundGlows(),
                    
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 60,
                        left: 20,
                        right: 20,
                        bottom: 100,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnimatedSection(0.0, 0.4, _buildProgressHero(_progressData!)),
                          const SizedBox(height: 24),
                          _buildAnimatedSection(0.1, 0.5, _buildStreakCard(_progressData!)),
                          const SizedBox(height: 24),
                          _buildAnimatedSection(0.2, 0.6, _buildBMICard(_progressData!)),
                          const SizedBox(height: 24),
                          _buildAnimatedSection(0.3, 0.7, _buildMuscleFocusCard(_progressData!)),
                          const SizedBox(height: 24),
                          _buildAnimatedSection(0.4, 0.8, _buildNutritionJourneyCard(_progressData!)),
                          const SizedBox(height: 24),
                          _buildAnimatedSection(0.45, 0.85, _buildCompositionPredictionCard(_progressData!)),
                          const SizedBox(height: 24),
                          _buildAnimatedSection(0.5, 0.9, _buildGithubHeatmap(_progressData!)),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }


  Widget _buildAnimatedSection(double start, double end, Widget child) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _mainController, curve: Interval(start, end, curve: Curves.easeOut)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _mainController, curve: Interval(start, end, curve: Curves.easeOutCubic)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildProgressHero(ProgressData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC0FF00).withOpacity(0.15),
            const Color(0xFF1E1E1E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFC0FF00).withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEKLY TARGET',
                    style: TextStyle(
                      color: const Color(0xFFC0FF00).withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Elite Challenger',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'LVL 5',
                  style: TextStyle(
                    color: Color(0xFFC0FF00),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _heroStat("WORKOUTS", "05", "This week"),
              const SizedBox(width: 30),
              _heroStat("POINTS", "500", "+12% total"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          sub,
          style: const TextStyle(
            color: Color(0xFFC0FF00),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundGlows() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC0FF00).withOpacity(0.12),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -50,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6C8FF).withOpacity(0.08),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionJourneyCard(ProgressData data) {
    final last7Days = data.nutritionJourney;
    final targetCalories = context.watch<AuthBloc>().state.targetCalories;
    final todayCalories = last7Days.isNotEmpty ? last7Days.last.toInt() : 0;

   
    final List<double> alignedDays = List.filled(7, 0.0);
    if (last7Days.isNotEmpty) {
      final int todayWeekday = DateTime.now().weekday;
      for (int i = 0; i < 7; i++) {
       
        final int dataIndex = (last7Days.length - 1) - (todayWeekday - 1) + i;
        if (dataIndex >= 0 && dataIndex < last7Days.length) {
          alignedDays[i] = last7Days[dataIndex];
        }
      }
    }
    
    final String trendText = "${todayCalories >= targetCalories ? 'Above' : 'Below'} Target"; 

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nutrition Journey'.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Goal: $targetCalories kcal',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$todayCalories',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  'KCAL',
                  style: TextStyle(
                    color: Color(0xFFC0FF00),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              _trendBadge(trendText),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return CustomPaint(
                  painter: NutritionJourneyPainter(
                    data: alignedDays,
                    targetCalories: targetCalories.toDouble(),
                    animationValue: CurvedAnimation(
                      parent: _mainController,
                      curve: const Interval(0.5, 0.9, curve: Curves.easeInOutQuart),
                    ).value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 35.0), // Match graph start
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                  .map((day) => Expanded(
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompositionPredictionCard(ProgressData data) {
    final authState = context.watch<AuthBloc>().state;
    
    // Fallback values if profile is incomplete
    final weight = authState.weight ?? 70.0;
    final height = authState.height ?? 175.0;
    final age = authState.age ?? 25;
    final gender = authState.gender ?? 'male';
    final activityLevel = authState.activityLevel;
    final targetProtein = authState.targetProtein.toDouble();

    final last7Days = data.nutritionJourney;
    final double todayCalories = last7Days.isNotEmpty ? last7Days.last : 0.0;
    
    // BMR and Needed Calories
    final double bmr = BodyCompositionCalculator.calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );
    final double caloriesNeeded = bmr * activityLevel;

    // Predicted change based on today's performance
    final prediction = BodyCompositionCalculator.calculateCompositionChanges(
      caloriesIntake: todayCalories,
      caloriesNeeded: caloriesNeeded,
      proteinIntake: targetProtein, // Using target as estimate since real-time protein might not be in progressData
      currentWeight: weight,
    );

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Composition Prediction'.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _predictionStat(
                  "MUSCLE SHIFT",
                  "${prediction.muscleChange >= 0 ? '+' : ''}${(prediction.muscleChange * 1000).toStringAsFixed(1)}g",
                  prediction.muscleChange >= 0 ? const Color(0xFFC0FF00) : Colors.redAccent,
                  Icons.fitness_center,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              Expanded(
                child: _predictionStat(
                  "FAT SHIFT",
                  "${prediction.fatChange >= 0 ? '+' : ''}${(prediction.fatChange * 1000).toStringAsFixed(1)}g",
                  prediction.fatChange <= 0 ? const Color(0xFFD6C8FF) : Colors.orangeAccent,
                  Icons.opacity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white.withOpacity(0.3), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Predictions based on BMR (${bmr.toInt()} kcal) and current balance.",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.5), size: 16),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white24,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(ProgressData data) {
    return _glassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0FF00).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flash_on, color: Color(0xFFC0FF00), size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consistency'.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Active Streak',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFC0FF00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC0FF00).withOpacity(0.2)),
            ),
            child: Text(
              '${data.streakDays} DAYS',
              style: const TextStyle(
                color: Color(0xFFC0FF00),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
        ],
      ),
    );
  }


  Widget _buildGithubHeatmap(ProgressData data) {
    final int columns = 14; // Reduce columns for mobile better fit
    final activeDatesSet = data.activeDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    final int rowIndexToday = today.weekday - 1;

    return _glassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Map'.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 10),
                    _dayLabel('M'),
                    const SizedBox(height: 25),
                    _dayLabel('W'),
                    const SizedBox(height: 25),
                    _dayLabel('F'),
                    const SizedBox(height: 10),
                  ],
                ),
                const SizedBox(width: 10),
                Row(
                  children: List.generate(columns, (colIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Column(
                        children: List.generate(7, (rowIndex) {
                          int daysFromToday = (columns - 1 - colIndex) * 7 + (rowIndexToday - rowIndex);
                          
                          if (daysFromToday < 0) {
                            return Container(
                              width: 15,
                              height: 15,
                              margin: const EdgeInsets.only(bottom: 6.0),
                              decoration: BoxDecoration(
                                color: Colors.transparent, 
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }

                          final cellDate = normalizedToday.subtract(Duration(days: daysFromToday));
                          final isActive = activeDatesSet.contains(cellDate);
                          
                          Color color;
                          if (isActive) {
                            color = const Color(0xFFC0FF00).withOpacity(
                              daysFromToday < 7 ? 1.0 : (daysFromToday < 30 ? 0.7 : 0.4)
                            );
                          } else {
                            color = Colors.white.withOpacity(0.05);
                          }

                          return Container(
                            width: 15,
                            height: 15,
                            margin: const EdgeInsets.only(bottom: 6.0),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: isActive ? [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ] : [],
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _dayLabel(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10));
  }

  Widget _buildBMICard(ProgressData data) {
    Color getCategoryColor(String category) {
      if (category.toLowerCase().contains('normal')) return const Color(0xFFC0FF00); // Lime green
      if (category.toLowerCase().contains('under')) return const Color(0xFF8DE2FF); // Light blue
      if (category.toLowerCase().contains('over')) return Colors.orangeAccent;
      if (category.toLowerCase().contains('obese')) return Colors.redAccent;
      return Colors.white;
    }
    
    final color = getCategoryColor(data.bmiCategory);

    return _glassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR DYNAMIC BMI',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data.adjustedWeight} kg',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1500),
            tween: Tween<double>(begin: 0, end: (data.bmi / 40).clamp(0.0, 1.0)), 
            curve: Curves.easeOutQuart,
            builder: (context, val, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: val,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.bmi.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.bmiCategory.toUpperCase(),
                        style: TextStyle(
                          color: color, 
                          fontSize: 10, 
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recalculating BMI from diet history...'), duration: Duration(seconds: 1)),
              );
              _loadProgressData();
            },
            icon: const Icon(Icons.calculate, color: Colors.black, size: 18),
            label: const Text('CALCULATE BMI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0FF00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMuscleFocusCard(ProgressData data) {
    final labels = data.radarData.labels;
    final values = data.radarData.values;

    return _glassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscle Focus'.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: SizedBox(
              width: 220,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(180, 180),
                        painter: RadarChartPainter(
                          values,
                          const Color(0xFFC0FF00),
                          animationValue: CurvedAnimation(
                            parent: _mainController,
                            curve: const Interval(0.4, 0.8, curve: Curves.easeOutQuart),
                          ).value,
                        ),
                      );
                    }
                  ),

                  // Render labels
                  ...List.generate(labels.length, (i) {
                    final angleScope = (2 * math.pi) / labels.length;
                    final angle = -math.pi / 2 + i * angleScope;
                    final radius = 110.0; 
                    final x = radius * math.cos(angle);
                    final y = radius * math.sin(angle);
                    return Positioned(
                      left: 110 + x - 25, 
                      top: 100 + y - 10,
                      child: SizedBox(
                        width: 50,
                        child: Text(
                          labels[i].toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    );
                  })
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- Aesthetic Helper Widgets ---

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }


  Widget _trendBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFC0FF00).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFC0FF00),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

}

class RadarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double animationValue;

  RadarChartPainter(this.values, this.color, {required this.animationValue});


  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);

    final angleScope = (2 * math.pi) / values.length;

    final bgPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 3; ring++) {
      final ringRadius = radius * (ring / 3);
      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final angle = -math.pi / 2 + i * angleScope;
        final x = center.dx + ringRadius * math.cos(angle);
        final y = center.dy + ringRadius * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, bgPaint);
    }

    for (int i = 0; i < values.length; i++) {
        final angle = -math.pi / 2 + i * angleScope;
        final x = center.dx + radius * math.cos(angle);
        final y = center.dy + radius * math.sin(angle);
        canvas.drawLine(center, Offset(x, y), bgPaint);
    }

    final valuePath = Path();
    for (int i = 0; i < values.length; i++) {
        final angle = -math.pi / 2 + i * angleScope;
        // Clamp values to 0-1 range and apply animation
        final valRadius = radius * (values[i].clamp(0.0, 1.0) * animationValue);
        final x = center.dx + valRadius * math.cos(angle);
        final y = center.dy + valRadius * math.sin(angle);

        if (i == 0) {
          valuePath.moveTo(x, y);
        } else {
          valuePath.lineTo(x, y);
        }
    }
    valuePath.close();

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class NutritionJourneyPainter extends CustomPainter {
  final List<double> data;
  final double animationValue;
  final double targetCalories;

  NutritionJourneyPainter({
    required this.data, 
    required this.animationValue,
    required this.targetCalories,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double leftPadding = 35.0; 
    final double rightPadding = 10.0;
    final double topPadding = 10.0;
    final double bottomPadding = 5.0;
    
    final double graphWidth = size.width - leftPadding - rightPadding;
    final double graphHeight = size.height - topPadding - bottomPadding;

    // Determine max Y scale
    double maxDataVal = data.fold(0.0, (prev, element) => element > prev ? element : prev);
    double maxY = (maxDataVal > targetCalories ? maxDataVal : targetCalories) * 1.25;
    if (maxY < 1000) maxY = 1000;
    maxY = (maxY / 500).ceil() * 500.0;

    final double stepX = graphWidth / (data.length - 1);

    double getX(int index) => leftPadding + (index * stepX);
    double getY(double val) {
      final normalized = val / maxY;
      return topPadding + graphHeight - (normalized * graphHeight * animationValue);
    }

    // 1. Draw Grid Lines and Y-Axis Labels
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    int labelCount = 5;
    for (int i = 0; i < labelCount; i++) {
      double labelVal = (maxY / (labelCount - 1)) * i;
      double y = topPadding + graphHeight - ((labelVal / maxY) * graphHeight);
      
      // Draw horizontal line
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width - rightPadding, y), gridPaint);
      
      // Draw label
      textPainter.text = TextSpan(
        text: '${labelVal.toInt()}',
        style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // 2. Linear Path and Fill
    final pathPaint = Paint()
      ..color = const Color(0xFFC0FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFC0FF00).withOpacity(0.2),
          const Color(0xFFC0FF00).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(leftPadding, topPadding, graphWidth, graphHeight));

    final path = Path();
    final fillPath = Path();

    path.moveTo(getX(0), getY(data[0]));
    fillPath.moveTo(getX(0), topPadding + graphHeight);
    fillPath.lineTo(getX(0), getY(data[0]));

    for (int i = 1; i < data.length; i++) {
      path.lineTo(getX(i), getY(data[i]));
      fillPath.lineTo(getX(i), getY(data[i]));
    }

    fillPath.lineTo(getX(data.length - 1), topPadding + graphHeight);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, pathPaint);

    // 3. Draw Dots (Markers)
    final dotPaint = Paint()..color = const Color(0xFFC0FF00);
    final dotStrokePaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final glowPaint = Paint()..color = const Color(0xFFC0FF00).withOpacity(0.3);

    for (int i = 0; i < data.length; i++) {
      final center = Offset(getX(i), getY(data[i]));
      canvas.drawCircle(center, 6 * animationValue, glowPaint);
      canvas.drawCircle(center, 3.5, dotPaint);
      canvas.drawCircle(center, 3.5, dotStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
