/// ==========================================================================
/// Channel Chart Widget — Bar chart showing WiFi channel congestion.
///
/// Displays how many networks are using each WiFi channel, helping users
/// identify the least congested channels. Color-coded from green (empty)
/// to red (crowded).
/// ==========================================================================
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/wifi_network_model.dart';

class ChannelChart extends StatelessWidget {
  final List<WifiNetworkModel> networks;
  final bool show5GHz;

  const ChannelChart({
    super.key,
    required this.networks,
    this.show5GHz = false,
  });

  @override
  Widget build(BuildContext context) {
    // Count networks per channel
    final channelCounts = <int, int>{};
    for (final network in networks) {
      if (show5GHz ? network.is5GHz : network.is24GHz) {
        channelCounts[network.channel] = (channelCounts[network.channel] ?? 0) + 1;
      }
    }

    if (channelCounts.isEmpty) {
      return Center(
        child: Text(
          'No ${show5GHz ? "5 GHz" : "2.4 GHz"} networks found',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // Define the channels we want to show
    final channels = show5GHz
        ? [36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 149, 153, 157, 161, 165]
        : [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

    final maxCount = channelCounts.values.isEmpty
        ? 1
        : channelCounts.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxCount.toDouble() + 1,

            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final ch = channels[group.x.toInt()];
                  return BarTooltipItem(
                    'CH $ch\n${rod.toY.toInt()} networks',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),

            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value == value.roundToDouble()) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < channels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          channels[idx].toString(),
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 1,
              ),
            ),

            borderData: FlBorderData(show: false),

            barGroups: List.generate(channels.length, (index) {
              final ch = channels[index];
              final count = channelCounts[ch] ?? 0;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: count.toDouble(),
                    width: show5GHz ? 8 : 14,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _getBarColor(count, maxCount).withOpacity(0.7),
                        _getBarColor(count, maxCount),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Color-code bars: green (empty) → yellow → red (crowded).
  Color _getBarColor(int count, int maxCount) {
    if (count == 0) return Colors.grey.withOpacity(0.3);
    final ratio = count / maxCount;
    if (ratio <= 0.33) return Colors.greenAccent;
    if (ratio <= 0.66) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
