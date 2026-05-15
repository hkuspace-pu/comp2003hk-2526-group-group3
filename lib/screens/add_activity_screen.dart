import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
import './import_health_screen.dart';
import 'share_preview_screen.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({Key? key}) : super(key: key);

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey _formCaptureKey = GlobalKey();

  String _selectedActivity = AppConstants.activityTypes[0];
  String _selectedMood = AppConstants.moods[0];

  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedEvidence;
  String? _selectedEvidenceType;

  bool _isSaving = false;

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<Uint8List> _captureFormBytes() async {
    FocusScope.of(context).unfocus();

    await WidgetsBinding.instance.endOfFrame;

    final boundary = _formCaptureKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('not found render object for capture');
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null)
      throw Exception('Can not get PNG byte data from image');

    return byteData.buffer.asUint8List();
  }

  Future<void> _openImport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await Navigator.push<List<HealthImportItem>>(
      context,
      MaterialPageRoute(builder: (_) => const ImportHealthScreen()),
    );

    if (!mounted || result == null || result.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      for (final item in result) {
        await _firestoreService.saveActivityLog(
          uid: user.uid,
          activityType: item.mappedActivityType,
          durationMinutes: item.durationMinutes,
          mood: _selectedMood,
          notes: (item.notes ?? '').trim().isEmpty
              ? 'Imported from Health (${item.source})\n${item.start.toLocal()} - ${item.end.toLocal()}'
              : item.notes!.trim(),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Imported ${result.length} activities from Health')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }



  Future<void> _pickEvidence(ImageSource source, {required bool isVideo}) async {
    try {
      final XFile? picked = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      setState(() {
        _selectedEvidence = picked;
        _selectedEvidenceType = isVideo ? 'video' : 'image';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select evidence: $e')),
      );
    }
  }

  Future<void> _showEvidencePicker() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.primaryDarkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Widget option({
          required IconData icon,
          required String title,
          required VoidCallback onTap,
        }) {
          return ListTile(
            leading: Icon(icon, color: AppColors.accentOrange),
            title: Text(
              title,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: onTap,
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textGrey.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload Evidence',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose an image or video as supporting evidence.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              option(
                icon: Icons.photo_library_outlined,
                title: 'Pick Image from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickEvidence(ImageSource.gallery, isVideo: false);
                },
              ),
              option(
                icon: Icons.videocam_outlined,
                title: 'Pick Video from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickEvidence(ImageSource.gallery, isVideo: true);
                },
              ),
              option(
                icon: Icons.camera_alt_outlined,
                title: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickEvidence(ImageSource.camera, isVideo: false);
                },
              ),
              option(
                icon: Icons.smart_display_outlined,
                title: 'Record Video',
                onTap: () {
                  Navigator.pop(context);
                  _pickEvidence(ImageSource.camera, isVideo: true);
                },
              ),
              if (_selectedEvidence != null)
                option(
                  icon: Icons.delete_outline,
                  title: 'Remove Selected Evidence',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedEvidence = null;
                      _selectedEvidenceType = null;
                    });
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvidenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidence (optional)',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textWhite.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a photo or video as proof for this activity.',
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
                  onPressed: _isSaving ? null : _showEvidencePicker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _selectedEvidence == null
                        ? 'UPLOAD EVIDENCE'
                        : 'CHANGE EVIDENCE',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (_selectedEvidence != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkGrey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedEvidenceType == 'video'
                            ? Icons.movie_creation_outlined
                            : Icons.image_outlined,
                        color: AppColors.accentOrange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedEvidenceType == 'video'
                                  ? 'Selected video'
                                  : 'Selected image',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedEvidence!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _selectedEvidence = null;
                                  _selectedEvidenceType = null;
                                });
                              },
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid duration')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? evidenceUrl;
      String? evidencePath;
      String? evidenceFileName;
      String? evidenceContentType;

      if (_selectedEvidence != null && _selectedEvidenceType != null) {
        final evidenceBytes = await _selectedEvidence!.readAsBytes();
        final uploadResult = await _firestoreService.uploadActivityEvidence(
          uid: user.uid,
          bytes: evidenceBytes,
          evidenceType: _selectedEvidenceType!,
          originalFileName: _selectedEvidence!.name,
        );
        evidenceUrl = uploadResult['url'];
        evidencePath = uploadResult['path'];
        evidenceFileName = uploadResult['fileName'];
        evidenceContentType = uploadResult['contentType'];
      }

      await _firestoreService.saveActivityLog(
        uid: user.uid,
        activityType: _selectedActivity,
        durationMinutes: duration,
        mood: _selectedMood,
        notes: _notesController.text.trim(),
        evidenceUrl: evidenceUrl,
        evidenceType: _selectedEvidenceType,
        evidenceStoragePath: evidencePath,
        evidenceFileName: evidenceFileName,
        evidenceContentType: evidenceContentType,
      );

      final points = (duration * 1.5).round();

      if (mounted) {
        setState(() {
          _isSaving = false;
          _selectedEvidence = null;
          _selectedEvidenceType = null;
        });
      }
      await WidgetsBinding.instance.endOfFrame;
      final bytes = await _captureFormBytes();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SharePreviewScreen(
            imageBytes: bytes,
            shareText: 'Activity saved! +$points points 🎉',
            popToRootAfterShare: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save activity: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Activity'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RepaintBoundary(
                  key: _formCaptureKey,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF0AA0D6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Activity Type',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedActivity,
                            isExpanded: true,
                            dropdownColor: AppColors.cardBackground,
                            underline: const SizedBox.shrink(),
                            style: const TextStyle(color: AppColors.textWhite),
                            items: AppConstants.activityTypes.map((activity) {
                              return DropdownMenuItem(
                                value: activity,
                                child: Text(activity),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedActivity = value!);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Duration (minutes)',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'e.g. 30',
                              hintStyle: TextStyle(color: AppColors.textGrey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Mood',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: AppConstants.moods.map((mood) {
                            final isSelected = _selectedMood == mood;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedMood = mood),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.accentOrange
                                      : AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.accentOrange
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(mood,
                                      style: const TextStyle(fontSize: 28)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Notes (optional)',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 3,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'How did it go?',
                              hintStyle: TextStyle(color: AppColors.textGrey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildEvidenceSection(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _openImport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'IMPORT FROM HEALTH',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 12),
                        Text(
                          'SUBMIT ACTIVITY',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
