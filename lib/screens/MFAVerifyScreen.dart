import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_auth_web/firebase_auth_web.dart'
    show
        FirebaseAuthWeb,
        RecaptchaVerifier,
        RecaptchaVerifierSize,
        RecaptchaVerifierTheme;

import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'dashboard_screen.dart';

class MFAVerifyScreen extends StatefulWidget {
  final bool enrollFlow;
  final FirebaseAuthMultiFactorException? exception;
  final String? phoneNumberForEnroll;

  const MFAVerifyScreen({
    super.key,
    required this.enrollFlow,
    this.exception,
    this.phoneNumberForEnroll,
  });

  @override
  State<MFAVerifyScreen> createState() => _MFAVerifyScreenState();
}

class _MFAVerifyScreenState extends State<MFAVerifyScreen> {
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String? _verificationId;
  String? _maskedPhone;
  bool _sendingCode = false;
  bool _verifying = false;
  String? _error;

  RecaptchaVerifier? _webVerifier;

  @override
  void initState() {
    super.initState();

    if (widget.enrollFlow && widget.phoneNumberForEnroll != null) {
      _phoneCtrl.text = widget.phoneNumberForEnroll!;
    }

    if (!(widget.enrollFlow &&
        (widget.phoneNumberForEnroll?.isEmpty ?? true))) {
      _sendSMS();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _maskPhone(String phone) {
    final p = phone.trim();
    if (p.length <= 6) return p;
    final prefix = p.substring(0, 5);
    final suffix = p.substring(p.length - 2);
    return '$prefix****$suffix';
  }

  Future<void> _prepareWebRecaptcha() async {
    try {
      _webVerifier?.clear();
    } catch (_) {}
    _webVerifier = null;

    _webVerifier = RecaptchaVerifier(
      auth: FirebaseAuthWeb.instance,
      container: 'recaptcha-container',
      size: RecaptchaVerifierSize.compact,
      theme: RecaptchaVerifierTheme.dark,
    );

    await _webVerifier!.render();
  }

  Future<void> _sendSMS() async {
    setState(() {
      _sendingCode = true;
      _error = null;
    });

    try {
      if (kIsWeb) {
        await _prepareWebRecaptcha();
      }

      if (widget.enrollFlow) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() => _error = 'No signed-in user for MFA enrollment.');
          return;
        }

        final phone = (_phoneCtrl.text.isNotEmpty)
            ? _phoneCtrl.text.trim()
            : (widget.phoneNumberForEnroll ?? '').trim();

        if (phone.isEmpty) {
          setState(() => _error = 'Please enter a phone number to enroll MFA.');
          return;
        }

        _maskedPhone = _maskPhone(phone);

        final session = await user.multiFactor.getSession();
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          multiFactorSession: session,
          verificationCompleted: (_) {},
          verificationFailed: (FirebaseAuthException e) =>
              setState(() => _error = '[${e.code}] ${e.message ?? ''}'),
          codeSent: (String id, int? _) => setState(() => _verificationId = id),
          codeAutoRetrievalTimeout: (_) {},
        );
      } else {
        final ex = widget.exception;
        if (ex == null) {
          setState(
              () => _error = 'Missing MultiFactorException for sign-in flow.');
          return;
        }

        final resolver = ex.resolver;
        final hint = resolver.hints.firstWhere(
          (h) => h is PhoneMultiFactorInfo,
          orElse: () => resolver.hints.first,
        ) as PhoneMultiFactorInfo;

        _maskedPhone = _maskPhone(hint.phoneNumber ?? '');

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: hint.phoneNumber!,
          multiFactorSession: resolver.session,
          verificationCompleted: (_) {},
          verificationFailed: (FirebaseAuthException e) =>
              setState(() => _error = '[${e.code}] ${e.message ?? ''}'),
          codeSent: (String id, int? _) => setState(() => _verificationId = id),
          codeAutoRetrievalTimeout: (_) {},
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeCtrl.text.trim(),
      );
      final assertion = PhoneMultiFactorGenerator.getAssertion(credential);

      if (widget.enrollFlow) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw FirebaseAuthException(code: 'no-current-user');
        await user.multiFactor.enroll(assertion, displayName: 'phone');
      } else {
        final ex = widget.exception!;
        await ex.resolver.resolveSignIn(assertion);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = '[${e.code}] ${e.message ?? ''}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
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
                const Text('🔑', style: TextStyle(fontSize: 80)),
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
                Text(
                  widget.enrollFlow ? 'Enroll Phone 2FA' : 'Verify 2FA Code',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.enrollFlow
                      ? (_maskedPhone == null
                          ? 'Enter phone number and send verification code to enroll two-factor authentication (SMS).'
                          : 'We have sent a verification code to $_maskedPhone, please enter it to complete registration.')
                      : (_maskedPhone == null
                          ? 'A verification code has been sent to your second factor phone number.'
                          : 'We have sent a verification code to $_maskedPhone, please enter it to complete login.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 24),
                if (widget.enrollFlow &&
                    (widget.phoneNumberForEnroll?.isEmpty ?? true))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTextField(
                      controller: _phoneCtrl,
                      icon: Icons.phone_android,
                      hint: 'Phone Number (+852XXXXXXXX)',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                _buildTextField(
                  controller: _codeCtrl,
                  icon: Icons.pin,
                  hint: 'SMS Code',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
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
                    onPressed: _verifying ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _verifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'VERIFY',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _sendingCode ? null : _sendSMS,
                  child: Text(
                    _sendingCode ? 'Sending...' : 'Resend Code',
                    style: const TextStyle(color: AppColors.textGrey),
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
