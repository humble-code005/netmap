/// ==========================================================================
/// WiFi Network Model — Data class representing a single WiFi access point.
///
/// This model wraps the raw [WiFiAccessPoint] data from the wifi_scan package
/// and adds computed properties like quality score, channel number, and
/// security type. It also includes serialization methods for database storage.
/// ==========================================================================
import 'package:wifi_scan/wifi_scan.dart';

/// Quality categories for visual indicators throughout the app.
/// Each network is classified into one of these based on its quality score.
enum SignalQuality { excellent, good, fair, poor }

class WifiNetworkModel {
  final WiFiAccessPoint accessPoint;

  WifiNetworkModel(this.accessPoint);

  // --- Basic Properties ---

  /// Returns the SSID (network name). Shows 'Hidden Network' if SSID is empty,
  /// which happens when a router has SSID broadcasting disabled.
  String get ssid =>
      accessPoint.ssid.isNotEmpty ? accessPoint.ssid : 'Hidden Network';

  /// The BSSID is the MAC address of the access point — always unique.
  String get bssid => accessPoint.bssid;

  /// RSSI (Received Signal Strength Indicator) in dBm.
  /// Typical range: -100 (very weak) to -30 (very strong).
  int get signalStrength => accessPoint.level;

  /// The radio frequency in MHz (e.g., 2437 for channel 6 on 2.4GHz).
  int get frequency => accessPoint.frequency;

  // --- Computed Properties ---

  /// Derives the WiFi channel number from the frequency.
  /// 2.4GHz channels: 1-14 (spaced 5 MHz apart, starting at 2412 MHz).
  /// 5GHz channels: 36-165 (spaced 5 MHz apart, starting at 5180 MHz).
  int get channel {
    if (is24GHz) {
      // Channel 1 = 2412 MHz, each channel is +5 MHz
      if (frequency == 2484) return 14; // Special case: channel 14
      return ((frequency - 2412) / 5 + 1).round();
    } else if (is5GHz) {
      // 5GHz channels start at 5180 MHz (channel 36)
      return ((frequency - 5000) / 5).round();
    }
    return 0; // Unknown frequency band
  }

  /// Determines the security type from the access point's capabilities string.
  /// The capabilities string contains authentication methods like [WPA2-PSK],
  /// [WPA3-SAE], [ESS], [WEP], etc.
  String get securityType {
    final caps = accessPoint.capabilities ?? '';
    if (caps.contains('WPA3')) return 'WPA3';
    if (caps.contains('WPA2')) return 'WPA2';
    if (caps.contains('WPA')) return 'WPA';
    if (caps.contains('WEP')) return 'WEP';
    if (caps.contains('ESS') && !caps.contains('WPA') && !caps.contains('WEP')) {
      return 'Open'; // No encryption — insecure!
    }
    return 'Unknown';
  }

  /// Returns true if the network has no encryption (security risk).
  bool get isOpen => securityType == 'Open';

  // --- Quality Scoring ---

  /// Calculates a 0-100 quality score based on signal strength.
  /// RSSI is typically -100 (weakest) to -30 (strongest).
  /// A bonus is added for 5GHz networks since they offer better throughput
  /// when the signal is strong enough (> -70 dBm).
  int get qualityScore {
    int level = accessPoint.level;
    if (level <= -100) return 0;
    if (level >= -30) return 100;

    // Linear normalization: map -100..-30 to 0..140, then clamp to 0..100
    int score = 2 * (level + 100);

    // 5GHz bonus: these networks are less congested and offer higher speeds,
    // but only if the signal is strong enough to be useful
    if (is5GHz && level > -70) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  /// Categorizes the quality score into human-readable buckets.
  SignalQuality get qualityCategory {
    final score = qualityScore;
    if (score >= 80) return SignalQuality.excellent;
    if (score >= 60) return SignalQuality.good;
    if (score >= 40) return SignalQuality.fair;
    return SignalQuality.poor;
  }

  /// Returns a human-readable label for the quality category.
  String get qualityLabel {
    switch (qualityCategory) {
      case SignalQuality.excellent:
        return 'Excellent';
      case SignalQuality.good:
        return 'Good';
      case SignalQuality.fair:
        return 'Fair';
      case SignalQuality.poor:
        return 'Poor';
    }
  }

  // --- Frequency Band Helpers ---

  bool get is5GHz => frequency >= 5000 && frequency < 6000;
  bool get is24GHz => frequency >= 2400 && frequency < 2500;

  String get bandLabel => is5GHz ? '5 GHz' : '2.4 GHz';

  // --- Database Serialization ---

  /// Converts this model to a Map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'ssid': ssid,
      'bssid': bssid,
      'signal_strength': signalStrength,
      'frequency': frequency,
      'channel': channel,
      'security_type': securityType,
      'quality_score': qualityScore,
      'capabilities': accessPoint.capabilities ?? '',
    };
  }
}
