import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../logic/services/food_api_service.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/services/notification_service.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> with SingleTickerProviderStateMixin {
  final FoodApiService _apiService = FoodApiService();
  final ImagePicker _picker = ImagePicker();
  
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  
  File? _selectedImage;
  bool _isScanning = false;
  NutritionInfo? _nutritionInfo;
  List<NutritionInfo> _suggestions = [];
  Timer? _debounce;
  String _lastQuery = '';
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _servingsController.text = '1';
    
    // Setup pulse animation for AI Scanning
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen to changes in inputs to recalculate live
    _servingsController.addListener(_onInputChanged);
    _caloriesController.addListener(_onInputChanged);
    _foodNameController.addListener(_onFoodNameChanged);
  }

  void _onFoodNameChanged() {
    final query = _foodNameController.text.trim().toLowerCase();
    
    // If they selected a food, we don't want to re-search exactly that if it matches _nutritionInfo.name
    if (_nutritionInfo != null && query == _nutritionInfo!.name.toLowerCase()) return;

    if (query == _lastQuery) return;
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      _lastQuery = query;
      
      if (query.isEmpty) {
        if (mounted) {
          setState(() {
            _suggestions = [];
          });
        }
        return;
      }

      final results = await _apiService.searchNutritionInfo(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
        });
      }
    });
  }

  void _onInputChanged() {
    if (_nutritionInfo != null) {
      final inputAmount = double.tryParse(_servingsController.text) ?? (_nutritionInfo!.baseAmount);
      final multiplier = inputAmount / _nutritionInfo!.baseAmount;
      final totalCals = (_nutritionInfo!.calories * multiplier).toInt().toString();
      if (_caloriesController.text != totalCals) {
        _caloriesController.text = totalCals;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _nutritionInfo = null; // Reset prev data
        });
        await _processFoodImage(_selectedImage!);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _processFoodImage(File imageFile) async {
    setState(() {
      _isScanning = true;
      _foodNameController.text = 'AI is analyzing...';
      _caloriesController.text = '';
    });

    try {
      // Use Custom Gemini AI Scanner
      final result = await _apiService.scanFoodWithGemini(imageFile);
      
      final String foodName = result['foodName'] ?? 'Unknown Food';
      final nutrition = NutritionInfo(
        name: foodName,
        calories: (result['calories'] ?? 0).toInt(),
        protein: (result['protein'] ?? 0).toDouble(),
        carbs: (result['carbs'] ?? 0).toDouble(),
        fats: (result['fats'] ?? 0).toInt().toDouble(),
        unit: 'quantity',
        baseAmount: 1,
      );

      setState(() {
        _foodNameController.text = foodName;
        _nutritionInfo = nutrition;
        _lastQuery = foodName.toLowerCase();
        _servingsController.text = '1';
        _caloriesController.text = nutrition.calories.toString();
        _suggestions = [];
      });
      
    } catch (e) {
      String errorMessage = 'AI Scan failed or no food detected. Please enter manually.';
      if (e.toString().contains('LOW_CONFIDENCE:')) {
         errorMessage = e.toString().split('LOW_CONFIDENCE:').last;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pulseController.dispose();
    _foodNameController.dispose();
    _caloriesController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Track Food',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gemini Smart AI Scanner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Powered by Google Gemini 1.5 Flash',
              style: TextStyle(
                color: const Color(0xFFC0FF00).withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            
            // Scanner Container (Glassmorphic)
            GestureDetector(
              onTap: _isScanning ? null : () => _showImageSourceDialog(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _isScanning 
                            ? const Color(0xFFC0FF00) // Neon lime pulse
                            : Colors.white.withOpacity(0.1),
                        width: _isScanning ? 2 : 1,
                      ),
                      image: _selectedImage != null 
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                            colorFilter: _isScanning 
                                ? ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)
                                : null,
                          )
                        : null,
                    ),
                    child: _isScanning 
                      ? _buildScanningOverlay()
                      : (_selectedImage == null ? _buildScannerPlaceholder() : const SizedBox.shrink()),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            
            const SizedBox(height: 30),
            Center(
              child: Text(
                '— OR ENTER MANUALLY —',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Modern Inputs
            _buildGlassTextField(
              label: 'Food Name',
              hint: 'e.g., Grilled Salmon',
              icon: Icons.restaurant_menu,
              controller: _foodNameController,
            ),
            
            if (_suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length > 5 ? 5 : _suggestions.length,
                  separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    return ListTile(
                      title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${item.calories} kcal per ${item.baseAmount.toInt()} ${item.unit}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                      trailing: const Icon(Icons.add_circle_outline, color: Color(0xFFC0FF00), size: 18),
                      onTap: () {
                        setState(() {
                          _nutritionInfo = item;
                          _foodNameController.text = item.name;
                          _lastQuery = item.name.toLowerCase();
                          _servingsController.text = item.baseAmount.toInt().toString();
                          _suggestions = [];
                          _onInputChanged();
                        });
                        FocusScope.of(context).unfocus();
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildGlassTextField(
                    label: 'Total Calories',
                    hint: 'kcal',
                    icon: Icons.local_fire_department,
                    isNumber: true,
                    controller: _caloriesController,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 2,
                  child: _buildQtyStepper(),
                ),
              ],
            ),
            
            // Macro Readouts if available
            if (_nutritionInfo != null) ...[
              const SizedBox(height: 25),
              const Text(
                'Nutrition Breakdown',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildMFPStyleMacroBreakdown(),
            ],

            const SizedBox(height: 40),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isScanning ? null : () async {
                  final authState = context.read<AuthBloc>().state;
                  final email = authState.email;
                  
                  if (email == null || email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User email not found. Please log in again.')),
                    );
                    return;
                  }

                  final foodName = _foodNameController.text.trim();
                  final calories = int.tryParse(_caloriesController.text) ?? 0;
                  final servings = int.tryParse(_servingsController.text) ?? 1;
                  
                  if (foodName.isEmpty || calories == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide at least a food name and calories.', style: TextStyle(color: Colors.white))),
                    );
                    return;
                  }
                  
                  setState(() { _isScanning = true; });
                  
                  final now = DateTime.now();
                  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  
                  final inputAmount = double.tryParse(_servingsController.text) ?? 1;
                  final baseAmount = _nutritionInfo?.baseAmount ?? 1.0;
                  final multiplier = inputAmount / baseAmount;
                  
                  final protein = _nutritionInfo?.protein ?? 0.0;
                  final carbs = _nutritionInfo?.carbs ?? 0.0;
                  final fats = _nutritionInfo?.fats ?? 0.0;

                  final success = await _apiService.logFood(
                    email: email,
                    foodName: foodName,
                    calories: calories, // The UI already multiplied this!
                    protein: protein * multiplier,
                    carbs: carbs * multiplier,
                    fats: fats * multiplier,
                    servings: inputAmount.toInt(),
                    date: dateStr,
                  );

                  if (mounted) {
                    setState(() { _isScanning = false; });
                    
                    if (success) {
                      // Fetch daily nutrition to calculate remaining calories
                      final dailyResult = await _apiService.getDailyNutrition(email, dateStr);
                      final totalEatenSoFar = dailyResult?.totalCalories ?? 0;
                      final targetCalories = authState.targetCalories;

                      // Trigger smart notification
                      await NotificationService.showFoodAddedNotification(
                        foodName, 
                        calories, 
                        targetCalories, 
                        totalEatenSoFar
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Food logged successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                      );
                      Navigator.pop(context, true); // return true to trigger refresh on home
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to log food. Try again.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0FF00),
                  disabledBackgroundColor: Colors.white.withOpacity(0.1),
                  elevation: _isScanning ? 0 : 8,
                  shadowColor: const Color(0xFFC0FF00).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _isScanning ? 'ANALYZING...' : 'LOG NUTRITION',
                  style: TextStyle(
                    color: _isScanning ? Colors.white54 : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFC0FF00).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_outlined,
            color: Color(0xFFC0FF00),
            size: 40,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Tap to scan your meal with Gemini AI',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSupportedFoodsHint() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supported Dishes',
          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 35,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: FoodApiService.indianFoodLabels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Center(
                  child: Text(
                    FoodApiService.indianFoodLabels[index],
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanningOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC0FF00).withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC0FF00).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Icon(Icons.document_scanner_outlined, color: Color(0xFFC0FF00), size: 40),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Extracting Nutrition Data...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
          )
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontWeight: FontWeight.normal),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFC0FF00), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildQtyStepper() {
    final unitLabel = _nutritionInfo?.unit == 'grams' ? 'Amount (grams)' : 
                      _nutritionInfo?.unit == 'ml' ? 'Amount (ml)' : 'Amount (qty)';
    final stepAmount = (_nutritionInfo?.unit == 'grams' || _nutritionInfo?.unit == 'ml') ? 50 : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          unitLabel,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60, // Match TextField height
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  int current = int.tryParse(_servingsController.text) ?? stepAmount;
                  if (current > stepAmount) {
                    _servingsController.text = (current - stepAmount).toString();
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _servingsController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Color(0xFFC0FF00)),
                onPressed: () {
                  int current = int.tryParse(_servingsController.text) ?? 0;
                  _servingsController.text = (current + stepAmount).toString();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMFPStyleMacroBreakdown() {
    final inputAmount = double.tryParse(_servingsController.text) ?? (_nutritionInfo!.baseAmount);
    final multiplier = inputAmount / _nutritionInfo!.baseAmount;
    
    // Calculate live totals
    final baseCals = _nutritionInfo!.calories.toDouble();
    final totalCals = baseCals * multiplier;
    final totalProtein = _nutritionInfo!.protein * multiplier;
    final totalCarbs = _nutritionInfo!.carbs * multiplier;
    final totalFats = _nutritionInfo!.fats * multiplier;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Calories', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    '${totalCals.toInt()} kcal',
                     style: const TextStyle(color: Color(0xFFC0FF00), fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text('Base: ${baseCals.toInt()} kcal / ${_nutritionInfo!.baseAmount.toInt()} ${_nutritionInfo!.unit}', style: const TextStyle(color: Colors.white70, fontSize: 10)),
              )
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroDistributionChip('Carbs', totalCarbs, const Color(0xFFFFD6C8)),
              _buildMacroDistributionChip('Protein', totalProtein, const Color(0xFFD6C8FF)),
              _buildMacroDistributionChip('Fats', totalFats, const Color(0xFFC8E6FF)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroDistributionChip(String label, double value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: 1.0, 
                strokeWidth: 4, 
                valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.3)),
              ),
            ),
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: 0.7, // Visual presentation
                strokeWidth: 4, 
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text('${value.toStringAsFixed(1)}g', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Wrap(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Select Image Source', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Photo Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFC0FF00).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_camera, color: Color(0xFFC0FF00)),
                ),
                title: const Text('Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
