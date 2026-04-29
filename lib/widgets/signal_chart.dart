/// ==========================================================================
/// Signal Chart Widget — Live line chart showing signal strength over time.
///
/// Used on the Network Detail Screen. Each time a new scan comes in,
/// the chart adds a data point and scrolls to show the latest readings.
/// Uses the fl_chart package for smooth, animated chart rendering.
/// ==========================================================================
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SignalChart extends StatelessWidget {
  /// List of signal strength values over time (most recent last).
  final List<int> signalHistory;

  const SignalChart({super.key, required this.signalHistory});

  @override
  Widget build(BuildContext context) {
    if (signalHistory.isEmpty) {
      return const Center(child: Text('No signal data yet'));
    }

    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            // Grid lines for readability
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.15),
                strokeWidth: 1,
              ),
            ),

            // Axis titles
            titlesData: FlTitlesData(
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()} dBm',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ),
            ),

            // Border
            borderData: FlBorderData(show: false),

            // Y-axis range: signal strength in dBm
            minY: -100,
            maxY: -20,

            // Line data
            lineBarsData: [
              LineChartBarData(
                spots: signalHistory.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.toDouble(),
                  );
                }).toList(),
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.cyanAccent,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: Colors.cyanAccent,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.cyanAccent.withOpacity(0.3),
                      Colors.cyanAccent.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],

            // Touch interaction
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y.toInt()} dBm',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
