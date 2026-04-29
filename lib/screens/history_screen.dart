import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/scan_record.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();
  List<ScanRecord> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _db.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('SCAN HISTORY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgDark, Color(0xFF1A1F35), AppTheme.bgDark],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _history.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 16),
                        Text('No scan history yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                        Text('Scans are saved automatically', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _history.length,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemBuilder: (context, index) {
                      final scan = _history[index];
                      return Dismissible(
                        key: Key(scan.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          if (scan.id != null) await _db.deleteScan(scan.id!);
                          setState(() => _history.removeAt(index));
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${scan.bestScore}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                ),
                              ),
                            ),
                            title: Text('${scan.networkCount} networks found', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Text(
                              '${_formatDate(scan.timestamp)}${scan.latitude != null ? " • 📍 GPS" : ""}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                            onTap: () => _showScanDetail(scan),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _showScanDetail(ScanRecord scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, controller) => Column(
          children: [
            Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.list_alt_rounded, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'SCAN DETAILS — ${_formatDate(scan.timestamp)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: scan.networks.length,
                itemBuilder: (ctx, i) {
                  final n = scan.networks[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        n.qualityScore >= 60 ? Icons.wifi_rounded : Icons.wifi_1_bar_rounded,
                        color: n.qualityScore >= 60 ? AppTheme.primary : AppTheme.warning,
                      ),
                      title: Text(n.ssid, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${n.signalStrength} dBm • CH ${n.channel} • ${n.securityType}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      trailing: Text(
                        '${n.qualityScore}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime t) => '${t.day}/${t.month}/${t.year} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
}

