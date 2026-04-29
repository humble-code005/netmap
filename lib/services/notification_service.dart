/// ==========================================================================
/// Notification Service — Monitors signal strength and alerts the user.
///
/// Features:
///   - Alert when connected WiFi drops below "Fair" quality
///   - Alert when a new (previously unseen) network SSID appears
///   - Tracks known SSIDs to detect new ones
/// ==========================================================================
import '../models/wifi_network_model.dart';

class NotificationService {
  /// Set of all SSIDs we've ever seen — used to detect new networks.
  final Set<String> _knownSSIDs = {};

  /// The last quality category of the connected network.
  SignalQuality? _lastQuality;

  /// Callback when signal drops below threshold.
  final void Function(String message)? onSignalAlert;

  /// Callback when a new network is detected.
  final void Function(String ssid)? onNewNetwork;

  NotificationService({this.onSignalAlert, this.onNewNetwork});

  /// Process a list of scanned networks and check for alerts.
  void processNetworks(List<WifiNetworkModel> networks) {
    // Check for new SSIDs
    for (final network in networks) {
      if (network.ssid != 'Hidden Network' && !_knownSSIDs.contains(network.ssid)) {
        // Only alert after the first scan (so we don't flood on startup)
        if (_knownSSIDs.isNotEmpty) {
          onNewNetwork?.call(network.ssid);
        }
        _knownSSIDs.add(network.ssid);
      }
    }
  }

  /// Check if the connected network's signal has dropped.
  /// Call this with the currently connected network's quality.
  void checkSignalDrop(SignalQuality currentQuality) {
    if (_lastQuality != null) {
      // Alert if quality dropped to Poor from something better
      if (currentQuality == SignalQuality.poor &&
          _lastQuality != SignalQuality.poor) {
        onSignalAlert?.call('⚠️ WiFi signal has dropped to Poor quality!');
      }
    }
    _lastQuality = currentQuality;
  }
}
