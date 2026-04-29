import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/wifi_network_model.dart';
import '../models/scan_record.dart';
import '../services/scanner_service.dart';
import '../services/database_service.dart';
import '../services/mobile_network_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../widgets/network_list_tile.dart';
import '../widgets/pro_widgets.dart';
import '../theme/app_theme.dart';
import 'network_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final ScannerService _scannerService = ScannerService();
  final DatabaseService _dbService = DatabaseService();
  final MobileNetworkService _mobileService = MobileNetworkService();
  late final NotificationService _notificationService;

  MobileNetworkData? _currentMobileNetwork;

  List<WifiNetworkModel> _networks = [];
  List<WifiNetworkModel> _scanHistory = [];
  StreamSubscription? _subscription;
  Timer? _scanTimer;
  bool _isScanning = false;
  String _statusMessage = 'Initializing...';
  int _tabIndex = 0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(
      onNewNetwork: (ssid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🆕 New network detected: $ssid'),
              backgroundColor: AppTheme.primaryDark,
            ),
          );
        }
      },
      onSignalAlert: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      },
    );
    _initializeScan();
  }

  Future<void> _initializeScan() async {
    bool hasPermissions = await _scannerService.requestPermissions();
    if (hasPermissions) {
      _startScanning();
    } else {
      setState(() {
        _statusMessage = 'Location permissions required for WiFi scanning.';
      });
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for networks...';
    });

    _subscription = _scannerService.onScannedResults.listen((results) {
      if (mounted) {
        setState(() {
          _networks = results;
          if (_networks.isNotEmpty) {
            _scanHistory.insert(0, _networks.first);
            if (_scanHistory.length > 20) _scanHistory.removeLast();
          }
          if (_networks.isEmpty) {
            _statusMessage = 'No networks found.';
          }
        });
        _notificationService.processNetworks(results);
        _saveScanToDatabase(results);
      }
    });

    _triggerScan();
    _scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _isScanning) {
        _triggerScan();
      }
    });
  }

  Future<void> _triggerScan() async {
    await _scannerService.startScan();
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 3));
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}

    // Fetch live mobile network
    final mobileNet = await _mobileService.getCarrierInfo();
    if (mounted) setState(() => _currentMobileNetwork = mobileNet);
  }

  Future<void> _saveScanToDatabase(List<WifiNetworkModel> networks) async {
    final record = ScanRecord(
      timestamp: DateTime.now(),
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      carrierName: _currentMobileNetwork?.carrierName,
      networkGeneration: _currentMobileNetwork?.networkGeneration,
      networks: networks.map((n) => NetworkEntry(
        ssid: n.ssid,
        bssid: n.bssid,
        signalStrength: n.signalStrength,
        frequency: n.frequency,
        channel: n.channel,
        securityType: n.securityType,
        qualityScore: n.qualityScore,
      )).toList(),
    );
    await _dbService.saveScan(record);
  }

  String _detectCircle() {
    return LocationService.detectTelecomCircle(_currentPosition);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scanTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgDark, Color(0xFF1A1F35), AppTheme.bgDark],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _triggerScan,
          color: AppTheme.primary,
          backgroundColor: AppTheme.bgCard,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const ProHeader(),
                _buildTopSection(),
                _buildMetricsGrid(),
                _buildCircleInfo(),
                _buildTabs(),
                const SizedBox(height: 20),
                _buildTabContent(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    final best = _networks.isNotEmpty ? _networks.first : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: ProGlassCard(
            child: ProScoreCircle(
              score: best?.qualityScore ?? 0,
              status: _isScanning ? 'Scanning...' : 'Ready',
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: ProGlassCard(
            title: 'Scanner Controls',
            icon: Icons.settings,
            child: Column(
              children: [
                _buildButton(
                  icon: Icons.search,
                  label: 'SCAN NOW',
                  onPressed: _triggerScan,
                  primary: true,
                ),
                const SizedBox(height: 12),
                _buildButton(
                  icon: _isScanning ? Icons.pause : Icons.play_arrow,
                  label: _isScanning ? 'STOP AUTO' : 'AUTO-SCAN',
                  onPressed: () => setState(() => _isScanning = !_isScanning),
                ),
                const SizedBox(height: 12),
                _buildButton(
                  icon: Icons.delete_outline,
                  label: 'CLEAR DATA',
                  onPressed: () => setState(() {
                    _networks = [];
                    _scanHistory = [];
                  }),
                  danger: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool primary = false,
    bool danger = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary
              ? AppTheme.primary
              : danger
                  ? AppTheme.danger.withOpacity(0.2)
                  : AppTheme.primary.withOpacity(0.1),
          foregroundColor: primary ? Colors.black : (danger ? AppTheme.danger : AppTheme.primary),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: primary ? Colors.transparent : (danger ? AppTheme.danger : AppTheme.primary),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ProMetricCard(
                label: 'Carrier',
                value: _currentMobileNetwork?.carrierName ?? 'Searching...',
                icon: Icons.cell_tower,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProMetricCard(
                label: 'Network',
                value: _currentMobileNetwork?.networkGeneration ?? '-',
                icon: Icons.network_cell,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ProMetricCard(
                label: 'Networks',
                value: '${_networks.length}',
                icon: Icons.router,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleInfo() {
    return ProGlassCard(
      title: 'Detected Circle',
      icon: Icons.location_city,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _detectCircle(),
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  _currentPosition != null
                      ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                      : 'GPS signal pending...',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 2)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Overview', Icons.dashboard),
          _buildTabItem(1, 'Networks', Icons.wifi_find),
          _buildTabItem(2, 'Logs', Icons.history),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final active = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? AppTheme.primary : AppTheme.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildNetworksList();
      case 2:
        return _buildLogsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab() {
    if (_networks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(_statusMessage, style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performance Network',
          style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        NetworkListTile(
          network: _networks.first,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NetworkDetailScreen(network: _networks.first)),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworksList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _networks.length,
      itemBuilder: (context, index) {
        return NetworkListTile(
          network: _networks[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NetworkDetailScreen(network: _networks[index])),
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    if (_scanHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Text('No scan logs available', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return Column(
      children: _scanHistory.map((n) {
        return ProLogEntry(
          time: '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}',
          score: n.qualityScore,
          details: '${n.ssid} | ${n.signalStrength}dBm | ${n.bandLabel}',
        );
      }).toList(),
    );
  }
}

