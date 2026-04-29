import 'dart:async';
import 'package:flutter/material.dart';
import '../models/wifi_network_model.dart';
import '../services/scanner_service.dart';
import '../widgets/channel_chart.dart';
import '../widgets/pro_widgets.dart';
import '../theme/app_theme.dart';

class ChannelScreen extends StatefulWidget {
  const ChannelScreen({super.key});
  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final ScannerService _scannerService = ScannerService();
  List<WifiNetworkModel> _networks = [];
  bool _show5GHz = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _scannerService.onScannedResults.listen((results) {
      if (mounted) setState(() => _networks = results);
    });
    _scannerService.startScan();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _getRecommendation() {
    final filtered = _networks.where((n) => _show5GHz ? n.is5GHz : n.is24GHz);
    if (filtered.isEmpty) return 'No networks found on this band.';
    final channelCounts = <int, int>{};
    for (final n in filtered) {
      channelCounts[n.channel] = (channelCounts[n.channel] ?? 0) + 1;
    }
    final allChannels = _show5GHz ? [36, 40, 44, 48, 149, 153, 157, 161, 165] : [1, 6, 11];
    int bestChannel = allChannels.first;
    int bestCount = channelCounts[bestChannel] ?? 0;
    for (final ch in allChannels) {
      final count = channelCounts[ch] ?? 0;
      if (count < bestCount) {
        bestCount = count;
        bestChannel = ch;
      }
    }
    return bestCount == 0
        ? 'Channel $bestChannel is completely free!'
        : 'Best channel: $bestChannel ($bestCount network${bestCount == 1 ? "" : "s"})';
  }

  @override
  Widget build(BuildContext context) {
    final count2g = _networks.where((n) => n.is24GHz).length;
    final count5g = _networks.where((n) => n.is5GHz).length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.bgDark, Color(0xFF1A1F35), AppTheme.bgDark],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: _BandCard(
                    label: '2.4 GHz',
                    count: count2g,
                    selected: !_show5GHz,
                    onTap: () => setState(() => _show5GHz = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BandCard(
                    label: '5 GHz',
                    count: count5g,
                    selected: _show5GHz,
                    onTap: () => setState(() => _show5GHz = true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ProGlassCard(
                  title: 'Channel Distribution (${_show5GHz ? "5 GHz" : "2.4 GHz"})',
                  icon: Icons.bar_chart_rounded,
                  child: SizedBox(
                    height: 200,
                    child: ChannelChart(networks: _networks, show5GHz: _show5GHz),
                  ),
                ),
                ProGlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommendation',
                              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              _getRecommendation(),
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Detected Networks',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ..._networks.where((n) => _show5GHz ? n.is5GHz : n.is24GHz).map((n) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.router_outlined, color: AppTheme.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.ssid, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(
                                  'CH ${n.channel} • ${n.signalStrength} dBm',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${n.qualityScore}',
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BandCard extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _BandCard({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : AppTheme.bgCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count networks',
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppTheme.primary.withOpacity(0.7) : AppTheme.textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

