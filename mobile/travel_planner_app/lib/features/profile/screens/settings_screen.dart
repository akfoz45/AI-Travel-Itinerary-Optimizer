import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _tripNotifications = true;
  bool _weatherAlerts = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _isDarkMode = isDark; 

    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSectionHeader('Appearance', isDark),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Reduce eye strain',
            value: themeProvider.isDarkMode, 
            onChanged: (value) {
              themeProvider.toggleTheme(value); 
            },
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Notifications', isDark),
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Travel Reminders',
            subtitle: 'Let us know about your upcoming routes.',
            value: _tripNotifications,
            onChanged: (value) => setState(() => _tripNotifications = value),
          ),
          _buildSwitchTile(
            icon: Icons.cloud_outlined,
            title: 'Weather Alerts',
            subtitle: 'Update the route during sudden weather changes.',
            value: _weatherAlerts,
            onChanged: (value) => setState(() => _weatherAlerts = value),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Privacy and Data Security', isDark),
          _buildActionTile(
            icon: Icons.location_on_outlined,
            title: 'Location Permissions',
            onTap: () {
              // TODO: Cihazın konum ayarları sayfasına yönlendir
            },
          ),
          _buildActionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Data Sharing Preferences',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            ),
            title: const Text(
              'Delete My Account and Data',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
            ),
            onTap: () {
              // TODO: Hesabı kalıcı silme onayı için bir BottomSheet aç
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        activeColor: const Color(0xFF4F46E5),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4F46E5)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}