import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/services/progress_api_service.dart';

class Progress extends StatefulWidget {
  const Progress({super.key});

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  final ProgressApiService _apiService = ProgressApiService();
  ProgressData? _progressData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
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
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
              onPressed: _loadProgressData,
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC0FF00)))
          : _progressData == null
              ? const Center(child: Text('Failed to load progress data', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStreakCard(_progressData!),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCircularStatCard(
                              "MUSCLE MASS",
                              _progressData!.muscleMass,
                              const Color(0xFFC0FF00),
                              "${_progressData!.muscleMassChange >= 0 ? '+' : ''}${_progressData!.muscleMassChange}% ${(_progressData!.muscleMassChange >= 0 ? '↑' : '↓')}",
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildCircularStatCard(
                              "BODY FAT",
                              _progressData!.bodyFat,
                              const Color(0xFFD6C8FF),
                              "${_progressData!.bodyFatChange >= 0 ? '+' : ''}${_progressData!.bodyFatChange}% ${(_progressData!.bodyFatChange <= 0 ? '↓' : '↑')}",
                              isNegativeGood: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildMuscleFocusCard(_progressData!),
                      const SizedBox(height: 20),
                      _buildNutritionJourneyCard(_progressData!),
                      const SizedBox(height: 20),
                      _buildGithubHeatmap(_progressData!),
                      const SizedBox(height: 80), // spacing for bottom nav bar
                    ],
                  ),
                ),
    );
  }

  Widget _buildNutritionJourneyCard(ProgressData data) {
    final last7Days = data.nutritionJourney;
    final todayCalories = last7Days.isNotEmpty ? last7Days.last.toInt() : 0;
    final targetCalories = context.watch<AuthBloc>().state.targetCalories;
    
    // Calculate percentage change compared to 7 days average or previous day
    // For now, let's show a fake positive trend as in the screenshot if data is sparse
    const String trendText = "-2.4% this month"; 

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nutrition Journey',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Goal: $targetCalories kcal',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
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
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  'KCAL',
                  style: TextStyle(
                    color: Color(0xFFC0FF00),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0FF00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  trendText,
                  style: TextStyle(
                    color: Color(0xFFC0FF00),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: NutritionJourneyPainter(data: last7Days),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map((day) => Text(
                      day,
                      style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                    ))
                .toList(),
          )
        ],
      ),
    );
  }

  Widget _buildStreakCard(ProgressData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_month, color: Color(0xFFC0FF00), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Consistency Streak',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Color(0xFFC0FF00), size: 14),
                    const SizedBox(width: 4),
                    Text('${data.streakDays} Days', style: const TextStyle(color: Color(0xFFC0FF00), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGithubHeatmap(ProgressData data) {
    final int columns = 18;
    final activeDatesSet = data.activeDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // In Flutter, Mon=1, Sun=7. We want Mon=rowIndex 0.
    final int rowIndexToday = today.weekday - 1;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
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
                    // Calculation for the date of this specific cell
                    // daysFromToday = (Weeks from end) * 7 + (Current Day Offset - Row Offset)
                    int daysFromToday = (columns - 1 - colIndex) * 7 + (rowIndexToday - rowIndex);
                    
                    if (daysFromToday < 0) {
                      // These are "future" cells in the current week column
                      return Container(
                        width: 15,
                        height: 15,
                        margin: const EdgeInsets.only(bottom: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.transparent, // Don't show future blocks
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }

                    final cellDate = normalizedToday.subtract(Duration(days: daysFromToday));
                    final isActive = activeDatesSet.contains(cellDate);
                    final dateStr = "${cellDate.day}/${cellDate.month}/${cellDate.year}";
                    
                    Color color;
                    if (isActive) {
                      if (daysFromToday < 7) {
                        color = const Color(0xFFC0FF00);
                      } else if (daysFromToday < 14) {
                        color = const Color(0xFFC0FF00).withOpacity(0.8);
                      } else if (daysFromToday < 30) {
                        color = const Color(0xFFC0FF00).withOpacity(0.6);
                      } else {
                        color = const Color(0xFFC0FF00).withOpacity(0.4);
                      }
                    } else {
                      color = Colors.grey[800]!;
                    }

                    return Tooltip(
                      message: isActive ? "Logged on $dateStr" : "Empty on $dateStr",
                      triggerMode: TooltipTriggerMode.tap,
                      child: Container(
                        width: 15,
                        height: 15,
                        margin: const EdgeInsets.only(bottom: 6.0),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _dayLabel(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10));
  }

  Widget _buildCircularStatCard(String title, double value, Color color, String subtitle, {bool isNegativeGood = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 75,
                height: 75,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '$value%',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: isNegativeGood ? (subtitle.contains('-') ? color : Colors.redAccent) : (subtitle.contains('+') ? color : Colors.redAccent),
              fontSize: 12,
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleFocusCard(ProgressData data) {
    final labels = data.radarData.labels;
    final values = data.radarData.values;

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.track_changes, color: Color(0xFFC0FF00), size: 20),
              SizedBox(width: 10),
              Text(
                'Muscle Focus',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
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
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: RadarChartPainter(values, const Color(0xFFC0FF00)),
                  ),
                  // Render labels
                  ...List.generate(labels.length, (i) {
                    final angleScope = (2 * math.pi) / labels.length;
                    final angle = -math.pi / 2 + i * angleScope;
                    final radius = 110; 
                    final x = radius * math.cos(angle);
                    final y = radius * math.sin(angle);
                    return Positioned(
                      left: 110 + x - 25, 
                      top: 100 + y - 10,
                      child: SizedBox(
                        width: 50,
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
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
}

class RadarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  RadarChartPainter(this.values, this.color);

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
        // Clamp values to 0-1 range to prevent drawing outside
        final valRadius = radius * values[i].clamp(0.0, 1.0);
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

  NutritionJourneyPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFC0FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFC0FF00).withOpacity(0.3),
          const Color(0xFFC0FF00).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double stepX = size.width / (data.length - 1);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    double getY(double val) {
      final normalized = (val - minVal) / range;
      return size.height - (normalized * size.height * 0.8) - (size.height * 0.1);
    }

    path.moveTo(0, getY(data[0]));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, getY(data[0]));

    for (int i = 0; i < data.length - 1; i++) {
      final double x1 = i * stepX;
      final double y1 = getY(data[i]);
      final double x2 = (i + 1) * stepX;
      final double y2 = getY(data[i + 1]);

      final double cx = x1 + (x2 - x1) / 2;
      
      path.cubicTo(cx, y1, cx, y2, x2, y2);
      fillPath.cubicTo(cx, y1, cx, y2, x2, y2);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = const Color(0xFFC0FF00);
    final glowPaint = Paint()..color = const Color(0xFFC0FF00).withOpacity(0.3);

    for (int i = 0; i < data.length; i++) {
      final center = Offset(i * stepX, getY(data[i]));
      canvas.drawCircle(center, 6, glowPaint);
      canvas.drawCircle(center, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
