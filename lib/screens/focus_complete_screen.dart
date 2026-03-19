import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import '../services/firestore_service.dart';
import 'aquarium_screen.dart';
import 'dashboard_screen.dart';
import '../services/notification_service.dart';

class FocusCompleteScreen extends StatefulWidget {
  final int duration;
  final DateTime startTime;

  const FocusCompleteScreen({
    Key? key,
    required this.duration,
    required this.startTime,
  }) : super(key: key);

  @override
  State<FocusCompleteScreen> createState() => _FocusCompleteScreenState();
}

class _FocusCompleteScreenState extends State<FocusCompleteScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = true;
  int _pointsEarned = 0;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _saveSession();
  }

  int _calculatePoints() {
    int basePoints = widget.duration * 2;
    int bonus = 10;
    if (widget.duration >= 25) bonus += 10;
    if (widget.duration >= 60) bonus += 10;
    return basePoints + bonus;
  }

  Future<void> _saveSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final points = _calculatePoints();

    await _firestoreService.saveFocusSession(
      uid: user.uid,
      durationMinutes: widget.duration,
      pointsEarned: points,
      startTime: widget.startTime,
      endTime: DateTime.now(),
    );

    final profile = await _firestoreService.getUserProfile(user.uid);

    // Show completion notification
    await NotificationService().showNotification(
      id: NotificationService.focusCompleteID,
      title: '🎉 Focus Session Complete!',
      body: 'You earned $_pointsEarned points! Keep it up!',
    );

    if (mounted) {
      setState(() {
        _pointsEarned = points;
        _totalPoints = profile?.totalPoints ?? 0;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isSaving
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentOrange,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Stars
                      const Text('⭐ ✨ ⭐', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 24),

                      // Congratulations
                      const Text(
                        'Congratulations!',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Duration
                      Text(
                        'You focused for ${widget.duration} min',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Points Earned
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '+$_pointsEarned 💰',
                              style: const TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Points Earned!',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Total Points
                      Text(
                        'Total Points: $_totalPoints',
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 60),

                      // View Aquarium Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AquariumScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.water),
                          label: const Text(
                            'VIEW AQUARIUM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDarkGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DashboardScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textWhite,
                            side: const BorderSide(
                              color: AppColors.textWhite,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
