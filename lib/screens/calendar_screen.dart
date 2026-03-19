import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/focus_session.dart';
import '../models/activity_log.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _currentMonth = DateTime.now();
  int _selectedDay = DateTime.now().day;
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

    final start = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final end =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);

    final sessions =
        await _firestoreService.getSessionsForDateRange(user.uid, start, end);
    final activities = await _firestoreService.getActivityLogs(user.uid);

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _activities = activities
            .where((a) => a.loggedAt.isAfter(start) && a.loggedAt.isBefore(end))
            .toList();
        _isLoading = false;
      });
    }
  }

  // Get days that have sessions
  Set<int> get _sessionDays => _sessions.map((s) => s.startTime.day).toSet();

  // Get days that have activities
  Set<int> get _activityDays => _activities.map((a) => a.loggedAt.day).toSet();

  // Get sessions for selected day
  List<FocusSession> get _selectedDaySessions =>
      _sessions.where((s) => s.startTime.day == _selectedDay).toList();

  // Get activities for selected day
  List<ActivityLog> get _selectedDayActivities =>
      _activities.where((a) => a.loggedAt.day == _selectedDay).toList();

  int get _selectedDayPoints =>
      _selectedDaySessions.fold(0, (sum, s) => sum + s.pointsEarned) +
      _selectedDayActivities.fold(0, (sum, a) => sum + a.pointsEarned);

  int get _selectedDayFocusMinutes =>
      _selectedDaySessions.fold(0, (sum, s) => sum + s.durationMinutes);

  int get _selectedDayActivityMinutes =>
      _selectedDayActivities.fold(0, (sum, a) => sum + a.durationMinutes);

  String get _monthTitle {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = 1;
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _selectedDay = 1;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Month Header with navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left,
                          color: AppColors.textWhite),
                      onPressed: _previousMonth,
                    ),
                    Text(
                      _monthTitle,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right,
                          color: AppColors.textWhite),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Calendar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentOrange,
                          ),
                        )
                      : Column(
                          children: [
                            // Weekday headers
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _WeekdayHeader('Su'),
                                _WeekdayHeader('Mo'),
                                _WeekdayHeader('Tu'),
                                _WeekdayHeader('We'),
                                _WeekdayHeader('Th'),
                                _WeekdayHeader('Fr'),
                                _WeekdayHeader('Sa'),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Calendar days
                            _buildCalendarGrid(),

                            const SizedBox(height: 16),

                            // Legend
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildLegend(Colors.green, 'Focus'),
                                _buildLegend(
                                    AppColors.accentOrange, 'Activity'),
                                _buildLegend(Colors.blue, 'Both'),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // Selected Day Details
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_monthTitle $_selectedDay',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedDaySessions.isEmpty &&
                          _selectedDayActivities.isEmpty)
                        const Text(
                          'No activity on this day',
                          style: TextStyle(color: AppColors.textGrey),
                        )
                      else ...[
                        if (_selectedDaySessions.isNotEmpty)
                          _buildDetailRow(
                            'Focus:',
                            '${_selectedDaySessions.length} sessions ($_selectedDayFocusMinutes min)',
                          ),
                        if (_selectedDayActivities.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Activities:',
                            '${_selectedDayActivities.length} ($_selectedDayActivityMinutes min)',
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Points Earned:',
                          '$_selectedDayPoints 💰',
                        ),
                      ],
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

  Widget _buildCalendarGrid() {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Empty cells before month starts
    for (int i = 0; i < firstWeekday; i++) {
      currentRow.add(_buildDayCell(0, false));
    }

    // Days of month
    for (int day = 1; day <= daysInMonth; day++) {
      currentRow.add(_buildDayCell(day, true));

      if (currentRow.length == 7) {
        rows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: currentRow,
        ));
        rows.add(const SizedBox(height: 8));
        currentRow = [];
      }
    }

    // Fill remaining cells
    while (currentRow.length < 7 && currentRow.isNotEmpty) {
      currentRow.add(_buildDayCell(0, false));
    }

    if (currentRow.isNotEmpty) {
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: currentRow,
      ));
    }

    return Column(children: rows);
  }

  Widget _buildDayCell(int day, bool isActive) {
    if (!isActive) {
      return const SizedBox(width: 40, height: 40);
    }

    final hasSession = _sessionDays.contains(day);
    final hasActivity = _activityDays.contains(day);
    final isSelected = day == _selectedDay;
    final isToday = day == DateTime.now().day &&
        _currentMonth.month == DateTime.now().month &&
        _currentMonth.year == DateTime.now().year;

    Color backgroundColor;
    if (hasSession && hasActivity) {
      backgroundColor = Colors.blue;
    } else if (hasSession) {
      backgroundColor = Colors.green;
    } else if (hasActivity) {
      backgroundColor = AppColors.accentOrange;
    } else {
      backgroundColor = AppColors.primaryDarkGrey.withValues(alpha: 0.3);
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.textWhite, width: 2)
              : isToday
                  ? Border.all(color: AppColors.accentOrange, width: 2)
                  : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: (hasSession || hasActivity)
                  ? Colors.white
                  : AppColors.textGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
}

class _WeekdayHeader extends StatelessWidget {
  final String day;
  const _WeekdayHeader(this.day);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textGrey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
