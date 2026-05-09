import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedRole = 'user';
  bool _sendVerificationEmail = true;
  bool _forcePasswordReset = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final notes = _notesController.text.trim();

    if (displayName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in display name, email, and password.';
      });
      return;
    }

    if (!email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.createUserByAdmin(
        email: email,
        password: password,
        displayName: displayName,
        role: _selectedRole,
        sendVerificationEmail: _sendVerificationEmail,
        requirePasswordReset: _forcePasswordReset,
        adminNotes: notes,
      );

      if (!mounted) return;

      _displayNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _notesController.clear();

      setState(() {
        _selectedRole = 'user';
        _sendVerificationEmail = true;
        _forcePasswordReset = false;
      });

      final verifyText =
          _sendVerificationEmail ? ' Verification email sent.' : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully for $displayName ($email).$verifyText',
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _parseError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (error.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (error.contains('invalid-email')) {
      return 'Invalid email address.';
    }
    if (error.contains('admin-not-authenticated')) {
      return 'Current admin session is not valid. Please login again.';
    }
    if (error.contains('permission-denied')) {
      return 'You do not have permission to create this account.';
    }
    if (error.contains('user-create-failed')) {
      return 'Unable to create the new account.';
    }
    return 'Something went wrong while creating the account.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Registration'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 24),
              _buildSectionTitle('👤 Account Information'),
              const SizedBox(height: 12),
              _buildFormCard(
                children: [
                  _buildTextField(
                    controller: _displayNameController,
                    label: 'Display Name',
                    hint: 'Enter user display name',
                    icon: Icons.badge,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'Enter email address',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Temporary Password',
                    hint: 'Enter temporary password',
                    icon: Icons.lock,
                    obscureText: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('🛡️ Access Control'),
              const SizedBox(height: 12),
              _buildFormCard(
                children: [
                  const Text(
                    'User Role',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RoleToggle(
                    value: _selectedRole,
                    onChanged: (value) => setState(() => _selectedRole = value),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    icon: Icons.mark_email_read,
                    label: 'Send verification email',
                    value: _sendVerificationEmail,
                    onChanged: (value) =>
                        setState(() => _sendVerificationEmail = value),
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchTile(
                    icon: Icons.key,
                    label: 'Require password reset on first login',
                    value: _forcePasswordReset,
                    onChanged: (value) =>
                        setState(() => _forcePasswordReset = value),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDarkGrey,
                          disabledBackgroundColor:
                              AppColors.primaryDarkGrey.withValues(alpha: 0.70),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'CREATE ACCOUNT',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textWhite,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryDarkGrey.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textWhite.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textGrey),
              prefixIcon: Icon(icon, color: AppColors.textGrey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGrey.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textWhite.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentOrange),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 15,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accentOrange,
          ),
        ],
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGrey.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.textWhite.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TogglePill(
              label: 'User',
              selected: value == 'user',
              onTap: () => onChanged('user'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TogglePill(
              label: 'Admin',
              selected: value == 'admin',
              onTap: () => onChanged('admin'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentOrange
              : AppColors.primaryDarkGrey.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
