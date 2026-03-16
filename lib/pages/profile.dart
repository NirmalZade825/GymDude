import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/auth/auth_event.dart';
import '../logic/blocs/auth/auth_state.dart';
import './login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Profile Header
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC0FF00), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white12,
                        child: Icon(Icons.person, color: Color(0xFFC0FF00), size: 70),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC0FF00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.black, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  state.fullName ?? 'Gym Enthusiast',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.email ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard('AGE', '${state.age ?? '--'}', 'Years'),
                      _buildStatCard('WEIGHT', '${state.weight ?? '--'}', 'KG'),
                      _buildStatCard('HEIGHT', '${state.height ?? '--'}', 'CM'),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Settings List
                _buildMenuItem(Icons.track_changes, 'Set Daily Goals', onTap: () {
                  _showGoalDialog(context, state.targetCalories, state.targetProtein);
                }),
                _buildMenuItem(Icons.person_outline, 'Profile Settings'),
                _buildMenuItem(Icons.notifications_none, 'Notifications'),
                _buildMenuItem(Icons.shield_outlined, 'Privacy & Security'),
                _buildMenuItem(Icons.help_outline, 'Help & Support'),

                const SizedBox(height: 40),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      foregroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                    ),
                    child: const Text(
                      'LOGOUT',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: Color(0xFFC0FF00), fontSize: 20, ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
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

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white38, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white12),
            ],
          ),
        ),
      ),
    );
  }
}
