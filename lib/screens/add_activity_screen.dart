import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../widgets/gradient_background.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({Key? key}) : super(key: key);

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  String _selectedActivity = AppConstants.activityTypes[0];
  String _selectedMood = AppConstants.moods[0];
  final TextEditingController _durationController =
      TextEditingController(text: '30');
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Activity'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Type
                const Text(
                  'Activity Type',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedActivity,
                      isExpanded: true,
                      dropdownColor: AppColors.primaryDarkGrey,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 16,
                      ),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.textWhite),
                      items: AppConstants.activityTypes.map((activity) {
                        return DropdownMenuItem(
                          value: activity,
                          child: Text(activity),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedActivity = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Duration
                const Text(
                  'Duration (minutes)',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
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
                      hintText: 'Enter duration',
                      hintStyle: TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Mood
                const Text(
                  'Mood',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: AppConstants.moods.map((mood) {
                    return _buildMoodButton(mood);
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Notes
                const Text(
                  'Notes (Optional)',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textWhite),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Great run today!',
                      hintStyle: TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Add Photo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textGrey, width: 2),
                  ),
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Photo upload coming soon')),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt, color: AppColors.textGrey),
                        SizedBox(width: 12),
                        Text(
                          '📷 Add Photo (Optional)',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      final duration =
                          int.tryParse(_durationController.text) ?? 30;
                      final points =
                          duration * 1; // 1 point per minute for activities

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Activity saved! +$points points!')),
                      );

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SAVE ACTIVITY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildMoodButton(String mood) {
    final isSelected = _selectedMood == mood;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentOrange.withOpacity(0.3)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentOrange : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            mood,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}
