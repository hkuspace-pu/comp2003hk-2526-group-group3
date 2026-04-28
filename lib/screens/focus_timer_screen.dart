import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import 'focus_complete_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class FocusTimerScreen extends StatefulWidget {
  final int duration;

  const FocusTimerScreen({
    Key? key,
    required this.duration,
  }) : super(key: key);

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late int _remainingSeconds;
  late DateTime _startTime;
  Timer? _timer;
  Timer? integrityTimer;
  bool _isPaused = false;

  final FirestoreService _firestoreService = FirestoreService();
  final Stopwatch stopwatch = Stopwatch();
  late DateTime wallStart;
  Duration totalPaused = Duration.zero;
  DateTime? pauseStarted;
  DateTime? lastWallNow;

  int? skewSecondsAtStart;
  bool timeIntegrityPassed = true;

  static const int maxStartSkewSeconds = 120;
  static const int maxDriftSeconds = 15;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration * 60;
    _startTime = DateTime.now();
    wallStart = DateTime.now();
    lastWallNow = wallStart;
    initAndStart();
  }

  Future<void> initAndStart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showErrorAndExit('You are not logged in.');
      return;
    }

    final skew =
        await _firestoreService.getDeviceServerTimeSkewSeconds(uid: user.uid);
    skewSecondsAtStart = skew;

    if (skew.abs() > maxStartSkewSeconds) {
      timeIntegrityPassed = false;
      showErrorAndExit(
        'Device time looks incorrect.\n'
        'Time skew: ${skew}s (limit: ${maxStartSkewSeconds}s).\n'
        'Please enable automatic date & time and try again.',
      );
      return;
    }
    stopwatch.start();
    _startTimer();
    integrityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      checkTimeIntegrity();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    integrityTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        integrityTimer?.cancel();
        _onComplete();
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      _timer?.cancel();
      integrityTimer?.cancel();
      stopwatch.stop();
      pauseStarted = DateTime.now();
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;

      if (pauseStarted != null) {
        totalPaused += DateTime.now().difference(pauseStarted!);
        pauseStarted = null;
      }
      stopwatch.start();
      _startTimer();
      integrityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        checkTimeIntegrity();
      });
    });
  }

  void checkTimeIntegrity() {
    if (_isPaused) return;

    final now = DateTime.now();
    final last = lastWallNow;

    if (last != null &&
        now.isBefore(last.subtract(const Duration(seconds: 2)))) {
      timeIntegrityPassed = false;
      onTimeTamperDetected('System time moved backwards.');
      return;
    }

    final expectedElapsed = now.difference(wallStart) - totalPaused;
    final drift =
        (expectedElapsed.inSeconds - stopwatch.elapsed.inSeconds).abs();

    if (drift > maxDriftSeconds) {
      timeIntegrityPassed = false;
      onTimeTamperDetected(
        'System time changed during focus.\n'
        'Detected drift: ${drift}s (limit: ${maxDriftSeconds}s).',
      );
      return;
    }
    lastWallNow = now;
  }

  void onTimeTamperDetected(String reason) {
    cleanupTimers();

    showAlertDialog(
      title: 'Time Integrity Failed',
      message: '$reason\n\n'
          'This focus session is cancelled to prevent cheating.\n'
          'Please set device time to automatic and try again.',
      shouldPopTwice: true,
    );
  }

  void showErrorAndExit(String message) {
    cleanupTimers();
    showAlertDialog(
      title: 'Cannot Start Focus',
      message: message,
      shouldPopTwice: false,
    );
  }

  void cleanupTimers() {
    _timer?.cancel();
    integrityTimer?.cancel();
    stopwatch.stop();
  }

  void showAlertDialog({
    required String title,
    required String message,
    required bool shouldPopTwice,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(
          message,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (shouldPopTwice) {
                Navigator.pop(ctx);
              }
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  void _onComplete() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FocusCompleteScreen(
          duration: widget.duration,
          startTime: _startTime,
        ),
      ),
    );
  }

  String _formatTime() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    return 1 - (_remainingSeconds / (widget.duration * 60));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Mode'),
        automaticallyImplyLeading: false,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Stay Focused!',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 60),

              // Timer Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: CircularProgressIndicator(
                      value: _getProgress(),
                      strokeWidth: 12,
                      backgroundColor: AppColors.cardBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentOrange,
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(),
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Motivation Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "You're doing great!\nKeep it up! 💪",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Pause/Resume Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(
                      _isPaused ? 'RESUME' : 'PAUSE',
                      style: const TextStyle(
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
              ),
              const SizedBox(height: 16),

              // Cancel Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancel Focus?'),
                          content: const Text(
                            'Are you sure you want to cancel this focus session?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
