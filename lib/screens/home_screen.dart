import 'package:flutter/material.dart';
import 'scanner_screen.dart';
import 'channel_screen.dart';
import 'speed_test_screen.dart';
import 'heatmap_screen.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;
  const HomeScreen({super.key, required this.onThemeChanged, required this.isDarkMode});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<String> _titles = ['NetMap', 'Channels', 'Speed Test', 'Heatmap', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ScannerScreen(),
      const ChannelScreen(),
      const SpeedTestScreen(),
      const HeatmapScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged, isDarkMode: widget.isDarkMode),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
            IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        backgroundColor: AppTheme.bgDark,
        indicatorColor: AppTheme.primary.withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wifi_find, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.wifi_find, color: AppTheme.primary),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.bar_chart, color: AppTheme.primary),
            label: 'Channels',
          ),
          NavigationDestination(
            icon: Icon(Icons.speed, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.speed, color: AppTheme.primary),
            label: 'Speed',
          ),
          NavigationDestination(
            icon: Icon(Icons.map, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.map, color: AppTheme.primary),
            label: 'Heatmap',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, color: AppTheme.textSecondary),
            selectedIcon: Icon(Icons.settings, color: AppTheme.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
