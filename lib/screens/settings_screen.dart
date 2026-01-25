import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoFlash = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _exportFormat = 'Excel';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.document_scanner,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GradeScan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Scanner Settings
            const Text(
              'Scanner Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.flash_on,
                  title: 'Auto Flash',
                  subtitle: 'Automatically turn on flash in low light',
                  trailing: Switch(
                    value: _autoFlash,
                    onChanged: (value) => setState(() => _autoFlash = value),
                    activeColor: const Color(0xFF2563EB),
                  ),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.volume_up,
                  title: 'Sound Effects',
                  subtitle: 'Play sound when scanning is complete',
                  trailing: Switch(
                    value: _soundEnabled,
                    onChanged: (value) => setState(() => _soundEnabled = value),
                    activeColor: const Color(0xFF2563EB),
                  ),
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.vibration,
                  title: 'Vibration',
                  subtitle: 'Vibrate on successful scan',
                  trailing: Switch(
                    value: _vibrationEnabled,
                    onChanged: (value) =>
                        setState(() => _vibrationEnabled = value),
                    activeColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Export Settings
            const Text(
              'Export Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.file_copy,
                  title: 'Default Export Format',
                  subtitle: _exportFormat,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showExportFormatSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // About
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.star_outline,
                  title: 'Rate App',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            Center(
              child: Text(
                'Made with ❤️ for Educators',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showExportFormatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Export Format',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Color(0xFF10B981)),
              title: const Text('Excel (.xlsx)'),
              trailing: _exportFormat == 'Excel'
                  ? const Icon(Icons.check, color: Color(0xFF2563EB))
                  : null,
              onTap: () {
                setState(() => _exportFormat = 'Excel');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFFEF4444),
              ),
              title: const Text('PDF (.pdf)'),
              trailing: _exportFormat == 'PDF'
                  ? const Icon(Icons.check, color: Color(0xFF2563EB))
                  : null,
              onTap: () {
                setState(() => _exportFormat = 'PDF');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Color(0xFF2563EB)),
              title: const Text('CSV (.csv)'),
              trailing: _exportFormat == 'CSV'
                  ? const Icon(Icons.check, color: Color(0xFF2563EB))
                  : null,
              onTap: () {
                setState(() => _exportFormat = 'CSV');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
