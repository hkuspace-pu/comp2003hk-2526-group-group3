import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';

class MFAVerifyScreen extends StatefulWidget {
  final FirebaseAuthMultiFactorException exception;

  const MFAVerifyScreen({super.key, required this.exception});

  @override
  State<MFAVerifyScreen> createState() => _MFAVerifyScreenState();
}

class _MFAVerifyScreenState extends State<MFAVerifyScreen> {
  String? verificationId;
  final codeCtrl = TextEditingController();
  bool sendingCode = false;
  bool verifying = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _sendSMS();
  }

  Future<void> _sendSMS() async {
    setState(() {
      sendingCode = true;
      error = null;
    });

    try {
      final resolver = widget.exception.resolver;
      final hint = resolver.hints.first as PhoneMultiFactorInfo;

      final phoneAuthProvider = PhoneAuthProvider();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: hint.phoneNumber!,
        multiFactorSession: resolver.session,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          setState(() => error = e.message);
        },
        codeSent: (id, _) {
          setState(() => verificationId = id);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => sendingCode = false);
    }
  }

  Future<void> _verifyCode() async {
    if (verificationId == null) return;
    setState(() {
      verifying = true;
      error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: codeCtrl.text.trim(),
      );

      final assertion = PhoneMultiFactorGenerator.getAssertion(credential);

      await widget.exception.resolver.resolveSignIn(assertion);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify 2FA Code")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("A verification code has been sent to your phone."),
            const SizedBox(height: 20),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: "Enter SMS code",
              ),
            ),
            const SizedBox(height: 20),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifying ? null : _verifyCode,
              child: verifying
                  ? const CircularProgressIndicator()
                  : const Text("Verify"),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: sendingCode ? null : _sendSMS,
              child: const Text("Resend Code"),
            ),
          ],
        ),
      ),
    );
  }
}
