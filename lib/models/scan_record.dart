/// ==========================================================================
/// Scan Record Model — Represents a complete WiFi scan snapshot.
///
/// Each time the user (or auto-scan) performs a scan, the results are saved
/// as a ScanRecord. This includes the timestamp, GPS coordinates, and all
/// the networks that were discovered during that scan.
/// ==========================================================================

/// A single network entry within a scan record (for database storage).
/// Unlike [WifiNetworkModel], this is a plain data class without the
/// underlying [WiFiAccessPoint] dependency, making it easy to serialize.
class NetworkEntry {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final int frequency;
  final int channel;
  final String securityType;
  final int qualityScore;

  NetworkEntry({
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    required this.frequency,
    required this.channel,
    required this.securityType,
    required this.qualityScore,
  });

  /// Create from a database row map.
  factory NetworkEntry.fromMap(Map<String, dynamic> map) {
    return NetworkEntry(
      ssid: map['ssid'] as String,
      bssid: map['bssid'] as String,
      signalStrength: map['signal_strength'] as int,
      frequency: map['frequency'] as int,
      channel: map['channel'] as int,
      securityType: map['security_type'] as String,
      qualityScore: map['quality_score'] as int,
    );
  }

  /// Convert to a map for database insertion.
  Map<String, dynamic> toMap(int scanId) {
    return {
      'scan_id': scanId,
      'ssid': ssid,
      'bssid': bssid,
      'signal_strength': signalStrength,
      'frequency': frequency,
      'channel': channel,
      'security_type': securityType,
      'quality_score': qualityScore,
    };
  }
}

/// A complete scan record, containing metadata and all discovered networks.
class ScanRecord {
  final int? id;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? carrierName;
  final String? networkGeneration;
  final List<NetworkEntry> networks;

  ScanRecord({
    this.id,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.carrierName,
    this.networkGeneration,
    required this.networks,
  });

  /// The number of networks found in this scan.
  int get networkCount => networks.length;

  /// The best quality score among all networks in this scan.
  int get bestScore =>
      networks.isEmpty ? 0 : networks.map((n) => n.qualityScore).reduce((a, b) => a > b ? a : b);

  /// Create from database row + associated network entries.
  factory ScanRecord.fromMap(Map<String, dynamic> map, List<NetworkEntry> networks) {
    return ScanRecord(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      carrierName: map['carrier_name'] as String?,
      networkGeneration: map['network_generation'] as String?,
      networks: networks,
    );
  }

  /// Convert scan metadata to a map (networks are stored in a separate table).
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'carrier_name': carrierName,
      'network_generation': networkGeneration,
      'network_count': networkCount,
      'best_score': bestScore,
    };
  }
}
