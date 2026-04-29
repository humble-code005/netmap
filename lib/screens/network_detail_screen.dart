import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../models/wifi_network_model.dart';
import '../services/crowd_service.dart';
import '../services/database_service.dart';
import '../widgets/signal_chart.dart';
import '../widgets/crowd_insight_card.dart';
import '../widgets/pro_widgets.dart';
import '../theme/app_theme.dart';

class NetworkDetailScreen extends StatefulWidget {
  final WifiNetworkModel network;

  const NetworkDetailScreen({super.key, required this.network});

  @override
  State<NetworkDetailScreen> createState() => _NetworkDetailScreenState();
}

class _NetworkDetailScreenState extends State<NetworkDetailScreen> {
  final List<int> _signalHistory = [];
  final DatabaseService _dbService = DatabaseService();
  late final CrowdService _crowdService;
  CrowdInsight? _crowdInsight;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _crowdService = CrowdService(_dbService);
    _signalHistory.add(widget.network.signalStrength);
    _loadCrowdInsight();
    _startMonitoring();
  }

  Future<void> _loadCrowdInsight() async {
    final insight = await _crowdService.getInsight(
      widget.network.bssid,
      widget.network.ssid,
    );
    if (mounted) {
      setState(() => _crowdInsight = insight);
    }
  }

  void _startMonitoring() {
    _subscription = WiFiScan.instance.onScannedResultsAvailable.listen((_) async {
      try {
        final results = await WiFiScan.instance.getScannedResults();
        final match = results.where((ap) => ap.bssid == widget.network.bssid);
        if (match.isNotEmpty && mounted) {
          setState(() {
            _signalHistory.add(match.first.level);
            if (_signalHistory.length > 30) {
              _signalHistory.removeAt(0);
            }
          });
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final network = widget.network;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(network.ssid),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgDark, Color(0xFF1A1F35), AppTheme.bgDark],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: kToolbarHeight + 40),
            // --- Signal Quality Hero ---
            ProGlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoChip(
                    icon: Icons.signal_cellular_alt,
                    label: 'Signal',
                    value: '${network.signalStrength} dBm',
                    color: AppTheme.primary,
                  ),
                  _InfoChip(
                    icon: Icons.speed,
                    label: 'Quality',
                    value: network.qualityLabel,
                    color: AppTheme.primaryLight,
                  ),
                  _InfoChip(
                    icon: Icons.score,
                    label: 'Score',
                    value: '${network.qualityScore}/100',
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),

            // --- Signal History Chart ---
            ProGlassCard(
              title: 'Signal Strength Over Time',
              icon: Icons.show_chart,
              child: SizedBox(
                height: 180,
                child: SignalChart(signalHistory: _signalHistory),
              ),
            ),

            // --- Network Details ---
            ProGlassCard(
              title: 'Network Details',
              icon: Icons.info_outline,
              child: Column(
                children: [
                  _DetailRow(label: 'SSID', value: network.ssid),
                  _DetailRow(label: 'BSSID (MAC)', value: network.bssid),
                  _DetailRow(label: 'Frequency', value: '${network.frequency} MHz'),
                  _DetailRow(label: 'Band', value: network.bandLabel),
                  _DetailRow(label: 'Channel', value: network.channel.toString()),
                  _DetailRow(
                    label: 'Security',
                    value: network.securityType,
                    valueColor: network.isOpen ? AppTheme.danger : AppTheme.primary,
                  ),
                ],
              ),
            ),

            // Security warning for open networks
            if (network.isOpen)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is an open network with no encryption. Your data could be intercepted. Avoid sensitive activities.',
                        style: TextStyle(fontSize: 13, color: AppTheme.danger, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            // --- Crowd Insights ---
            if (_crowdInsight != null)
              ProGlassCard(
                title: 'Crowd Insights',
                icon: Icons.groups_outlined,
                child: CrowdInsightCard(insight: _crowdInsight!),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

