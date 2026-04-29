import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});
  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final DatabaseService _db = DatabaseService();
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _heatData = [];
  LatLng? _currentPos;
  String _selectedCarrier = 'All';
  final List<String> _carriers = ['All', 'Jio', 'Airtel', 'Vi India', 'BSNL Mobile'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _currentPos = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      _currentPos = const LatLng(20.5937, 78.9629); // Default: India center
    }
    final data = await _db.getHeatmapData(carrierName: _selectedCarrier);
    if (mounted) setState(() => _heatData = data);
  }

  void _onCarrierChanged(String carrier) {
    setState(() {
      _selectedCarrier = carrier;
      _heatData = []; // Clear current data while loading
    });
    _loadData();
  }

  Color _signalToColor(double qualityScore) {
    if (qualityScore >= 80) return AppTheme.success.withOpacity(0.6);
    if (qualityScore >= 60) return AppTheme.primary.withOpacity(0.6);
    if (qualityScore >= 40) return AppTheme.warning.withOpacity(0.6);
    return AppTheme.danger.withOpacity(0.6);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPos == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _currentPos!, initialZoom: 16),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.wifiscanner.wifi_scanner',
            ),
            CircleLayer(circles: [
              // Current location marker
              CircleMarker(
                point: _currentPos!,
                radius: 10,
                color: AppTheme.primary.withOpacity(0.8),
                borderColor: Colors.white,
                borderStrokeWidth: 2,
              ),
              // Heatmap data points
              ..._heatData.map((d) {
                final lat = d['grid_lat'] as double;
                final lon = d['grid_lon'] as double;
                final signal = d['signal'] as double;
                return CircleMarker(
                  point: LatLng(lat, lon),
                  radius: 20,
                  color: _signalToColor(signal),
                  borderColor: Colors.white.withOpacity(0.3),
                  borderStrokeWidth: 1,
                );
              }),
            ]),
          ],
        ),
        // Legend
        Positioned(
          bottom: 24,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgDark.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('QUALITY SCORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primary, letterSpacing: 1)),
                const SizedBox(height: 12),
                _LegendItem(color: AppTheme.success, label: 'Excellent (> 80)'),
                _LegendItem(color: AppTheme.primary, label: 'Good (60 - 80)'),
                _LegendItem(color: AppTheme.warning, label: 'Fair (40 - 60)'),
                _LegendItem(color: AppTheme.danger, label: 'Poor (< 40)'),
                const SizedBox(height: 8),
                Text('${_heatData.length} data points detected', style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
        // Recenter button
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              if (_currentPos != null) _mapController.move(_currentPos!, 16);
            },
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.my_location),
          ),
        ),
        // Carrier Filter Tabs
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _carriers.map((c) {
                final isSelected = c == _selectedCarrier;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _onCarrierChanged(c),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.bgCard.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.borderColor,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textPrimary)),
          ],
        ),
      );
}

