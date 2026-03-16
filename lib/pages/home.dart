import 'package:blo_trial/logic/blocs/auth/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/auth/auth_state.dart';
import '../logic/services/food_api_service.dart';
import 'tracked_food_list_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FoodApiService _apiService = FoodApiService();
  DailyNutritionResult? _nutritionData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyNutrition();
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
                      onPressed: _loadDailyNutrition,
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
                    onPressed: () {},
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
            onPressed: () {},
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
                        onTap: () => _showGoalDialog(context, targetCalories, state.targetProtein),
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
                    onTap: () => _showGoalDialog(context, state.targetCalories, targetProtein),
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

  void _showGoalDialog(BuildContext context, int currentCal, int currentProt) {
    final calController = TextEditingController(text: currentCal.toString());
    final protController = TextEditingController(text: currentProt.toString());

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
              context.read<AuthBloc>().add(UpdateGoals(targetCalories: newCal, targetProtein: newProt));
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
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
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chest & \nTriceps',
                      style: TextStyle(
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
                      child: const Text('STRENGTH', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  '45 mins • 8 exercises',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}