import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../models/wifi_network_model.dart';

class ScannerService {
  // Request necessary permissions for WiFi scanning
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    final statusLocation = await Permission.location.request();
    return statusLocation.isGranted;
  }

  // Start a WiFi scan
  Future<bool> startScan() async {
    if (kIsWeb) return false;
    
    try {
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        return false;
      }
      final result = await WiFiScan.instance.startScan();
      return result;
    } catch (_) {
      return false;
    }
  }

  // Get scan results as a stream
  Stream<List<WifiNetworkModel>> get onScannedResults {
    if (kIsWeb) return const Stream.empty();
    
    return WiFiScan.instance.onScannedResultsAvailable.asyncMap((event) async {
      try {
        final canGet = await WiFiScan.instance.canGetScannedResults();
        if (canGet != CanGetScannedResults.yes) {
          return <WifiNetworkModel>[];
        }
        final results = await WiFiScan.instance.getScannedResults();
        
        // Convert to models and sort by quality score descending
        var models = results.map((ap) => WifiNetworkModel(ap)).toList();
        models.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
        
        return models;
      } catch (_) {
        return <WifiNetworkModel>[];
      }
    });
  }
}
