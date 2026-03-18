import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      setState(() => _error = "User is not logged in.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Step 2: Get MFA Session
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
      if (mounted) {
        setState(() => _loading = false);
      }
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
          .enroll(assertion, displayName: "My Phone");

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Phone 2FA Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_smsSent)
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number (+852XXXXXXX)",
                ),
              ),
            if (_smsSent)
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "SMS Code",
                ),
              ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : _smsSent
                      ? _verifyCode
                      : _sendSMS,
              child: Text(_smsSent ? "Verify Code" : "Send SMS"),
            ),
          ],
        ),
      ),
    );
  }
}
