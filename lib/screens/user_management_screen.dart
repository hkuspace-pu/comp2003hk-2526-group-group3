import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _roleFilter = 'all';
  String? _busyUid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus({
    required String uid,
    required bool currentDisabled,
    required String displayName,
  }) async {
    setState(() => _busyUid = uid);
    try {
      await _firestoreService.setUserDisabled(
        uid: uid,
        disabled: !currentDisabled,
      );
      if (!mounted) return;
      final action = currentDisabled ? 'enabled' : 'disabled';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$displayName has been $action.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_parseError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busyUid = null);
    }
  }

  Future<void> _removeUser({
    required String uid,
    required String displayName,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User'),
        content: Text(
          'Delete all stored data for $displayName? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _busyUid = uid);
    try {
      await _firestoreService.deleteManagedUser(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$displayName has been removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_parseError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _busyUid = null);
    }
  }

  Future<void> _editUser({
    required String uid,
    required Map<String, dynamic> user,
  }) async {
    final displayNameController = TextEditingController(
      text: (user['displayName'] ?? '').toString(),
    );
    final emailController = TextEditingController(
      text: (user['email'] ?? '').toString(),
    );
    final notesController = TextEditingController(
      text: (user['adminNotes'] ?? '').toString(),
    );

    String selectedRole = (user['role'] ?? 'user').toString();
    bool requireReset =
        (user['requirePasswordResetOnFirstLogin'] ?? false) == true;
    String? dialogError;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              final displayName = displayNameController.text.trim();
              final email = emailController.text.trim();
              final notes = notesController.text.trim();

              if (displayName.isEmpty || email.isEmpty) {
                setDialogState(() {
                  dialogError = 'Please fill in display name and email.';
                });
                return;
              }
              if (!email.contains('@')) {
                setDialogState(() {
                  dialogError = 'Please enter a valid email address.';
                });
                return;
              }

              setDialogState(() {
                isSaving = true;
                dialogError = null;
              });

              try {
                await _firestoreService.updateManagedUser(
                  uid: uid,
                  displayName: displayName,
                  email: email,
                  role: selectedRole,
                  requirePasswordResetOnFirstLogin: requireReset,
                  adminNotes: notes.isEmpty ? null : notes,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('$displayName updated successfully.')),
                );
              } catch (e) {
                setDialogState(() {
                  dialogError = _parseError(e.toString());
                  isSaving = false;
                });
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.primaryDarkGrey,
              title: const Text(
                'Edit User',
                style: TextStyle(color: AppColors.textWhite),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDialogTextField(
                        controller: displayNameController,
                        label: 'Display Name',
                        icon: Icons.badge,
                      ),
                      const SizedBox(height: 12),
                      _buildDialogTextField(
                        controller: emailController,
                        label: 'Email Address',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
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
                        value: selectedRole,
                        onChanged: (value) {
                          setDialogState(() => selectedRole = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSwitchTile(
                        icon: Icons.key,
                        label: 'Require password reset on first login',
                        value: requireReset,
                        onChanged: (value) {
                          setDialogState(() => requireReset = value);
                        },
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkGrey,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    displayNameController.dispose();
    emailController.dispose();
    notesController.dispose();
  }

  String _parseError(String error) {
    if (error.contains('permission-denied')) {
      return 'You do not have permission to manage this user.';
    }
    if (error.contains('not-found')) {
      return 'The selected user no longer exists.';
    }
    return 'Something went wrong. Please try again.';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterUsers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final displayName = (data['displayName'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? 'user').toString();
      final isDisabled = (data['isDisabled'] ?? false) == true;

      final searchMatched = _searchQuery.isEmpty ||
          displayName.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          doc.id.toLowerCase().contains(_searchQuery);

      final roleMatched = _roleFilter == 'all'
          ? true
          : _roleFilter == 'disabled'
              ? isDisabled
              : role == _roleFilter;

      return searchMatched && roleMatched;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestoreService.getAllUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Failed to load users. Please try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accentOrange),
                );
              }

              final docs = snapshot.data!.docs;
              final filteredDocs = _filterUsers(docs);
              final disabledCount = docs
                  .where((doc) => (doc.data()['isDisabled'] ?? false) == true)
                  .length;
              final adminCount = docs
                  .where((doc) => (doc.data()['role'] ?? 'user') == 'admin')
                  .length;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 24),
                  _buildSectionTitle('👥 User Directory'),
                  const SizedBox(height: 12),
                  _buildFormCard(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 14),
                      _RoleStatFilterToggle(
                        value: _roleFilter,
                        totalCount: docs.length,
                        adminCount: adminCount,
                        userCount: docs
                            .where((doc) =>
                                (doc.data()['role'] ?? 'user') == 'user')
                            .length,
                        disabledCount: disabledCount,
                        onChanged: (value) {
                          setState(() => _roleFilter = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('🗂️ Manage Users'),
                  const SizedBox(height: 12),
                  if (filteredDocs.isEmpty)
                    _buildFormCard(
                      children: const [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              'No users matched the current filters.',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    ...filteredDocs.map((doc) {
                      final user = doc.data();
                      final displayName =
                          (user['displayName'] ?? 'Unnamed User').toString();
                      final email = (user['email'] ?? '').toString();
                      final role = (user['role'] ?? 'user').toString();
                      final isDisabled = (user['isDisabled'] ?? false) == true;
                      final requireReset =
                          (user['requirePasswordResetOnFirstLogin'] ?? false) ==
                              true;
                      final isBusy = _busyUid == doc.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildFormCard(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: isDisabled
                                              ? Colors.redAccent
                                                  .withValues(alpha: 0.16)
                                              : AppColors.accentOrange
                                                  .withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          role == 'admin'
                                              ? Icons.admin_panel_settings
                                              : Icons.person,
                                          color: isDisabled
                                              ? Colors.redAccent
                                              : AppColors.accentOrange,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: const TextStyle(
                                                color: AppColors.textWhite,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              email.isEmpty
                                                  ? 'No email'
                                                  : email,
                                              style: const TextStyle(
                                                color: AppColors.textGrey,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _MetaBadge(
                                                  label: role.toUpperCase(),
                                                  color: role == 'admin'
                                                      ? const Color(0xFFFF8A3D)
                                                      : const Color(0xFF3B82F6),
                                                ),
                                                _MetaBadge(
                                                  label: isDisabled
                                                      ? 'DISABLED'
                                                      : 'ENABLED',
                                                  color: isDisabled
                                                      ? const Color(0xFFFF4D67)
                                                      : const Color(0xFF22C55E),
                                                ),
                                                if (requireReset)
                                                  const _MetaBadge(
                                                    label: 'RESET ON LOGIN',
                                                    color: Color(0xFFF59E0B),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 132,
                                  child: Column(
                                    children: [
                                      _ActionButton(
                                        icon: Icons.edit,
                                        label: 'Update',
                                        color: AppColors.primaryDarkGrey,
                                        labelColor: AppColors.accentOrange,
                                        fullWidth: true,
                                        onPressed: isBusy
                                            ? null
                                            : () => _editUser(
                                                  uid: doc.id,
                                                  user: user,
                                                ),
                                      ),
                                      const SizedBox(height: 10),
                                      _ActionButton(
                                        icon: isDisabled
                                            ? Icons.check_circle
                                            : Icons.block,
                                        label:
                                            isDisabled ? 'Enable' : 'Disable',
                                        color: AppColors.primaryDarkGrey,
                                        labelColor: AppColors.accentOrange,
                                        fullWidth: true,
                                        onPressed: isBusy
                                            ? null
                                            : () => _toggleUserStatus(
                                                  uid: doc.id,
                                                  currentDisabled: isDisabled,
                                                  displayName: displayName,
                                                ),
                                      ),
                                      const SizedBox(height: 10),
                                      _ActionButton(
                                        icon: Icons.delete,
                                        label: 'Remove',
                                        labelColor: const Color(0xFFFF4D67),
                                        iconColor: const Color(0xFFFF4D67),
                                        color: AppColors.primaryDarkGrey,
                                        fullWidth: true,
                                        onPressed: isBusy
                                            ? null
                                            : () => _removeUser(
                                                  uid: doc.id,
                                                  displayName: displayName,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (isBusy) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(
                                color: AppColors.accentOrange,
                                minHeight: 3,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              );
            },
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

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim().toLowerCase());
            },
            style: const TextStyle(color: AppColors.textWhite),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Search by name, email',
              hintStyle: const TextStyle(color: AppColors.textGrey),
              prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close, color: AppColors.textGrey),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
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
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

class _RoleStatFilterToggle extends StatelessWidget {
  const _RoleStatFilterToggle({
    required this.value,
    required this.totalCount,
    required this.adminCount,
    required this.userCount,
    required this.disabledCount,
    required this.onChanged,
  });

  final String value;
  final int totalCount;
  final int adminCount;
  final int userCount;
  final int disabledCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role Filter',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FilterStatCard(
                label: 'All',
                value: totalCount.toString(),
                icon: Icons.people,
                selected: value == 'all',
                onTap: () => onChanged('all'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FilterStatCard(
                label: 'Admin',
                value: adminCount.toString(),
                icon: Icons.admin_panel_settings,
                selected: value == 'admin',
                onTap: () => onChanged('admin'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FilterStatCard(
                label: 'User',
                value: userCount.toString(),
                icon: Icons.person,
                selected: value == 'user',
                onTap: () => onChanged('user'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FilterStatCard(
                label: 'Disabled',
                value: disabledCount.toString(),
                icon: Icons.block,
                selected: value == 'disabled',
                onTap: () => onChanged('disabled'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterStatCard extends StatelessWidget {
  const _FilterStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? AppColors.accentOrange.withValues(alpha: 0.94)
        : AppColors.primaryDarkGrey.withValues(alpha: 0.30);

    final borderColor = selected
        ? AppColors.accentOrange
        : AppColors.textWhite.withValues(alpha: 0.10);

    final iconColor = selected ? AppColors.textWhite : AppColors.accentOrange;
    final labelColor = selected ? AppColors.textWhite : AppColors.textGrey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.20),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.color,
    required this.onPressed,
    this.fullWidth = false,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color labelColor;
  final Color color;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? labelColor;

    final button = ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      icon: Icon(
        icon,
        size: 18,
        color: effectiveIconColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: labelColor,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
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
