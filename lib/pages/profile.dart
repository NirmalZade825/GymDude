import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/auth/auth_event.dart';
import '../logic/blocs/auth/auth_state.dart';
import './login_page.dart';
import './update_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return Stack(
            children: [
              // Background Gradient
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFC0FF00).withOpacity(0.05),
                  ),
                ),
              ),
              
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildProfileHeader(state),
                          const SizedBox(height: 40),
                          _buildStatsSection(state),
                          const SizedBox(height: 40),
                          _buildSettingsSection(context, state),
                          const SizedBox(height: 40),
                          _buildLogoutButton(context),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AuthState state) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFC0FF00).withOpacity(0.5),
                    const Color(0xFFC0FF00).withOpacity(0.1),
                  ],
                ),
              ),
              child: const CircleAvatar(
                radius: 65,
                backgroundColor: Color(0xFF1E1E1E),
                child: Icon(Icons.person, color: Color(0xFFC0FF00), size: 80),
              ),
            ),
            // Container(
            //   padding: const EdgeInsets.all(8),
            //   decoration: const BoxDecoration(
            //     color: Color(0xFFC0FF00),
            //     shape: BoxShape.circle,
            //     boxShadow: [
            //       BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
            //     ],
            //   ),
            //   child: const Icon(Icons.edit_outlined, color: Colors.black, size: 20),
            // ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          state.fullName ?? 'Gym Enthusiast',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          state.email ?? 'gymdude@example.com',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(AuthState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('AGE', '${state.age ?? '--'}', 'Years', Icons.calendar_today),
        const SizedBox(width: 12),
        _buildStatCard('WEIGHT', '${state.weight ?? '--'}', 'KG', Icons.monitor_weight),
        const SizedBox(width: 12),
        _buildStatCard('HEIGHT', '${state.height ?? '--'}', 'CM', Icons.height),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(icon, color: const Color(0xFFC0FF00).withOpacity(0.5), size: 18),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFFC0FF00),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREFERENCES',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        _buildGlassMenuItem(
          Icons.track_changes, 
          'Daily Nutrition Goals', 
          subtitle: 'Update your intake targets',
          onTap: () => _showGoalDialog(context, state.targetCalories, state.targetProtein, state.waterGoal),
        ),
        _buildGlassMenuItem(
          Icons.person_outline, 
          'Update Profile Info', 
          subtitle: 'Change name, age, etc.',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateProfilePage())),
        ),
        _buildGlassMenuItem(Icons.notifications_none, 'Notification Settings', subtitle: 'Manage reminders'),
        _buildGlassMenuItem(Icons.security, 'Security & Privacy', subtitle: 'Account protection'),
      ],
    );
  }

  Widget _buildGlassMenuItem(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFC0FF00), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          context.read<AuthBloc>().add(LogoutRequested());
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          foregroundColor: Colors.redAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
          ),
        ),
        child: const Text(
          'SIGN OUT',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
    );
  }

  void _showGoalDialog(BuildContext context, int currentCal, int currentProt, double currentWater) {
    final calController = TextEditingController(text: currentCal.toString());
    final protController = TextEditingController(text: currentProt.toString());
    final waterController = TextEditingController(text: currentWater.toString());

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: const Text(
            'Refine Daily Goals', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField('Daily Calories', calController, Icons.local_fire_department),
              const SizedBox(height: 16),
              _buildDialogField('Protein Target (g)', protController, Icons.fitness_center),
              const SizedBox(height: 16),
              _buildDialogField('Water Goal (Litr)', waterController, Icons.water_drop),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
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
                  const SnackBar(
                    content: Text('Goals synchronized!'), 
                    backgroundColor: Color(0xFFC0FF00),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0FF00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('SAVE GOALS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: const Color(0xFFC0FF00), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}
