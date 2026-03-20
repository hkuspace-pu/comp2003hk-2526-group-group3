import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';

import 'login_screen.dart';

class PhoneRegister extends StatefulWidget {
  const PhoneRegister({super.key});

  @override
  State<PhoneRegister> createState() => _PhoneRegisterState();
}

class _PhoneRegisterState extends State<PhoneRegister> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  String? _verificationId;
  bool _smsSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendSMS() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'User is not logged in.');
      return;
    }

    await user.reload();
    if (!user.emailVerified) {
      setState(() => _error =
          'Need to verify email first before enrolling second factors.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await user.multiFactor.getSession();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneCtrl.text.trim(),
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          setState(() => _error = e.message);
        },
        codeSent: (verificationId, _) {
          setState(() {
            _verificationId = verificationId;
            _smsSent = true;
          });
        },
        codeAutoRetrievalTimeout: (_) {},
        multiFactorSession: session,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeCtrl.text.trim(),
      );
      final assertion = PhoneMultiFactorGenerator.getAssertion(credential);

      await FirebaseAuth.instance.currentUser!.multiFactor
          .enroll(assertion, displayName: 'My Phone');

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                const Text('🔐', style: TextStyle(fontSize: 80)),
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
                  'Enable Phone 2FA',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter your phone number to receive a verification code.\n'
                  'Use E.164 format, e.g. +852XXXXXXXX.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 24),
                if (!_smsSent)
                  _buildTextField(
                    controller: _phoneCtrl,
                    icon: Icons.phone,
                    hint: 'Phone Number (+852XXXXXXXX)',
                    keyboardType: TextInputType.phone,
                  ),
                if (_smsSent)
                  _buildTextField(
                    controller: _codeCtrl,
                    icon: Icons.pin,
                    hint: 'SMS Code',
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 16),
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
                    onPressed: _loading
                        ? null
                        : _smsSent
                            ? _verifyCode
                            : _sendSMS,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _smsSent ? 'VERIFY & ENABLE' : 'SEND SMS',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textWhite),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textGrey),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
