import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';
import 'calendar_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTab = 1; // 0: Today, 1: Week, 2: Month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CalendarScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab Selection
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTab('Today', 0),
                      _buildTab('Week', 1),
                      _buildTab('Month', 2),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Focus Time Trend
                const Text(
                  '📊 Focus Time Trend',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Simple chart representation
                      SizedBox(
                        height: 150,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildBar('Mon', 2.0, 3.0),
                            _buildBar('Tue', 1.0, 3.0),
                            _buildBar('Wed', 3.0, 3.0),
                            _buildBar('Thu', 2.0, 3.0),
                            _buildBar('Fri', 0.5, 3.0),
                            _buildBar('Sat', 1.0, 3.0),
                            _buildBar('Sun', 0.5, 3.0),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Hours per day',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // This Week Summary
                const Text(
                  '📈 This Week Summary',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Total Focus:', '9 hours'),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Total Activities:', '12'),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Points Earned:', '1,080 💰'),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Streak:', '5 days 🔥'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Activity Distribution
                const Text(
                  '🎯 Activity Distribution',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Simple pie chart representation
                      SizedBox(
                        height: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPieSegment(
                                '🏃', 'Running', '40%', AppColors.accentOrange),
                            const SizedBox(width: 20),
                            _buildPieSegment(
                                '📚', 'Reading', '30%', AppColors.primaryBlue),
                            const SizedBox(width: 20),
                            _buildPieSegment(
                                '🎨', 'Other', '30%', AppColors.textGrey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDarkGrey : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.textWhite : AppColors.textGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double hours, double maxHours) {
    final heightPercent = hours / maxHours;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${hours.toStringAsFixed(1)}h',
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: 100 * heightPercent,
          decoration: BoxDecoration(
            color: AppColors.accentOrange,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPieSegment(
      String icon, String label, String percent, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 12,
          ),
        ),
        Text(
          percent,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
