import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How to earn points?',
      'answer': 'Complete focus sessions and log off-screen activities to earn points. '
          'Focus mode gives 2 points per minute, and activities give 1-1.5 points per minute. '
          'You also get bonus points for completing sessions without interruption!',
    },
    {
      'question': 'How to buy fish?',
      'answer':
          'Go to your Aquarium, tap the Store button, browse available fish and decorations, '
              'then tap Buy to purchase with your points. Your new fish will appear in your aquarium!',
    },
    {
      'question': 'How to feed fish?',
      'answer':
          'Visit your Aquarium and tap the Feed button. Each feeding uses 1 food item and '
              'increases your fish hunger level by 10%. Make sure to keep your fish happy by feeding them regularly!',
    },
    {
      'question': 'How to export data?',
      'answer':
          'Go to Profile → Data Management, then choose your export format (JSON, TSV, or ZIP). '
              'Your data will be saved as a file that you can backup to cloud storage or transfer to another device.',
    },
    {
      'question': 'What are achievements?',
      'answer':
          'Achievements are special badges you unlock by completing challenges like focusing for 10 hours, '
              'logging 10 activities, or maintaining a 7-day streak. Check your Profile to see all achievements!',
    },
    {
      'question': 'How does the focus timer work?',
      'answer':
          'Select a duration (15-60 minutes or custom), start the timer, and keep your focus! '
              'The timer runs in the background. If you complete without canceling, you earn full points plus a bonus.',
    },
    {
      'question': 'Can I use the app offline?',
      'answer':
          'Yes! All core features work offline including focus mode, activity logging, and aquarium viewing. '
              'Your data is stored locally on your device.',
    },
    {
      'question': 'How to switch languages?',
      'answer':
          'Go to Settings → Language and select from English, Traditional Chinese, or Simplified Chinese. '
              'The app will update immediately.',
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
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) {
                    return _buildFaqItem(index);
                  },
                ),
              ),

              // Contact Support
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Need more help?',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email: support@focusaquarium.com'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.email),
                        label: const Text(
                          'Contact Support',
                          style: TextStyle(
                            fontSize: 16,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(int index) {
    final faq = _faqs[index];
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '❓',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      faq['question']!,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textWhite,
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
                faq['answer']!,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
