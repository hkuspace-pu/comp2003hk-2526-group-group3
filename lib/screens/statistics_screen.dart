import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/focus_session.dart';
import '../models/activity_log.dart';
import '../services/firestore_service.dart';
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
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;

  List<FocusSession> _sessions = [];
  List<ActivityLog> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    DateTime start;

    if (_selectedTab == 0) {
      start = DateTime(now.year, now.month, now.day);
    } else if (_selectedTab == 1) {
      start = now.subtract(const Duration(days: 7));
    } else {
      start = now.subtract(const Duration(days: 30));
    }

    final sessions = await _firestoreService.getSessionsForDateRange(
      user.uid,
      start,
      now,
    );
    final activities = await _firestoreService.getActivityLogs(user.uid);

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _activities =
            activities.where((a) => a.loggedAt.isAfter(start)).toList();
        _isLoading = false;
      });
    }
  }

  // Calculate daily focus minutes for bar chart (last 7 days)
  Map<String, double> _getDailyFocusHours() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final Map<String, double> result = {
      for (var d in days) d: 0.0,
    };

    for (final session in _sessions) {
      final weekday = session.startTime.weekday; // 1=Mon, 7=Sun
      final dayName = days[weekday - 1];
      result[dayName] = (result[dayName] ?? 0) + session.durationMinutes / 60;
    }

    return result;
  }

  // Calculate activity type distribution
  Map<String, int> _getActivityDistribution() {
    final Map<String, int> result = {};
    for (final activity in _activities) {
      result[activity.activityType] = (result[activity.activityType] ?? 0) + 1;
    }
    return result;
  }

  int get _totalFocusMinutes =>
      _sessions.fold(0, (sum, s) => sum + s.durationMinutes);

  int get _totalPoints =>
      _sessions.fold(0, (sum, s) => sum + s.pointsEarned) +
      _activities.fold(0, (sum, a) => sum + a.pointsEarned);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CalendarScreen(),
              ),
            ),
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

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentOrange,
                    ),
                  )
                else ...[
                  // Focus Time Trend (bar chart)
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
                        SizedBox(
                          height: 150,
                          child: Builder(builder: (context) {
                            final dailyHours = _getDailyFocusHours();
                            final maxHours = dailyHours.values.isEmpty
                                ? 1.0
                                : dailyHours.values
                                            .reduce((a, b) => a > b ? a : b) ==
                                        0
                                    ? 1.0
                                    : dailyHours.values
                                        .reduce((a, b) => a > b ? a : b);

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: dailyHours.entries.map((e) {
                                return _buildBar(e.key, e.value, maxHours);
                              }).toList(),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
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

                  // Summary
                  Text(
                    _selectedTab == 0
                        ? '📈 Today\'s Summary'
                        : _selectedTab == 1
                            ? '📈 This Week\'s Summary'
                            : '📈 This Month\'s Summary',
                    style: const TextStyle(
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
                        _buildSummaryRow(
                          'Focus Sessions:',
                          '${_sessions.length}',
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Total Focus:',
                          '${(_totalFocusMinutes / 60).toStringAsFixed(1)} hours',
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Activities Logged:',
                          '${_activities.length}',
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Points Earned:',
                          '$_totalPoints 💰',
                        ),
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
                    child: _activities.isEmpty
                        ? const Center(
                            child: Text(
                              'No activities logged yet',
                              style: TextStyle(color: AppColors.textGrey),
                            ),
                          )
                        : Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _getActivityDistribution()
                                .entries
                                .map((e) => _buildActivityChip(e.key, e.value))
                                .toList(),
                          ),
                  ),
                ],
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
          setState(() => _selectedTab = index);
          _loadData();
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
    final heightPercent = maxHours == 0 ? 0.0 : hours / maxHours;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hours > 0)
          Text(
            '${hours.toStringAsFixed(1)}h',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 10),
          ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: (100 * heightPercent).clamp(4.0, 100.0),
          decoration: BoxDecoration(
            color:
                hours > 0 ? AppColors.accentOrange : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 16)),
        Text(value,
            style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActivityChip(String activityType, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$activityType ($count)',
        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
      ),
    );
  }
}
