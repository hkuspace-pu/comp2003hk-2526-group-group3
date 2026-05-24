import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_log.dart';
import '../models/focus_session.dart';
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

  DateTime _rangeStart() {
    final now = DateTime.now();
    return switch (_selectedTab) {
      0 => DateTime(now.year, now.month, now.day),
      1 => now.subtract(const Duration(days: 7)),
      _ => now.subtract(const Duration(days: 30)),
    };
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final start = _rangeStart();
    final now = DateTime.now();

    final sessions = await _firestoreService.getSessionsForDateRange(
      user.uid,
      start,
      now,
    );
    final activities = await _firestoreService.getActivityLogs(user.uid);
    // print('stat loaded ${sessions.length} sessions, ${activities.length} activities');

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _activities =
            activities.where((a) => a.loggedAt.isAfter(start)).toList();
        _isLoading = false;
      });
    }
  }

  // sessions inside the current tab range
  List<FocusSession> get _sessionsInTabRange {
    final start = _rangeStart();
    return _sessions.where((s) => s.startTime.isAfter(start)).toList();
  }

  // bar series for the chart. Bins vary by tab; labels are sparse on Month.
  List<Map<String, dynamic>> _getChartSeries() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedTab == 0) {
      final bins = List<double>.filled(12, 0);
      for (final s in _sessions.where((s) => !s.startTime.isBefore(today))) {
        bins[(s.startTime.hour ~/ 2).clamp(0, 11)] += s.durationMinutes / 60;
      }
      return [
        for (var i = 0; i < 12; i++)
          {'label': '${i * 2}', 'hours': bins[i], 'showLabel': i % 2 == 0},
      ];
    }

    final days = _selectedTab == 1 ? 7 : 30;
    return [
      for (var i = days - 1; i >= 0; i--)
        _dayBar(today.subtract(Duration(days: i)),
            showLabel: _selectedTab == 1 || i % 5 == 0),
    ];
  }

  Map<String, dynamic> _dayBar(DateTime d, {required bool showLabel}) {
    var hours = 0.0;
    for (final s in _sessions) {
      final t = s.startTime;
      if (t.year == d.year && t.month == d.month && t.day == d.day) {
        hours += s.durationMinutes / 60;
      }
    }
    return {
      'label': '${d.month}/${d.day}',
      'hours': hours,
      'showLabel': showLabel,
    };
  }

  Map<String, int> _getActivityDistribution() {
    final out = <String, int>{};
    for (final a in _activities) {
      out[a.activityType] = (out[a.activityType] ?? 0) + 1;
    }
    return out;
  }

  int get _totalFocusMinutes =>
      _sessionsInTabRange.fold(0, (s, x) => s + x.durationMinutes);

  int get _totalPoints =>
      _sessionsInTabRange.fold(0, (s, x) => s + x.pointsEarned) +
      _activities.fold(0, (s, x) => s + x.pointsEarned);

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
                            final series = _getChartSeries();
                            // find the max hours for scale the bar height
                            double maxHours = 0.0;
                            for (var bar in series) {
                              final h = bar['hours'] as double;
                              if (h > maxHours) maxHours = h;
                            }
                            if (maxHours == 0) maxHours = 1.0;

                            double barWidth;
                            if (_selectedTab == 2) {
                              barWidth = 6.0;
                            } else if (_selectedTab == 0) {
                              barWidth = 16.0;
                            } else {
                              barWidth = 26.0;
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: _selectedTab == 2
                                  ? MainAxisAlignment.spaceBetween
                                  : MainAxisAlignment.spaceEvenly,
                              children: series.map((bar) {
                                final showLabel = bar['showLabel'] as bool;
                                final label =
                                    showLabel ? bar['label'] as String : '';
                                final hours = bar['hours'] as double;
                                return _buildBar(
                                  label,
                                  hours,
                                  maxHours,
                                  width: barWidth,
                                );
                              }).toList(),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedTab == 0
                              ? 'Hours per 2-hour block (today)'
                              : _selectedTab == 1
                                  ? 'Hours per day (last 7 days)'
                                  : 'Hours per day (last 30 days)',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                          '${_sessionsInTabRange.length}',
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

  Widget _buildBar(String label, double hours, double maxHours,
      {double width = 26}) {
    final pct = maxHours > 0 ? hours / maxHours : 0.0;
    final barHeight = (100 * pct).clamp(4.0, 100.0);
    // skip value label on narrow bars (month view) — no room
    final showValue = hours > 0 && width >= 16;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showValue)
          Text(
            '${hours.toStringAsFixed(1)}h',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 10),
          ),
        const SizedBox(height: 4),
        Container(
          width: width,
          height: barHeight,
          decoration: BoxDecoration(
            color:
                hours > 0 ? AppColors.accentOrange : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 12,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 10),
          ),
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
