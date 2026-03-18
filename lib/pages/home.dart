import 'package:gym_dude/logic/blocs/auth/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/auth/auth_state.dart';
import '../logic/services/food_api_service.dart';
import '../logic/services/workout_api_service.dart';
import 'tracked_food_list_page.dart';
import 'workout.dart';
import 'notifications_page.dart';
import '../logic/services/notification_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FoodApiService _apiService = FoodApiService();
  final WorkoutApiService _workoutApiService = WorkoutApiService();
  DailyNutritionResult? _nutritionData;
  Map<String, dynamic>? _workoutData;
  bool _isLoading = true;
  bool _isWorkoutLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadDailyNutrition(),
      _loadDailyWorkout(),
    ]);
  }

  Future<void> _loadDailyWorkout() async {
    setState(() { _isWorkoutLoading = true; });
    final authState = context.read<AuthBloc>().state;
    final email = authState.email;
    
    if (email != null && email.isNotEmpty) {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final result = await _workoutApiService.getDailyWorkouts(email, dateStr);
      if (mounted) {
        setState(() {
          _workoutData = result;
          _isWorkoutLoading = false;
        });
      }
    } else {
      if (mounted) setState(() { _isWorkoutLoading = false; });
    }
  }

  Future<void> _loadDailyNutrition() async {
    setState(() { _isLoading = true; });
    final authState = context.read<AuthBloc>().state;
    final email = authState.email;
    
    if (email != null && email.isNotEmpty) {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final result = await _apiService.getDailyNutrition(email, dateStr);
      if (mounted) {
        setState(() {
          _nutritionData = result;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Darker background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 30),
              
              // Daily Nutrition Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Nutrition',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Orbitron', // Assuming a futuristic font, falling back to default if unavailable
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC0FF00)),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                      onPressed: _loadAllData,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Calories Card
              _buildCaloriesCard(),
              const SizedBox(height: 20),
              
              // Protein & Food Type Cards
              Row(
                children: [
                  Expanded(child: _buildProteinCard()),
                  const SizedBox(width: 15),
                  Expanded(child: _buildFoodTypeCard()),
                ],
              ),
              const SizedBox(height: 15),
              _buildWaterCard(),
              const SizedBox(height: 15),
              const SizedBox(height: 30),
              
              // Your Plan Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WorkoutPage()),
                      ).then((_) => _loadDailyWorkout());
                    },
                    child: const Text(
                      'SEE ALL',
                      style: TextStyle(
                        color: Color(0xFFC0FF00), // Lime green
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),
              
              // Plan Card
              _buildPlanCard(),
              const SizedBox(height: 80), // Space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final displayName = (state.fullName?.isNotEmpty == true 
            ? state.fullName!.toUpperCase() 
            : 'JAMES');
            
        return Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.amber[100],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HI $displayName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Fitness Freak',
                  style: TextStyle(
                    color: Color(0xFFC0FF00), // Lime green
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        const Spacer(),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
        )
      ],
    );
      },
    );
  }

  Widget _buildCaloriesCard() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final caloriesEaten = _nutritionData?.totalCalories ?? 0;
        final targetCalories = state.targetCalories;
        final caloriesLeft = targetCalories - caloriesEaten > 0 ? targetCalories - caloriesEaten : 0;
        final percentVal = (caloriesEaten / targetCalories).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CALORIES LEFT',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$caloriesLeft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '+12% from yesterday',
                    style: TextStyle(color: Color(0xFFC0FF00), fontSize: 10),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showGoalDialog(context, targetCalories, state.targetProtein, state.waterGoal),
                        child: _buildMiniStat('Target', '$targetCalories'),
                      ),
                      const SizedBox(width: 20),
                      _buildMiniStat('Eaten', '$caloriesEaten'),
                    ],
                  )
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: percentVal,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC0FF00)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(percentVal * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
           const SizedBox(height: 2),
           Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProteinCard() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final proteinEaten = _nutritionData?.totalProtein.toInt() ?? 0;
        final targetProtein = state.targetProtein;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFD6C8FF), // Light purple
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.egg_alt_outlined, color: Colors.black, size: 20),
              ),
              const SizedBox(height: 15),
              const Text('PROTEIN', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('${proteinEaten}g', style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w300)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showGoalDialog(context, state.targetCalories, targetProtein, state.waterGoal),
                    child: Text('GOAL: ${targetProtein}g', style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.show_chart, color: Colors.black87, size: 16),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _showGoalDialog(BuildContext context, int currentCal, int currentProt, double currentWater) {
    final calController = TextEditingController(text: currentCal.toString());
    final protController = TextEditingController(text: currentProt.toString());
    final waterController = TextEditingController(text: currentWater.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Update Daily Goals', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Daily Calories',
                labelStyle: TextStyle(color: Color(0xFFC0FF00)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: protController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Daily Protein (g)',
                labelStyle: TextStyle(color: Color(0xFFC0FF00)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: waterController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Daily Water Goal (L)',
                labelStyle: TextStyle(color: Color(0xFFC0FF00)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              final newCal = int.tryParse(calController.text) ?? currentCal;
              final newProt = int.tryParse(protController.text) ?? currentProt;
              final newWater = double.tryParse(waterController.text) ?? currentWater;
              context.read<AuthBloc>().add(UpdateGoals(
                targetCalories: newCal, 
                targetProtein: newProt,
                waterGoal: newWater,
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goals updated successfully!'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0FF00)),
            child: const Text('SAVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTypeCard() {
    final hasLogs = _nutritionData != null && _nutritionData!.logs.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrackedFoodListPage()),
        ).then((_) {
          _loadDailyNutrition();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant, color: Color(0xFFC0FF00), size: 20),
            ),
            const SizedBox(height: 15),
            const Text('TRACKED', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            Text(hasLogs ? '${_nutritionData!.logs.length}\nItems' : 'None\nYet', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300, height: 1.2)),
            const SizedBox(height: 5),
            Row(
               children: [
                 _buildFoodIcon('🥗'),
                 const SizedBox(width: 4),
                 _buildFoodIcon('🥩'),
               ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFoodIcon(String emoji) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildPlanCard() {
    if (_isWorkoutLoading) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: Color(0xFFC0FF00)),
      );
    }

    final hasWorkouts = _workoutData != null && _workoutData!['data'] != null && _workoutData!['data']['logs'] != null && (_workoutData!['data']['logs'] as List).isNotEmpty;
    
    if (!hasWorkouts) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WorkoutPage()),
          ).then((_) => _loadDailyWorkout());
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.add, color: Color(0xFFC0FF00), size: 30),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No workout yet',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tap to add exercises for today',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    }

    final logs = _workoutData!['data']['logs'] as List;
    final count = logs.length;
    final firstExercise = logs[0]['exerciseName'] ?? 'Exercise';
    final muscle = logs[0]['muscleGroup'] ?? 'STRENGTH';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0FF00).withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFC0FF00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.fitness_center, color: Color(0xFFC0FF00), size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          count > 1 ? '$firstExercise & \n${count - 1} more' : firstExercise,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6C8FF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(muscle.toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Today\'s Plan • $count exercises',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              )
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: 15),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        logs[index]['exerciseName'],
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () => _showGoalDialog(context, state.targetCalories, state.targetProtein, state.waterGoal),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE3FFB7), // Light lime/yellowish
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop, color: Colors.blueAccent, size: 22),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HYDRATION', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('Daily Goal: ${state.waterGoal}L', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const Expanded(
                  child: Text(
                    'Drink 250ml every hour!',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
