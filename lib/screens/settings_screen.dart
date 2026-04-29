import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/database_service.dart';
import 'history_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/pro_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;
  const SettingsScreen({super.key, required this.onThemeChanged, required this.isDarkMode});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService();
  int _scanCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final count = await _db.getScanCount();
    if (mounted) setState(() => _scanCount = count);
  }

  Future<void> _exportCSV() async {
    try {
      final csv = await _db.exportAsCSV();
      final dir = await getExternalStorageDirectory();
      final file = File('${dir!.path}/wifi_netmap_export.csv');
      await file.writeAsString(csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Exported to ${file.path}'),
          backgroundColor: AppTheme.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Clear All Data?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will delete all scan history, crowd data, and speed test results. This action cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('DELETE ALL', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.clearHistory();
      _loadStats();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared'), backgroundColor: AppTheme.warning));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.bgDark, Color(0xFF1A1F35), AppTheme.bgDark],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          const _SectionTitle(title: 'APPEARANCE'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Toggle high-fidelity dark theme', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              value: widget.isDarkMode,
              onChanged: widget.onThemeChanged,
              activeColor: AppTheme.primary,
              secondary: Icon(widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'DATA MANAGEMENT'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.history_rounded,
                  title: 'Scan History',
                  subtitle: '$_scanCount scans recorded',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                ),
                _SettingsTile(
                  icon: Icons.file_download_outlined,
                  title: 'Export as CSV',
                  subtitle: 'Save scan data to storage',
                  onTap: _exportCSV,
                ),
                _SettingsTile(
                  icon: Icons.delete_sweep_outlined,
                  title: 'Clear All Data',
                  subtitle: 'Erase all historical records',
                  titleColor: AppTheme.danger,
                  onTap: _clearData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'ABOUT'),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.wifi_rounded, color: AppTheme.primary, size: 32),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('netmap Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Version 2.0.0 (Premium Build)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 16),
                const Text(
                  'A high-performance WiFi analyzer and crowd-sourced signal mapping tool.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.2)),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.titleColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppTheme.textSecondary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: titleColor)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}

