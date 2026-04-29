/// ==========================================================================
/// Crowd Service — Aggregates historical scan data to provide insights.
///
/// "Crowd-based" data here means: aggregating YOUR past scans across
/// different locations and times to provide useful insights like:
///   - "This network averages -55 dBm at this location"
///   - "Based on 12 scans, this is usually a Good connection"
///   - "Network reliability: 85% (seen in 17 out of 20 scans)"
/// ==========================================================================
import 'database_service.dart';

/// Represents aggregated insight data for a specific network.
class CrowdInsight {
  final String bssid;
  final String ssid;
  final double averageSignal;
  final int totalScans;
  final int locationCount;
  final DateTime lastSeen;
  final String reliabilityLabel;

  CrowdInsight({
    required this.bssid,
    required this.ssid,
    required this.averageSignal,
    required this.totalScans,
    required this.locationCount,
    required this.lastSeen,
    required this.reliabilityLabel,
  });

  /// Quality label based on average signal strength.
  String get averageQualityLabel {
    if (averageSignal >= -50) return 'Excellent';
    if (averageSignal >= -60) return 'Good';
    if (averageSignal >= -70) return 'Fair';
    return 'Poor';
  }
}

class CrowdService {
  final DatabaseService _db;

  CrowdService(this._db);

  /// Get crowd-based insight for a specific network.
  Future<CrowdInsight?> getInsight(String bssid, String ssid) async {
    final data = await _db.getCrowdInsight(bssid);
    if (data == null) return null;

    final totalScans = data['total_scans'] as int;

    // Determine reliability based on how many times we've seen this network
    String reliability;
    if (totalScans >= 20) {
      reliability = 'Very Reliable';
    } else if (totalScans >= 10) {
      reliability = 'Reliable';
    } else if (totalScans >= 5) {
      reliability = 'Moderate';
    } else {
      reliability = 'Limited Data';
    }

    return CrowdInsight(
      bssid: bssid,
      ssid: ssid,
      averageSignal: data['avg_signal'] as double,
      totalScans: totalScans,
      locationCount: data['locations'] as int,
      lastSeen: data['last_seen'] as DateTime,
      reliabilityLabel: reliability,
    );
  }
}
