import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/colors.dart';
import '../utils/constants.dart';

class HealthImportItem {
  final DateTime start;
  final DateTime end;
  final int durationMinutes;
  final String mappedActivityType;
  final String source;
  final String? notes;
  final String? evidencePhotoPath;

  const HealthImportItem({
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.mappedActivityType,
    required this.source,
    this.notes,
    this.evidencePhotoPath,
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

  final List<_Candidate> _all = [];
  String? _selectedId;
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _health.configure();
    _load(forceRequestPermission: false);
  }

  String _mapToActivityType(String raw) {
    final lower = raw.toLowerCase();
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _seedTestHealthData() async {
    await Permission.activityRecognition.request();
    await Permission.location.request();

    if (!Platform.isAndroid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seed only supported on Android (Health Connect).'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final okWrite = await _ensureWritePermission();
      if (!okWrite) {
        if (!mounted) return;
        setState(() => _loading = false);
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Write permission required'),
            content: const Text(
              'Health Connect has not granted write permission.\n\n'
              'Please go to Health Connect → App permissions, find Focus Aquarium '
              'and grant Exercise permission, then try seeding again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _openHealthConnectManageAccess();
                },
                child: const Text('Open Health Connect'),
              ),
            ],
          ),
        );
        return;
      }

      final now = DateTime.now();
      final sessions = <({
        HealthWorkoutActivityType activity,
        DateTime start,
        DateTime end,
      })>[
        (
          activity: HealthWorkoutActivityType.YOGA,
          start: now.subtract(const Duration(hours: 2)),
          end: now.subtract(const Duration(hours: 0, minutes: 21)),
        ),
        (
          activity: HealthWorkoutActivityType.RUNNING,
          start: now.subtract(const Duration(days: 1, hours: 3)),
          end: now.subtract(const Duration(days: 1, hours: 2, minutes: 15)),
        ),
        (
          activity: HealthWorkoutActivityType.RUNNING,
          start: now.subtract(const Duration(days: 2, hours: 4)),
          end: now.subtract(const Duration(days: 2, hours: 3, minutes: 10)),
        ),
      ];

      for (final s in sessions) {
        await _health.writeWorkoutData(
          activityType: s.activity,
          title: 'Seed workout',
          start: s.start,
          end: s.end,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seeded 3 workouts into Health Connect')),
      );

      final okRead = await _ensureReadPermission(force: true);
      if (!okRead) {
        if (!mounted) return;
        setState(() => _loading = false);
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Read permission required'),
            content: const Text(
              'The test workouts were created, but the app cannot read them yet.\n\n'
              'Please grant Exercise, Distance, Total Calories Burned, and Steps read '
              'permissions in Health Connect, then press Refresh.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _openHealthConnectManageAccess();
                },
                child: const Text('Open Health Connect'),
              ),
            ],
          ),
        );
        return;
      }

      await Future.delayed(const Duration(seconds: 2));
      await _load(forceRequestPermission: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seed failed: $e')),
      );
    }
  }

  static const _hcChannel = MethodChannel('health_connect');

  Future<void> _openHealthConnectManageAccess() async {
    try {
      await _hcChannel.invokeMethod('openManageHealthPermissions');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open Health Connect settings: $e')),
      );
    }
  }

  Future<bool> _ensureReadPermission({bool force = false}) async {
    final types = <HealthDataType>[
      HealthDataType.WORKOUT,
      HealthDataType.DISTANCE_DELTA,
      HealthDataType.TOTAL_CALORIES_BURNED,
      HealthDataType.STEPS,
    ];

    final permissions = List<HealthDataAccess>.filled(
      types.length,
      HealthDataAccess.READ,
    );

    if (!force) {
      final has = await _health.hasPermissions(
        types,
        permissions: permissions,
      );
      debugPrint(
        'hasPermissions(WORKOUT + DISTANCE_DELTA + TOTAL_CALORIES_BURNED + STEPS, READ) = $has',
      );
      if (has == true) return true;
    }

    final granted = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );
    debugPrint(
      'requestAuthorization(WORKOUT + DISTANCE_DELTA + TOTAL_CALORIES_BURNED + STEPS, READ) = $granted',
    );
    return granted;
  }

  Future<bool> _ensureWritePermission() async {
    final types = <HealthDataType>[HealthDataType.WORKOUT];
    final permissions = List<HealthDataAccess>.filled(
      types.length,
      HealthDataAccess.READ_WRITE,
    );

    final granted = await _health.requestAuthorization(
      types,
      permissions: permissions,
    );
    debugPrint('requestAuthorization(WORKOUT, READ_WRITE) = $granted');
    return granted;
  }

  Future<void> _load({required bool forceRequestPermission}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await _ensureReadPermission(force: forceRequestPermission);
      if (!ok) {
        throw Exception('Health permission not granted');
      }

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 3));

      final types = <HealthDataType>[
        HealthDataType.WORKOUT,
      ];
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );

      for (var p in points) {
        print("TYPE: ${p.type}");
        print("VALUE: ${p.value}");
        print("FROM: ${p.dateFrom}");
        print("TO: ${p.dateTo}");
        print("SOURCE: ${p.sourceName}");
      }

      final deduped = _health
          .removeDuplicates(points)
          .where((p) => p.type == HealthDataType.WORKOUT);

      _all
        ..clear()
        ..addAll(
          deduped.map((p) {
            final from = p.dateFrom;
            final to = p.dateTo;
            final minutes = to.difference(from).inMinutes;

            final raw = p.value.toString();
            final mapped = _mapToActivityType(raw);

            final id =
                '${p.sourceName}|${from.millisecondsSinceEpoch}|${to.millisecondsSinceEpoch}|${p.typeString}';

            return _Candidate(
              id: id,
              start: from,
              end: to,
              minutes: minutes,
              raw: raw,
              source: p.sourceName,
              mappedActivityType: mapped,
            );
          }).where((c) => c.minutes > 0),
        );

      _all.sort((a, b) => b.start.compareTo(a.start));

      if (_selectedId != null && !_all.any((c) => c.id == _selectedId)) {
        _selectedId = null;
      }
      _rowKeys
        ..clear()
        ..addEntries(_all.map((c) => MapEntry(c.id, GlobalKey())));

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _toggle(String id, bool selected) {
    setState(() {
      _selectedId = selected ? id : null;
    });
  }

  Future<String?> _captureSelectedRowPhoto(String id) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _rowKeys[id]?.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final file = File(
        '${Directory.systemTemp.path}/health_import_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Failed to capture selected health row: $e');
      return null;
    }
  }

  Future<void> _importSelected() async {
    final selectedId = _selectedId;
    if (selectedId == null) return;

    final selected = _all.where((c) => c.id == selectedId).toList();
    if (selected.isEmpty) return;

    final c = selected.first;
    final evidencePhotoPath = await _captureSelectedRowPhoto(c.id);

    final item = HealthImportItem(
      start: c.start,
      end: c.end,
      durationMinutes: c.minutes,
      mappedActivityType: c.mappedActivityType,
      source: c.source,
      notes: 'This data is imported from Health',
      evidencePhotoPath: evidencePhotoPath,
    );

    if (!mounted) return;
    Navigator.pop(context, item);
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
            tooltip: 'Seed test data',
            icon: const Icon(Icons.science),
            onPressed: _loading ? null : _seedTestHealthData,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed:
                _loading ? null : () => _load(forceRequestPermission: false),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF0AA0D6),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(
                      message: _error!,
                      onRetry: () => _load(forceRequestPermission: true),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Please Select the data you want to import below',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _all.length + 1,
                            itemBuilder: (context, index) {
                              if (_all.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Center(
                                    child: Text(
                                      'No data in last 3 days.',
                                      style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              if (index == 0) {
                                return const SizedBox(height: 6);
                              }

                              final c = _all[index - 1];
                              final checked = _selectedId == c.id;

                              return RepaintBoundary(
                                key: _rowKeys[c.id],
                                child: _ImportRow(
                                  checked: checked,
                                  onChanged: (v) => _toggle(c.id, v),
                                  activity: c.mappedActivityType,
                                  minutesText: '${c.minutes} mins',
                                  dateText: _formatDate(c.start),
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
                                  _selectedId == null ? null : _importSelected,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDarkGrey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _selectedId == null
                                    ? 'import (0)'
                                    : 'import (1)',
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

class _ImportRow extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool> onChanged;
  final String activity;
  final String minutesText;
  final String dateText;

  const _ImportRow({
    required this.checked,
    required this.onChanged,
    required this.activity,
    required this.minutesText,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final rowColor = checked
        ? AppColors.accentOrange.withValues(alpha: 0.92)
        : AppColors.cardBackground;
    final borderColor = checked ? Colors.white : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: checked ? const EdgeInsets.all(4) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: checked ? AppColors.accentOrange.withValues(alpha: 0.22) : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: checked ? AppColors.accentOrange : Colors.transparent,
          width: checked ? 2 : 0,
        ),
        boxShadow: checked
            ? [
                BoxShadow(
                  color: AppColors.accentOrange.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => onChanged(!checked),
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    checked ? AppColors.accentOrange : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: checked ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.radio_button_checked, color: Colors.white)
                  : const Icon(Icons.radio_button_unchecked,
                      color: Colors.white54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => onChanged(!checked),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 52,
                decoration: BoxDecoration(
                  color: rowColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: borderColor, width: checked ? 1.5 : 0),
                ),
                child: Row(
                  children: [
                    _Cell(text: activity),
                    _Divider(),
                    _Cell(text: minutesText),
                    _Divider(),
                    _Cell(text: dateText),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: double.infinity,
      color: Colors.white.withOpacity(0.08),
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
