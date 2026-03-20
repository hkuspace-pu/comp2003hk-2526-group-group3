import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

// --- Web 端需要的 reCAPTCHA 類別（來自 firebase_auth_web） ---
import 'package:firebase_auth_web/firebase_auth_web.dart'
    show
        FirebaseAuthWeb,
        RecaptchaVerifier,
        RecaptchaVerifierSize,
        RecaptchaVerifierTheme;

// 你的專案既有樣式／工具
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import 'dashboard_screen.dart';

/// 支援兩種流程：
/// 1) 登入補第二因素（sign-in flow）：enrollFlow=false，exception 必填。
/// 2) 首次註冊第二因素（enroll flow）：enrollFlow=true，phoneNumberForEnroll 建議提供。
class MFAVerifyScreen extends StatefulWidget {
  final bool enrollFlow; // true=註冊第二因素；false=登入補第二因素
  final FirebaseAuthMultiFactorException? exception; // sign-in flow 需要
  final String? phoneNumberForEnroll; // enroll flow 建議提供；若為 null，畫面會顯示輸入框

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
  // 驗證碼與電話欄位
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  String? _verificationId;
  String? _maskedPhone;
  bool _sendingCode = false;
  bool _verifying = false;
  String? _error;

  // --- Web reCAPTCHA verifier ---
  RecaptchaVerifier? _webVerifier;

  @override
  void initState() {
    super.initState();

    // enroll flow 若有預設電話，帶到輸入框
    if (widget.enrollFlow && widget.phoneNumberForEnroll != null) {
      _phoneCtrl.text = widget.phoneNumberForEnroll!;
    }

    // 頁面載入即送一次驗證碼（若為 enroll flow 但沒有電話，就先不送）
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

  // --- Web：每次送碼前建立並 render reCAPTCHA，避免殘留衝突 ---
  Future<void> _prepareWebRecaptcha() async {
    try {
      _webVerifier?.clear(); // clear() 回傳 void，不要 await
    } catch (_) {}
    _webVerifier = null;

    _webVerifier = RecaptchaVerifier(
      auth: FirebaseAuthWeb.instance,
      container:
          'recaptcha-container', // 請在 web/index.html 放置 <div id="recaptcha-container"></div>
      size:
          RecaptchaVerifierSize.compact, // 常見可用: normal/compact（無 invisible 常數）
      theme: RecaptchaVerifierTheme.dark,
    );

    // 先行 render；verifyPhoneNumber 會自動拾取已 render 的 v2 reCAPTCHA
    // ignore: unused_result
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
        // ========= 註冊第二因素（enroll） =========
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() => _error = 'No signed-in user for MFA enrollment.');
          return;
        }

        final phone = (_phoneCtrl.text.isNotEmpty)
            ? _phoneCtrl.text.trim()
            : (widget.phoneNumberForEnroll ?? '').trim();

        if (phone.isEmpty) {
          setState(() => _error = '請先輸入要註冊的手機號碼（含國碼，例如 +852xxxxxxxx）。');
          return;
        }

        _maskedPhone = _maskPhone(phone);

        // enroll 需要 user.multiFactor.getSession()
        final session =
            await user.multiFactor.getSession(); // enroll 流程的 session
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
        // ========= 登入補第二因素（sign-in） =========
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
          multiFactorSession: resolver.session, // sign-in 流程的 session
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
        // ✅ 註冊第二因素完成（enroll）
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw FirebaseAuthException(code: 'no-current-user');
        await user.multiFactor.enroll(assertion,
            displayName: 'phone'); // 對應 mfaEnrollment:finalize
      } else {
        // ✅ 登入補第二因素完成（sign-in）
        final ex = widget.exception!;
        await ex.resolver.resolveSignIn(assertion); // 對應 mfaSignIn:finalize
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
                          ? '輸入電話並發送驗證碼以註冊第二因素（SMS）。'
                          : '我們已傳送驗證碼至 $_maskedPhone，請輸入以完成註冊。')
                      : (_maskedPhone == null
                          ? '已向你的第二因素電話發送驗證碼。'
                          : '我們已傳送驗證碼至 $_maskedPhone，請輸入以完成登入。'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textGrey),
                ),
                const SizedBox(height: 24),

                // enroll flow 若未提供 phone，顯示電話輸入框
                if (widget.enrollFlow &&
                    (widget.phoneNumberForEnroll?.isEmpty ?? true))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTextField(
                      controller: _phoneCtrl,
                      icon: Icons.phone_android,
                      hint: '電話（含國碼，例如 +852xxxxxxxx）',
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
