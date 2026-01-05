import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'focus_timer_screen.dart';

class FocusStartScreen extends StatefulWidget {
  const FocusStartScreen({Key? key}) : super(key: key);

  @override
  State<FocusStartScreen> createState() => _FocusStartScreenState();
}

class _FocusStartScreenState extends State<FocusStartScreen> {
  int _selectedTime = 25; // Default 25 minutes
  final TextEditingController _customTimeController = TextEditingController();

  @override
  void dispose() {
    _customTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Title
                      const Text(
                        'Select Duration',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Time Selection Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: AppConstants.focusTimes.map((time) {
                          return _buildTimeButton(time);
                        }).toList(),
                      ),
                      const SizedBox(height: 40),

                      // Custom Time
                      const Text(
                        'Custom Time',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customTimeController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 18,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter minutes',
                                  hintStyle:
                                      TextStyle(color: AppColors.textGrey),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _selectedTime = int.tryParse(value) ?? 25;
                                    });
                                  }
                                },
                              ),
                            ),
                            const Text(
                              'minutes',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Start Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FocusTimerScreen(
                                  duration: _selectedTime,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDarkGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.play_circle_filled, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'START FOCUS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
        ),
      ),
    );
  }

  Widget _buildTimeButton(int time) {
    final isSelected =
        _selectedTime == time && _customTimeController.text.isEmpty;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTime = time;
          _customTimeController.clear();
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentOrange : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentOrange : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$time',
              style: TextStyle(
                color: isSelected ? AppColors.textWhite : AppColors.textGrey,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'min',
              style: TextStyle(
                color: isSelected ? AppColors.textWhite : AppColors.textGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
