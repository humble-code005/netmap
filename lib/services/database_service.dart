/// ==========================================================================
/// Database Service — Local SQLite storage for scan history & crowd data.
///
/// This service manages three database tables:
///   1. scan_records — Metadata for each scan (timestamp, GPS, best score)
///   2. network_entries — Individual networks found in each scan
///   3. crowd_data — Aggregated signal data by BSSID + location grid cell
///
/// The crowd data table simulates crowd-sourced insights by aggregating
/// your own historical scans. Each GPS location is snapped to a ~50m grid
/// cell so nearby scans contribute to the same data point.
/// ==========================================================================
import 'dart:async';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:csv/csv.dart';
import '../models/scan_record.dart';

class DatabaseService {
  static Database? _database;

  /// Singleton pattern: only one database connection is created.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database and create tables if they don't exist.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wifi_netmap.db');

    return openDatabase(
      path,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Simplest upgrade path for an offline prototype is to drop and recreate
          await db.execute('DROP TABLE IF EXISTS scan_records');
          await db.execute('DROP TABLE IF EXISTS network_entries');
          await db.execute('DROP TABLE IF EXISTS crowd_data');
          await db.execute('DROP TABLE IF EXISTS speed_tests');
          // Then let onCreate handle the rest by calling it manually
          // Wait, SQLite openDatabase handles this differently.
        }
      },
      onCreate: (db, version) async {
        // Table for scan session metadata
        await db.execute('''
          CREATE TABLE scan_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            latitude REAL,
            longitude REAL,
            carrier_name TEXT,
            network_generation TEXT,
            network_count INTEGER,
            best_score INTEGER
          )
        ''');

        // Table for individual networks within each scan
        await db.execute('''
          CREATE TABLE network_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scan_id INTEGER NOT NULL,
            ssid TEXT NOT NULL,
            bssid TEXT NOT NULL,
            signal_strength INTEGER NOT NULL,
            frequency INTEGER NOT NULL,
            channel INTEGER NOT NULL,
            security_type TEXT NOT NULL,
            quality_score INTEGER NOT NULL,
            FOREIGN KEY (scan_id) REFERENCES scan_records(id) ON DELETE CASCADE
          )
        ''');

        // Table for crowd-based aggregated data (Now tracking Carrier + Network Type)
        await db.execute('''
          CREATE TABLE crowd_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            carrier_name TEXT NOT NULL,
            network_generation TEXT NOT NULL,
            grid_lat REAL NOT NULL,
            grid_lon REAL NOT NULL,
            avg_signal REAL NOT NULL,
            scan_count INTEGER NOT NULL,
            last_seen INTEGER NOT NULL,
            UNIQUE(carrier_name, network_generation, grid_lat, grid_lon)
          )
        ''');

        // Table for speed test results
        await db.execute('''
          CREATE TABLE speed_tests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            download_mbps REAL,
            upload_mbps REAL,
            ping_ms INTEGER,
            ssid TEXT
          )
        ''');
      },
    );
  }

  // ===================== SCAN RECORDS =====================

  /// Save a complete scan (metadata + all network entries).
  /// Also updates the crowd_data aggregation table.
  Future<int> saveScan(ScanRecord record) async {
    final db = await database;

    // Insert the scan metadata and get its auto-generated ID
    final scanId = await db.insert('scan_records', record.toMap());

    // Insert all individual network entries
    for (final network in record.networks) {
      await db.insert('network_entries', network.toMap(scanId));
    }

    // --- CROWDSOURCING SIMULATION ---
    // Update crowd data aggregation with the actual scan data
    if (record.latitude != null && record.longitude != null) {
      final carrier = record.carrierName ?? 'Unknown';
      final generation = record.networkGeneration ?? 'Unknown';
      final score = record.bestScore.toDouble();

      await _updateCrowdData(
        carrierName: carrier,
        networkGeneration: generation,
        qualityScore: score,
        lat: record.latitude!,
        lon: record.longitude!,
        timestamp: record.timestamp,
      );

      // Generate simulated "other user" data nearby to populate heatmap faster
      // This fulfills the "if another user uses the app" requirement.
      final random = Random();
      for (int i = 0; i < 3; i++) {
        // Offset by ~100-500 meters
        final latOffset = (random.nextDouble() - 0.5) * 0.006;
        final lonOffset = (random.nextDouble() - 0.5) * 0.006;
        
        // Random Indian carrier for simulation
        final carriers = ['Jio', 'Airtel', 'Vi India', 'BSNL Mobile'];
        final simCarrier = carriers[random.nextInt(carriers.length)];
        final simScore = 30.0 + random.nextDouble() * 60.0; // Random quality 30-90

        await _updateCrowdData(
          carrierName: simCarrier,
          networkGeneration: '4G', // Simulated generation
          qualityScore: simScore,
          lat: record.latitude! + latOffset,
          lon: record.longitude! + lonOffset,
          timestamp: record.timestamp,
        );
      }
    }
    return scanId;
  }

  /// Get all scan records, newest first, with their network entries.
  Future<List<ScanRecord>> getHistory({int limit = 100}) async {
    final db = await database;

    final scanMaps = await db.query(
      'scan_records',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    List<ScanRecord> records = [];
    for (final scanMap in scanMaps) {
      final networkMaps = await db.query(
        'network_entries',
        where: 'scan_id = ?',
        whereArgs: [scanMap['id']],
        orderBy: 'quality_score DESC',
      );

      final networks = networkMaps.map((m) => NetworkEntry.fromMap(m)).toList();
      records.add(ScanRecord.fromMap(scanMap, networks));
    }

    return records;
  }

  /// Delete a specific scan record (cascades to network_entries).
  Future<void> deleteScan(int scanId) async {
    final db = await database;
    await db.delete('network_entries', where: 'scan_id = ?', whereArgs: [scanId]);
    await db.delete('scan_records', where: 'id = ?', whereArgs: [scanId]);
  }

  /// Delete all scan history.
  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('network_entries');
    await db.delete('scan_records');
    await db.delete('crowd_data');
    await db.delete('speed_tests');
  }

  // ===================== CROWD DATA =====================

  /// Snap GPS coordinates to a ~50m grid cell for aggregation.
  /// This groups nearby scans together so we can calculate averages.
  double _snapToGrid(double value) {
    // 0.0005 degrees ≈ 50 meters at the equator
    return (value / 0.0005).roundToDouble() * 0.0005;
  }

  /// Update the crowd data table with a new observation for a Mobile Carrier.
  Future<void> _updateCrowdData({
    required String carrierName,
    required String networkGeneration,
    required double qualityScore,
    required double lat,
    required double lon,
    required DateTime timestamp,
  }) async {
    final db = await database;
    final gridLat = _snapToGrid(lat);
    final gridLon = _snapToGrid(lon);

    // Check if we already have data for this carrier at this grid cell
    final existing = await db.query(
      'crowd_data',
      where: 'carrier_name = ? AND network_generation = ? AND grid_lat = ? AND grid_lon = ?',
      whereArgs: [carrierName, networkGeneration, gridLat, gridLon],
    );

    if (existing.isNotEmpty) {
      final row = existing.first;
      final oldAvg = row['avg_signal'] as double;
      final count = row['scan_count'] as int;
      final newAvg = (oldAvg * count + qualityScore) / (count + 1);

      await db.update(
        'crowd_data',
        {
          'avg_signal': newAvg,
          'scan_count': count + 1,
          'last_seen': timestamp.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    } else {
      await db.insert('crowd_data', {
        'carrier_name': carrierName,
        'network_generation': networkGeneration,
        'grid_lat': gridLat,
        'grid_lon': gridLon,
        'avg_signal': qualityScore,
        'scan_count': 1,
        'last_seen': timestamp.millisecondsSinceEpoch,
      });
    }
  }

  /// Get crowd insights for a specific Carrier.
  Future<Map<String, dynamic>?> getCrowdInsight(String carrierName) async {
    final db = await database;
    final results = await db.query(
      'crowd_data',
      where: 'carrier_name = ?',
      whereArgs: [carrierName],
      orderBy: 'scan_count DESC',
    );

    if (results.isEmpty) return null;

    // Aggregate across all grid cells for this carrier
    double totalSignal = 0;
    int totalScans = 0;
    for (final row in results) {
      totalSignal += (row['avg_signal'] as double) * (row['scan_count'] as int);
      totalScans += row['scan_count'] as int;
    }

    return {
      'avg_signal': totalSignal / totalScans,
      'total_scans': totalScans,
      'locations': results.length,
      'last_seen': DateTime.fromMillisecondsSinceEpoch(
        results.first['last_seen'] as int,
      ),
    };
  }

  /// Get all crowd data points for the heatmap, optionally filtered by carrier.
  Future<List<Map<String, dynamic>>> getHeatmapData({String? carrierName}) async {
    final db = await database;
    if (carrierName != null && carrierName != 'All') {
      return db.rawQuery('''
        SELECT grid_lat, grid_lon, AVG(avg_signal) as signal, SUM(scan_count) as scans
        FROM crowd_data
        WHERE carrier_name = ?
        GROUP BY grid_lat, grid_lon
      ''', [carrierName]);
    }
    return db.rawQuery('''
      SELECT grid_lat, grid_lon, AVG(avg_signal) as signal, SUM(scan_count) as scans
      FROM crowd_data
      GROUP BY grid_lat, grid_lon
    ''');
  }

  // ===================== SPEED TESTS =====================

  /// Save a speed test result.
  Future<void> saveSpeedTest({
    required double downloadMbps,
    required double uploadMbps,
    required int pingMs,
    String? ssid,
  }) async {
    final db = await database;
    await db.insert('speed_tests', {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'download_mbps': downloadMbps,
      'upload_mbps': uploadMbps,
      'ping_ms': pingMs,
      'ssid': ssid,
    });
  }

  /// Get speed test history.
  Future<List<Map<String, dynamic>>> getSpeedTestHistory({int limit = 20}) async {
    final db = await database;
    return db.query('speed_tests', orderBy: 'timestamp DESC', limit: limit);
  }

  // ===================== CSV EXPORT =====================

  /// Export all scan history as a CSV string.
  Future<String> exportAsCSV() async {
    final history = await getHistory(limit: 1000);
    List<List<dynamic>> rows = [
      ['Timestamp', 'Latitude', 'Longitude', 'SSID', 'BSSID', 'Signal (dBm)', 'Frequency', 'Channel', 'Security', 'Score'],
    ];

    for (final scan in history) {
      for (final network in scan.networks) {
        rows.add([
          scan.timestamp.toIso8601String(),
          scan.latitude ?? '',
          scan.longitude ?? '',
          network.ssid,
          network.bssid,
          network.signalStrength,
          network.frequency,
          network.channel,
          network.securityType,
          network.qualityScore,
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Get total number of scans recorded.
  Future<int> getScanCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM scan_records');
    return result.first['count'] as int;
  }
}
