import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/auth/auth_event.dart';
import '../logic/blocs/auth/auth_state.dart';

class UpdateProfilePage extends StatefulWidget {
  const UpdateProfilePage({super.key});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _activityLevelController;
  String _gender = 'Male';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _nameController = TextEditingController(text: authState.fullName ?? '');
    _ageController = TextEditingController(text: authState.age?.toString() ?? '');
    _weightController = TextEditingController(text: authState.weight?.toString() ?? '');
    _heightController = TextEditingController(text: authState.height?.toString() ?? '');
    _activityLevelController = TextEditingController(text: authState.activityLevel.toString());
    _gender = authState.gender ?? 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _activityLevelController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    setState(() => _isLoading = true);

    final String name = _nameController.text.trim();
    final int age = int.tryParse(_ageController.text) ?? 0;
    final double weight = double.tryParse(_weightController.text) ?? 0.0;
    final double height = double.tryParse(_heightController.text) ?? 0.0;
    final double activityLevel = double.tryParse(_activityLevelController.text) ?? 1.2;

    if (name.isEmpty || age <= 0 || weight <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields correctly.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    context.read<AuthBloc>().add(UpdateProfileRequested(
      fullName: name,
      age: age,
      weight: weight,
      height: height,
      gender: _gender,
      activityLevel: activityLevel,
    ));

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFFC0FF00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'UPDATE PROFILE',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Stack(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlassTextField('Full Name', _nameController, Icons.person_outline),
                  const SizedBox(height: 20),
                  _buildGlassTextField('Age', _ageController, Icons.calendar_today, isNumber: true),
                  const SizedBox(height: 20),
                  _buildGlassTextField('Weight (kg)', _weightController, Icons.monitor_weight_outlined, isNumber: true),
                  const SizedBox(height: 20),
                  _buildGlassTextField('Height (cm)', _heightController, Icons.height, isNumber: true),
                  const SizedBox(height: 20),
                  _buildGenderSelector(),
                  const SizedBox(height: 20),
                  _buildGlassTextField('Activity Level (1.2 - 2.0)', _activityLevelController, Icons.directions_run, isNumber: true),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC0FF00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                        shadowColor: const Color(0xFFC0FF00).withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'SAVE CHANGES',
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: const Color(0xFFC0FF00), size: 22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          dropdownColor: const Color(0xFF1E1E1E),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.3)),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          items: ['Male', 'Female', 'Other'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(
                    value == 'Male' ? Icons.male : (value == 'Female' ? Icons.female : Icons.transgender),
                    color: const Color(0xFFC0FF00),
                    size: 22,
                  ),
                  const SizedBox(width: 15),
                  Text(value),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _gender = newValue!;
            });
          },
        ),
      ),
    );
  }
}
