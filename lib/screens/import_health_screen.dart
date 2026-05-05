import 'package:flutter/material.dart';
import 'package:health/health.dart';

import '../utils/colors.dart';
import '../utils/constants.dart';

/// Returned to AddActivityScreen
class HealthImportItem {
  final DateTime start;
  final DateTime end;
  final int durationMinutes;
  final String mappedActivityType;
  final String source;
  final String? notes;

  const HealthImportItem({
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.mappedActivityType,
    required this.source,
    this.notes,
  });
}

class ImportHealthScreen extends StatefulWidget {
  const ImportHealthScreen({super.key});

  @override
  State<ImportHealthScreen> createState() => _ImportHealthScreenState();
}

class _ImportHealthScreenState extends State<ImportHealthScreen> {
  final Health _health = Health();

  bool _loading = true;
  String? _error;

  // 0=today,1=yesterday,2=two days ago
  int _dayFilterIndex = 0;

  final List<_Candidate> _all = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _mapToActivityType(String raw) {
    final lower = raw.toLowerCase();

    // Very simple mapping. Add more keywords if needed.
    String? pick;
    if (lower.contains('yoga')) pick = 'Yoga';
    if (lower.contains('run')) pick = 'Run';
    if (lower.contains('walk')) pick = 'Walk';
    if (lower.contains('cycle') || lower.contains('bike')) pick = 'Cycling';
    if (lower.contains('swim')) pick = 'Swim';

    if (pick != null && AppConstants.activityTypes.contains(pick)) return pick;
    return AppConstants.activityTypes.isNotEmpty
        ? AppConstants.activityTypes.first
        : 'Workout';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 3));
      final types = <HealthDataType>[HealthDataType.WORKOUT];

      final granted = await _health.requestAuthorization(types);
      if (!granted) {
        throw Exception('Health permission not granted');
      }

      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );

      final deduped = _health.removeDuplicates(points);

      _all
        ..clear()
        ..addAll(
          deduped.map((p) {
            final from = p.dateFrom;
            final to = p.dateTo;
            final minutes = to.difference(from).inMinutes;

            // Different platforms may format workout info differently.
            final raw = p.value.toString();

            // Stable ID for checkbox selection
            final id =
                '${p.sourceName}|${from.millisecondsSinceEpoch}|${to.millisecondsSinceEpoch}|${p.typeString}';

            return _Candidate(
              id: id,
              start: from,
              end: to,
              minutes: minutes,
              raw: raw,
              source: p.sourceName,
              mappedActivityType: _mapToActivityType(raw),
            );
          }).where((c) => c.minutes > 0),
        );

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<_Candidate> get _filtered {
    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final dayStart = todayStart.subtract(Duration(days: _dayFilterIndex));
    final dayEnd = dayStart.add(const Duration(days: 1));

    final list = _all
        .where((c) => c.start.isAfter(dayStart) && c.start.isBefore(dayEnd))
        .toList()
      ..sort((a, b) => b.start.compareTo(a.start));

    return list;
  }

  void _toggle(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _importSelected() {
    final selected = _all.where((c) => _selectedIds.contains(c.id)).toList();

    final items = selected
        .map(
          (c) => HealthImportItem(
            start: c.start,
            end: c.end,
            durationMinutes: c.minutes,
            mappedActivityType: c.mappedActivityType,
            source: c.source,
            notes:
                'Imported from Health (${c.source})\n${c.start.toLocal()} - ${c.end.toLocal()}',
          ),
        )
        .toList();

    Navigator.pop(context, items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import from Health'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF0AA0D6),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : Column(
                      children: [
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _DayChip(
                                label: 'Today',
                                selected: _dayFilterIndex == 0,
                                onTap: () =>
                                    setState(() => _dayFilterIndex = 0),
                              ),
                              _DayChip(
                                label: 'Yesterday',
                                selected: _dayFilterIndex == 1,
                                onTap: () =>
                                    setState(() => _dayFilterIndex = 1),
                              ),
                              _DayChip(
                                label: '2 Days Ago',
                                selected: _dayFilterIndex == 2,
                                onTap: () =>
                                    setState(() => _dayFilterIndex = 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No workouts found in this day.',
                                    style: TextStyle(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  itemCount: _filtered.length,
                                  itemBuilder: (context, index) {
                                    final c = _filtered[index];
                                    final checked = _selectedIds.contains(c.id);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.cardBackground,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: CheckboxListTile(
                                        value: checked,
                                        onChanged: (v) =>
                                            _toggle(c.id, v ?? false),
                                        activeColor: AppColors.accentOrange,
                                        checkColor: Colors.black,
                                        title: Text(
                                          '${c.mappedActivityType} • ${c.minutes} min',
                                          style: const TextStyle(
                                            color: AppColors.textWhite,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${c.start.toLocal()}\nSource: ${c.source}',
                                          style: const TextStyle(
                                            color: AppColors.textGrey,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  _selectedIds.isEmpty ? null : _importSelected,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDarkGrey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'import (${_selectedIds.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _Candidate {
  final String id;
  final DateTime start;
  final DateTime end;
  final int minutes;
  final String raw;
  final String source;
  final String mappedActivityType;

  _Candidate({
    required this.id,
    required this.start,
    required this.end,
    required this.minutes,
    required this.raw,
    required this.source,
    required this.mappedActivityType,
  });
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accentOrange,
      backgroundColor: AppColors.cardBackground,
      labelStyle: TextStyle(
        color: selected ? Colors.black : AppColors.textWhite,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.health_and_safety,
                size: 48, color: AppColors.textWhite),
            const SizedBox(height: 12),
            Text(
              'Cannot access health data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}
