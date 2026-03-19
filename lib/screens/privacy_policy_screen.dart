import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('🔒', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Last updated: March 2026',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                AppColors.accentOrange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          'Your privacy matters to us. Focus Aquarium is designed with data minimisation and user control at its core.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.accentOrange,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildSection(
                  icon: '📋',
                  iconColor: Colors.blue,
                  title: '1. Data We Collect',
                  items: [
                    _PolicyItem(
                      icon: Icons.email_outlined,
                      title: 'Account Information',
                      description:
                          'Your email address used for registration and authentication.',
                    ),
                    _PolicyItem(
                      icon: Icons.timer_outlined,
                      title: 'Focus Session Data',
                      description:
                          'Start time, end time, duration, and points earned per session.',
                    ),
                    _PolicyItem(
                      icon: Icons.directions_run_outlined,
                      title: 'Activity Logs',
                      description:
                          'Activity type, duration, mood, personal notes, and optional photo attachments.',
                    ),
                    _PolicyItem(
                      icon: Icons.settings_outlined,
                      title: 'App Preferences',
                      description:
                          'Notification settings stored locally on your device.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSection(
                  icon: '🎯',
                  iconColor: Colors.green,
                  title: '2. How We Use Your Data',
                  content: 'Your data is used solely to:\n\n'
                      '• Provide personalised focus tracking and gamification features.\n'
                      '• Display statistics, progress, and achievement history.\n'
                      '• Send optional reminders based on your chosen preferences.\n\n'
                      'We do not sell, share, or transfer your personal data to any third party for commercial purposes.',
                ),
                const SizedBox(height: 16),

                _buildSection(
                  icon: '🛡️',
                  iconColor: Colors.purple,
                  title: '3. Data Storage & Security',
                  items: [
                    _PolicyItem(
                      icon: Icons.cloud_outlined,
                      title: 'Secure Cloud Storage',
                      description:
                          'Data is stored via Google Firebase with industry-standard encryption in transit and at rest.',
                    ),
                    _PolicyItem(
                      icon: Icons.lock_outlined,
                      title: 'Authentication',
                      description:
                          'Login is handled via Firebase Authentication using email and password.',
                    ),
                    _PolicyItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Re-authentication',
                      description:
                          'Sensitive operations such as export, import, and deletion require identity verification.',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSection(
                  icon: '⚙️',
                  iconColor: AppColors.accentOrange,
                  title: '4. Your Rights & Data Control',
                  rights: [
                    _RightItem(
                        icon: Icons.download_outlined,
                        color: Colors.blue,
                        label: 'Export',
                        description:
                            'Download a full backup of your data in JSON format at any time.'),
                    _RightItem(
                        icon: Icons.upload_outlined,
                        color: Colors.green,
                        label: 'Import',
                        description:
                            'Restore your data from a previously exported backup file.'),
                    _RightItem(
                        icon: Icons.delete_outline,
                        color: Colors.red,
                        label: 'Delete',
                        description:
                            'Permanently delete all your data from our servers at any time.'),
                    _RightItem(
                        icon: Icons.person_outline,
                        color: Colors.orange,
                        label: 'Account',
                        description:
                            'Request full account deletion by contacting us directly.'),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSection(
                  icon: '👶',
                  iconColor: Colors.pink,
                  title: "5. Children's Privacy",
                  content:
                      'Focus Aquarium is not intended for children under the age of 13. '
                      'We do not knowingly collect personal data from children. '
                      'If you believe a child has provided us with personal data, please contact us immediately.',
                ),
                const SizedBox(height: 16),

                _buildSection(
                  icon: '📬',
                  iconColor: Colors.teal,
                  title: '6. Contact Us',
                  content:
                      'If you have any questions about this Privacy Policy or your data, please contact us at:\n\nfocusaquarium@support.com',
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String icon,
    required Color iconColor,
    required String title,
    String? content,
    List<_PolicyItem>? items,
    List<_RightItem>? rights,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.textGrey, height: 1),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          if (items != null)
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: AppColors.accentOrange, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          if (rights != null)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: rights
                  .map((r) => Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: r.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: r.color.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(r.icon, color: r.color, size: 22),
                            const SizedBox(height: 6),
                            Text(
                              r.label,
                              style: TextStyle(
                                color: r.color,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                r.description,
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                                overflow: TextOverflow.fade,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _PolicyItem {
  final IconData icon;
  final String title;
  final String description;
  const _PolicyItem(
      {required this.icon, required this.title, required this.description});
}

class _RightItem {
  final IconData icon;
  final Color color;
  final String label;
  final String description;
  const _RightItem(
      {required this.icon,
      required this.color,
      required this.label,
      required this.description});
}
