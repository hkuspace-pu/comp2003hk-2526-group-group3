import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../services/firestore_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';
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

    await _firestoreService.saveActivityLog(
      uid: user.uid,
      activityType: _selectedActivity,
      durationMinutes: duration,
      mood: _selectedMood,
      notes: _notesController.text.trim(),
    );

    final points = (duration * 1.5).round();

    try {
      setState(() => _isSaving = false);
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
        SnackBar(content: Text('Saved, but capture failed: $e')),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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
