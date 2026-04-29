import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:carrier_info/carrier_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class MobileNetworkData {
  final String carrierName;
  final String networkGeneration;

  MobileNetworkData({
    required this.carrierName,
    required this.networkGeneration,
  });
}

class MobileNetworkService {
  /// Fetches the current mobile carrier info.
  /// Falls back to mock data on Web or if permissions fail.
  Future<MobileNetworkData> getCarrierInfo() async {
    // Check connectivity first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      final wifiSsid = await NetworkInfo().getWifiName();
      return MobileNetworkData(
        carrierName: wifiSsid != null ? 'WiFi: ${wifiSsid.replaceAll('"', '')}' : 'WiFi Connected',
        networkGeneration: 'Broadband',
      );
    }

    // Web doesn't support carrier info plugins
    if (kIsWeb) {
      return _getMockData();
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Request permissions
        if (Platform.isAndroid) {
          await Permission.phone.request();
        }
        
        final mobileInfo = await _getRealMobileInfo();
        if (mobileInfo != null) return mobileInfo;
      }
      
      return _getMockData();
    } catch (e) {
      debugPrint('Error fetching carrier info: $e');
      return _getMockData();
    }
  }

  Future<MobileNetworkData?> _getRealMobileInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await CarrierInfo.getAndroidInfo();
        if (androidInfo != null && androidInfo.telephonyInfo.isNotEmpty) {
          final sim = androidInfo.telephonyInfo.first;
          return MobileNetworkData(
            carrierName: sim.carrierName.isNotEmpty ? sim.carrierName : sim.networkOperatorName,
            networkGeneration: sim.networkGeneration.isNotEmpty ? sim.networkGeneration : '4G',
          );
        }
      } else if (Platform.isIOS) {
        final iosInfo = await CarrierInfo.getIosInfo();
        if (iosInfo != null && iosInfo.carrierData.isNotEmpty) {
          final sim = iosInfo.carrierData.first;
          return MobileNetworkData(
            carrierName: sim.carrierName ?? 'Unknown',
            networkGeneration: '4G', // iOS doesn't expose radio type easily
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Maps technical network types to consumer-friendly generations.
  String _mapNetworkTypeToGeneration(String? type) {
    if (type == null) return 'Unknown';
    final t = type.toUpperCase();
    if (t.contains('NR') || t.contains('5G')) return '5G';
    if (t.contains('LTE') || t.contains('4G')) return '4G';
    if (t.contains('HSPA') || t.contains('3G')) return '3G';
    if (t.contains('EDGE') || t.contains('GPRS') || t.contains('2G')) return '2G';
    return '4G'; // Fallback for most modern networks
  }

  /// Mock data for Web / Simulators to allow UI testing.
  MobileNetworkData _getMockData() {
    // Cycle through Indian carriers based on time for demo purposes
    final second = DateTime.now().second;
    if (second < 15) {
      return MobileNetworkData(carrierName: 'Jio', networkGeneration: '5G');
    } else if (second < 30) {
      return MobileNetworkData(carrierName: 'Airtel', networkGeneration: '4G');
    } else if (second < 45) {
      return MobileNetworkData(carrierName: 'Vi India', networkGeneration: '4G');
    } else {
      return MobileNetworkData(carrierName: 'BSNL Mobile', networkGeneration: '3G');
    }
  }
}
