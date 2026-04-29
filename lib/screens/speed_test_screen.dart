import 'package:flutter/material.dart';
import '../services/speed_test_service.dart';
import '../services/database_service.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/pro_widgets.dart';
import '../theme/app_theme.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});
  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  final DatabaseService _db = DatabaseService();
  String _phase = 'idle';
  double _download = 0, _upload = 0, _currentSpeed = 0;
  int _ping = 0;
  bool _testing = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await _db.getSpeedTestHistory();
    if (mounted) setState(() => _history = h);
  }

  Future<void> _runTest() async {
    setState(() {
      _testing = true;
      _phase = 'ping';
      _download = 0;
      _upload = 0;
      _currentSpeed = 0;
      _ping = 0;
    });
    final service = SpeedTestService(onProgress: (phase, progress, currentSpeed) {
      if (mounted) {
        setState(() {
          _phase = phase;
          if (phase == 'download') _download = currentSpeed;
          if (phase == 'upload') _upload = currentSpeed;
          _currentSpeed = currentSpeed;
        });
      }
    });
    try {
      final result = await service.runFullTest();
      setState(() {
        _download = result.downloadMbps;
        _upload = result.uploadMbps;
        _ping = result.pingMs;
        _currentSpeed = 0; // reset dial
        _phase = 'done';
        _testing = false;
      });
      await _db.saveSpeedTest(downloadMbps: result.downloadMbps, uploadMbps: result.uploadMbps, pingMs: result.pingMs);
      _loadHistory();
    } catch (e) {
      setState(() {
        _phase = 'error';
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.bgDark, Color(0xFF1A1F35), AppTheme.bgDark],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          ProGlassCard(
            child: Column(
              children: [
                Center(
                  child: SpeedGauge(
                    value: _phase == 'download' || _phase == 'upload' ? _currentSpeed : 0,
                    label: _getPhaseLabel(),
                    color: _phase == 'upload' ? AppTheme.info : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ResultCard(
                        icon: Icons.download_rounded,
                        label: 'Download',
                        value: '${_download.toStringAsFixed(1)}',
                        unit: 'Mbps',
                        color: AppTheme.primary),
                    _ResultCard(
                        icon: Icons.upload_rounded,
                        label: 'Upload',
                        value: '${_upload.toStringAsFixed(1)}',
                        unit: 'Mbps',
                        color: AppTheme.info),
                    _ResultCard(
                        icon: Icons.timer_outlined,
                        label: 'Ping',
                        value: '$_ping',
                        unit: 'ms',
                        color: AppTheme.warning),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _testing ? null : _runTest,
              icon: _testing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.speed),
              label: Text(_testing ? 'TESTING...' : 'START SPEED TEST', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_history.isNotEmpty) ...[
            const Text(
              'RECENT TESTS',
              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            ..._history.take(5).map((h) {
              final time = DateTime.fromMillisecondsSinceEpoch(h['timestamp'] as int);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '↓ ${(h['download_mbps'] as double).toStringAsFixed(1)} / ↑ ${(h['upload_mbps'] as double).toStringAsFixed(1)} Mbps',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Ping: ${h['ping_ms']} ms • ${_formatTime(time)}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getPhaseLabel() {
    switch (_phase) {
      case 'ping':
        return 'MEASURING PING...';
      case 'download':
        return 'DOWNLOADING...';
      case 'upload':
        return 'UPLOADING...';
      case 'done':
        return 'COMPLETE';
      case 'error':
        return 'ERROR';
      default:
        return 'READY';
    }
  }

  String _formatTime(DateTime t) => '${t.day}/${t.month} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final Color color;
  const _ResultCard({required this.icon, required this.label, required this.value, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimary)),
              const SizedBox(width: 2),
              Text(unit, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        ],
      );
}

