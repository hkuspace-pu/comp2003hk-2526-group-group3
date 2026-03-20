import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startEmailCheckLoop();
  }

  void _startEmailCheckLoop() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user?.emailVerified == true) {
        _timer?.cancel();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  Future<void> _resendVerification() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _checkNow() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.emailVerified == true) {
      _timer?.cancel();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email not verified yet')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Text('📧', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify your email',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We have sent a verification link to your inbox.\n'
                  'After you click the link, come back to this app.\n'
                  'This screen will auto-continue once verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _resending ? null : _resendVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _resending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text(
                            'RESEND EMAIL',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _checkNow,
                  child: const Text(
                    'I have verified — Check now',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
