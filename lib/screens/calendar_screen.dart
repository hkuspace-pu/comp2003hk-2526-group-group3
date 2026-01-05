import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedDay = 25;

  // Fake data for demonstration
  final Map<int, String> _dayStatus = {
    1: 'complete',
    2: 'complete',
    3: 'partial',
    5: 'complete',
    8: 'complete',
    10: 'partial',
    12: 'complete',
    15: 'complete',
    18: 'partial',
    20: 'complete',
    22: 'complete',
    25: 'complete',
  };

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
                // Month Header
                const Text(
                  'December 2025',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Calendar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Weekday headers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
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
                          _buildLegend(Colors.green, 'Completed'),
                          _buildLegend(Colors.yellow[700]!, 'Partial'),
                          _buildLegend(AppColors.textGrey, 'Incomplete'),
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
                        'Selected: Dec $_selectedDay, 2025',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow('Focus:', '2 sessions (90 min)'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Activities:', '3 (120 min)'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Points Earned:', '240 💰'),
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
    // December 2025 starts on Monday (day 1)
    final daysInMonth = 31;
    final startWeekday = 1; // Monday = 1

    List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Add empty cells for days before month starts
    for (int i = 0; i < startWeekday; i++) {
      currentRow.add(_buildDayCell(0, false));
    }

    // Add days of month
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

    // Add remaining cells
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
      return SizedBox(
        width: 40,
        height: 40,
        child: Container(),
      );
    }

    final status = _dayStatus[day];
    final isSelected = day == _selectedDay;

    Color backgroundColor;
    if (status == 'complete') {
      backgroundColor = Colors.green;
    } else if (status == 'partial') {
      backgroundColor = Colors.yellow[700]!;
    } else {
      backgroundColor = AppColors.textGrey.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: AppColors.textWhite, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              color: status != null ? Colors.white : AppColors.textGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
