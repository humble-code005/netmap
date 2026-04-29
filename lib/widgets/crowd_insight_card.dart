/// ==========================================================================
/// Crowd Insight Card — Displays aggregated historical data for a network.
///
/// Shows crowd-sourced stats like average signal strength, number of scans,
/// reliability score, and a recommendation based on historical performance.
/// ==========================================================================
import 'package:flutter/material.dart';
import '../services/crowd_service.dart';

class CrowdInsightCard extends StatelessWidget {
  final CrowdInsight insight;

  const CrowdInsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.withOpacity(0.15),
              Colors.blue.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.people, color: Colors.deepPurple[300], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Crowd Insights',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple[300],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.wifi,
                  label: 'Avg Signal',
                  value: '${insight.averageSignal.round()} dBm',
                  subValue: insight.averageQualityLabel,
                ),
                _StatItem(
                  icon: Icons.radar,
                  label: 'Total Scans',
                  value: insight.totalScans.toString(),
                  subValue: insight.reliabilityLabel,
                ),
                _StatItem(
                  icon: Icons.location_on,
                  label: 'Locations',
                  value: insight.locationCount.toString(),
                  subValue: 'Seen at',
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Recommendation text
            Text(
              _getRecommendation(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecommendation() {
    final quality = insight.averageQualityLabel;
    final scans = insight.totalScans;

    if (scans < 5) {
      return '📊 Limited data — keep scanning to build more insights for this network.';
    }

    if (quality == 'Excellent' || quality == 'Good') {
      return '✅ This network is typically $quality at your scanned locations. Recommended for use!';
    } else if (quality == 'Fair') {
      return '⚠️ This network has average performance. Consider alternatives if available.';
    } else {
      return '❌ This network usually has poor signal. Try moving closer to the router.';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subValue;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          subValue,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
