import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import 'privacy_policy_screen.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;

  final List<Map<String, dynamic>> _faqs = [
    {
      'icon': '💰',
      'question': 'How do I earn points?',
      'answer':
          'You earn 2 points per minute during focus sessions, plus bonus points for longer sessions:\n\n'
              '• +10 bonus points for sessions of 25 minutes or more\n'
              '• +10 bonus points for sessions of 60 minutes or more\n\n'
              'Activity logging earns 1.5 points per minute based on duration.',
    },
    {
      'icon': '⏱️',
      'question': 'How does the focus timer work?',
      'answer': 'Select a duration (15, 25, 45, or 60 minutes), tap Start Focus, and keep your device on screen. '
          'When the session completes, your points are automatically saved to your profile. '
          'You can cancel at any time, but cancelled sessions do not earn points.',
    },
    {
      'icon': '🐟',
      'question': 'How do I buy and manage fish?',
      'answer':
          'Go to your Aquarium and tap the Store button. Browse available fish, decorations, and food, '
              'then tap Buy to purchase with your earned points. '
              'Your new fish will appear and swim in your aquarium immediately!',
    },
    {
      'icon': '🍖',
      'question': 'How do I feed my fish?',
      'answer': 'Visit your Aquarium and tap the Feed button. '
          'Each feeding uses 1 food item from your stock. '
          'Purchase more food from the Store using your points.',
    },
    {
      'icon': '📊',
      'question': 'How do I view my statistics?',
      'answer': 'Go to the Statistics tab on your Dashboard. '
          'You can view your focus minutes and activity history by Today, This Week, or This Month. '
          'A bar chart shows your daily focus hours, and a breakdown shows your activity types.',
    },
    {
      'icon': '🏆',
      'question': 'What are achievements?',
      'answer':
          'Achievements are milestones you unlock by building consistent habits, such as:\n\n'
              '• Completing your first focus session\n'
              '• Accumulating 10 hours of total focus time\n'
              '• Logging 10 off-screen activities\n'
              '• Maintaining a 7-day focus streak\n\n'
              'Check your Profile to track your progress towards each achievement.',
    },
    {
      'icon': '📅',
      'question': 'How does the calendar work?',
      'answer':
          'The Calendar view shows a monthly overview of your focus sessions and activities. '
              'Days with activity are highlighted. Tap any day to see a detailed breakdown of '
              'sessions and activities logged on that date.',
    },
    {
      'icon': '💾',
      'question': 'How do I back up my data?',
      'answer': 'Go to Settings → Data Management → Export as JSON. '
          'A full backup of your profile, sessions, and activities will be saved as a file '
          'you can store in iCloud, Google Drive, or any other location. '
          'Identity verification is required before export.',
    },
    {
      'icon': '📥',
      'question': 'How do I restore my data?',
      'answer': 'Go to Settings → Data Management → Import from JSON. '
          'Select your previously exported backup file. '
          'This will overwrite your current data with the backup. '
          'Identity verification is required before import.',
    },
    {
      'icon': '🔔',
      'question': 'How do I set up daily reminders?',
      'answer':
          'Go to Settings → Notifications → Enable Daily Focus Reminder, then set your preferred reminder time. '
              'You will receive a notification each day at that time encouraging you to start a focus session. '
              'Note: notifications must be enabled in your device settings.',
    },
    {
      'icon': '📱',
      'question': 'Can I use the app on multiple devices?',
      'answer':
          'Yes. Your data is stored securely in the cloud via Firebase, so you can log in '
              'on any device using the same account and access all your data remotely.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // About Section
              _buildAboutCard(),
              const SizedBox(height: 20),

              // Key Features
              _buildFeaturesCard(),
              const SizedBox(height: 20),

              // FAQ Header
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // FAQ Items
              ...List.generate(
                _faqs.length,
                (index) => _buildFaqItem(index),
              ),
              const SizedBox(height: 20),

              // Privacy Policy Link
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.privacy_tip_outlined,
                          color: AppColors.accentOrange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          color: AppColors.textGrey, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Contact Support
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Need more help?',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Contact us and we\'ll get back to you as soon as possible.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email: support@focusaquarium.com'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.email_outlined),
                        label: const Text(
                          'Contact Support',
                          style: TextStyle(
                            fontSize: 15,
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('🐠', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          const Text(
            'Focus Aquarium',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Version 1.0.0',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accentOrange.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'Focus Aquarium helps you build healthier digital habits through gamification. '
              'Complete focus sessions and log offline activities to earn points — '
              'then spend them growing your virtual aquarium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Our Mission',
            style: TextStyle(
              color: AppColors.accentOrange,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Excessive smartphone use is linked to reduced productivity and poorer mental wellbeing. '
            'Focus Aquarium makes digital wellness engaging and sustainable by turning healthy habits into a rewarding experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    final features = [
      {'icon': '⏱️', 'label': 'Focus Timer'},
      {'icon': '🏃', 'label': 'Activity Log'},
      {'icon': '😊', 'label': 'Mood Tracking'},
      {'icon': '📊', 'label': 'Statistics'},
      {'icon': '📅', 'label': 'Calendar'},
      {'icon': '🏆', 'label': 'Achievements'},
      {'icon': '🐠', 'label': 'Aquarium'},
      {'icon': '💾', 'label': 'Data Backup'},
      {'icon': '🔔', 'label': 'Reminders'},
      {'icon': '☁️', 'label': 'Cloud Sync'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Features',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: features
                .map(
                  (f) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGrey,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(f['icon']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          f['label']!,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(int index) {
    final faq = _faqs[index];
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: isExpanded
            ? Border.all(color: AppColors.accentOrange.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    faq['icon'] as String,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      faq['question'] as String,
                      style: TextStyle(
                        color: isExpanded
                            ? AppColors.accentOrange
                            : AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isExpanded
                        ? AppColors.accentOrange
                        : AppColors.textGrey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(
              color: AppColors.textGrey,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                faq['answer'] as String,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
