import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/gradient_background.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Management'),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Export Data Section
                const Text(
                  'Export Data',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Backup your progress',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                _buildExportButton(
                  context,
                  icon: Icons.code,
                  label: 'Export as JSON',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Export as JSON feature coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildExportButton(
                  context,
                  icon: Icons.table_chart,
                  label: 'Export as TSV',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Export as TSV feature coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildExportButton(
                  context,
                  icon: Icons.folder_zip,
                  label: 'Export as ZIP',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Export as ZIP feature coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Divider
                const Divider(color: AppColors.textGrey),
                const SizedBox(height: 32),

                // Import Data Section
                const Text(
                  'Import Data',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Restore from backup',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Import feature coming soon')),
                      );
                    },
                    icon: const Icon(Icons.file_upload),
                    label: const Text(
                      'Import from File',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGrey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Divider
                const Divider(color: AppColors.textGrey),
                const SizedBox(height: 32),

                // Storage Info
                const Text(
                  'Storage Info',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Database size:', '2.3 MB'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Photos:', '42 items (15.7 MB)'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Total storage:', '18.0 MB'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Last backup:', 'Never', isWarning: true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Divider
                const Divider(color: AppColors.textGrey),
                const SizedBox(height: 32),

                // Danger Zone
                const Text(
                  'Danger Zone',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showDeleteConfirmation(context);
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text(
                      'DELETE ALL DATA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone. All your data will be permanently deleted.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
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

  Widget _buildExportButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkGrey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isWarning ? Colors.orange : AppColors.textWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryDarkGrey,
        title: const Text(
          'Delete All Data?',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'This will permanently delete all your data including:\n\n'
          '• Focus sessions\n'
          '• Activities\n'
          '• Aquarium (fishes & decorations)\n'
          '• Points and achievements\n\n'
          'This action CANNOT be undone!',
          style: TextStyle(color: AppColors.textWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete all data feature coming soon'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
