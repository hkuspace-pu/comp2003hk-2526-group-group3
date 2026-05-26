import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

enum ShareTarget { whatsapp, instagram, facebook }

extension ShareTargetUI on ShareTarget {
  String get label {
    switch (this) {
      case ShareTarget.whatsapp:
        return 'WhatsApp';
      case ShareTarget.instagram:
        return 'Instagram';
      case ShareTarget.facebook:
        return 'Facebook';
    }
  }

  IconData get icon {
    switch (this) {
      case ShareTarget.whatsapp:
        return Icons.chat_bubble;
      case ShareTarget.instagram:
        return Icons.camera_alt;
      case ShareTarget.facebook:
        return Icons.facebook;
    }
  }

  Color get color {
    switch (this) {
      case ShareTarget.whatsapp:
        return const Color(0xFF25D366);
      case ShareTarget.instagram:
        return const Color(0xFFE1306C);
      case ShareTarget.facebook:
        return const Color(0xFF1877F2);
    }
  }
}

class SharePreviewScreen extends StatefulWidget {
  const SharePreviewScreen({
    super.key,
    required this.imageBytes,
    this.shareText,
    this.popToRootAfterShare = true,
    this.canExportToHealth = false,
    this.exportActivityType,
    this.exportDurationMinutes,
  });

  final Uint8List imageBytes;
  final String? shareText;
  final bool popToRootAfterShare;
  final bool canExportToHealth;
  final String? exportActivityType;
  final int? exportDurationMinutes;

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  final Health _health = Health();

  bool _sharing = false;
  bool _exportingToHealth = false;
  ShareTarget _selectedTarget = ShareTarget.whatsapp;

  @override
  void initState() {
    super.initState();
    _health.configure();
  }

  HealthWorkoutActivityType _mapActivityTypeToWorkout(String? activityType) {
    final lower = (activityType ?? '').toLowerCase();

    if (lower.contains('run')) return HealthWorkoutActivityType.RUNNING;
    if (lower.contains('walk')) return HealthWorkoutActivityType.WALKING;
    if (lower.contains('swim')) return HealthWorkoutActivityType.SWIMMING;
    if (lower.contains('yoga')) return HealthWorkoutActivityType.YOGA;

    return HealthWorkoutActivityType.RUNNING;
  }

  Future<bool> _ensureHealthWritePermission() async {
    if (Platform.isAndroid) {
      await Permission.activityRecognition.request();
    }

    final types = <HealthDataType>[HealthDataType.WORKOUT];
    final permissions = List<HealthDataAccess>.filled(
      types.length,
      HealthDataAccess.READ_WRITE,
    );

    return _health.requestAuthorization(
      types,
      permissions: permissions,
    );
  }

  Future<void> _exportToHealth() async {
    if (_exportingToHealth) return;

    final duration = widget.exportDurationMinutes;
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot export: invalid duration.')),
      );
      return;
    }

    setState(() => _exportingToHealth = true);

    try {
      final granted = await _ensureHealthWritePermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health write permission not granted.')),
        );
        return;
      }

      final end = DateTime.now();
      final start = end.subtract(Duration(minutes: duration));

      await _health.writeWorkoutData(
        activityType: _mapActivityTypeToWorkout(widget.exportActivityType),
        title: widget.exportActivityType ?? 'Focus Aquarium Activity',
        start: start,
        end: end,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported to Health successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export to Health: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportingToHealth = false);
    }
  }

  Future<void> _share() async {
    if (_sharing) return;

    setState(() => _sharing = true);

    try {
      final xfile = XFile.fromData(
        widget.imageBytes,
        mimeType: 'image/png',
        name: 'activity.png',
      );

      await Share.shareXFiles(
        [xfile],
        text: widget.shareText ?? 'Share to ${_selectedTarget.label}',
        subject: 'Share',
      );

      if (!mounted) return;
      if (widget.popToRootAfterShare) {
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _leavePreview() {
    if (widget.popToRootAfterShare) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leavePreview,
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _sharing ? null : _share,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _sharing
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                'SHARE TO ${_selectedTarget.label.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    if (widget.canExportToHealth) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed:
                              _exportingToHealth ? null : _exportToHealth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDarkGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _exportingToHealth
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.health_and_safety),
                          label: Text(
                            _exportingToHealth
                                ? 'EXPORTING...'
                                : 'EXPORT TO HEALTH',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Positioned(
                  right: 0,
                  bottom: widget.canExportToHealth ? 148 : 80,
                  child: _ShareTargetRail(
                    selected: _selectedTarget,
                    onSelect: (t) => setState(() => _selectedTarget = t),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareTargetRail extends StatelessWidget {
  const _ShareTargetRail({
    required this.selected,
    required this.onSelect,
  });

  final ShareTarget selected;
  final ValueChanged<ShareTarget> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Share To',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...ShareTarget.values.map((t) {
            final isSelected = t == selected;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: () => onSelect(t),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? t.color : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white70 : Colors.white12,
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Icon(t.icon, color: Colors.white, size: 22),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
