/// ==========================================================================
/// Speed Test Service — Measures download speed, upload speed, and ping.
///
/// Upgraded to "Ookla style" multi-threaded bandwidth saturation.
/// Uses multiple concurrent connections and streams data for a fixed duration
/// to accurately measure true maximum throughput.
/// ==========================================================================
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SpeedTestResult {
  final double downloadMbps;
  final double uploadMbps;
  final int pingMs;

  SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.pingMs,
  });
}

class SpeedTestService {
  // Cloudflare speed test endpoints
  static const String _downloadUrl = 'https://speed.cloudflare.com/__down?bytes=25000000'; // 25MB chunks
  static const String _uploadUrl = 'https://speed.cloudflare.com/__up';
  static const String _pingUrl = 'https://www.cloudflare.com/cdn-cgi/trace';

  final int concurrentConnections = 4;
  final Duration testDuration = const Duration(seconds: 5);

  /// Callback for progress updates.
  /// phase: 'ping', 'download', 'upload'
  /// progress: 0.0 to 1.0
  /// currentSpeed: Current Mbps (for live UI dial)
  final void Function(String phase, double progress, double currentSpeed)? onProgress;

  SpeedTestService({this.onProgress});

  Future<SpeedTestResult> runFullTest() async {
    onProgress?.call('ping', 0.0, 0.0);
    final ping = await measurePing();
    onProgress?.call('ping', 1.0, 0.0);

    onProgress?.call('download', 0.0, 0.0);
    final download = await measureDownloadSpeed();
    onProgress?.call('download', 1.0, download);

    onProgress?.call('upload', 0.0, 0.0);
    final upload = await measureUploadSpeed();
    onProgress?.call('upload', 1.0, upload);

    return SpeedTestResult(
      downloadMbps: download,
      uploadMbps: upload,
      pingMs: ping,
    );
  }

  Future<int> measurePing() async {
    List<int> pings = [];
    final client = http.Client();
    try {
      for (int i = 0; i < 3; i++) {
        final stopwatch = Stopwatch()..start();
        try {
          await client.head(Uri.parse(_pingUrl)).timeout(const Duration(seconds: 2));
          stopwatch.stop();
          pings.add(stopwatch.elapsedMilliseconds);
        } catch (_) {
          pings.add(999);
        }
      }
    } finally {
      client.close();
    }
    pings.sort();
    return pings.isNotEmpty ? pings[pings.length ~/ 2] : 999;
  }

  Future<double> measureDownloadSpeed() async {
    final client = http.Client();
    int totalBytes = 0;
    bool isTesting = true;
    
    final stopwatch = Stopwatch()..start();
    List<Future<void>> downloads = [];

    // Setup periodic UI updates
    Timer? progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isTesting) {
        timer.cancel();
        return;
      }
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed > 0) {
        final currentMbps = (totalBytes * 8) / (elapsed * 1000);
        final progress = min(1.0, elapsed / testDuration.inMilliseconds);
        onProgress?.call('download', progress, currentMbps);
      }
    });

    try {
      for (int i = 0; i < concurrentConnections; i++) {
        downloads.add(Future(() async {
          while (isTesting) {
            try {
              final request = http.Request('GET', Uri.parse(_downloadUrl));
              final response = await client.send(request);
              await for (final chunk in response.stream) {
                if (!isTesting) break;
                totalBytes += chunk.length;
              }
            } catch (_) {
              // Ignore individual connection drops during stress test
              await Future.delayed(const Duration(milliseconds: 100));
            }
          }
        }));
      }

      await Future.delayed(testDuration);
    } finally {
      isTesting = false;
      progressTimer.cancel();
      client.close();
    }

    stopwatch.stop();
    final finalSeconds = stopwatch.elapsedMilliseconds / 1000.0;
    return finalSeconds > 0 ? (totalBytes * 8) / (finalSeconds * 1000000) : 0.0;
  }

  Future<double> measureUploadSpeed() async {
    final client = http.Client();
    int totalBytes = 0;
    bool isTesting = true;
    
    // Generate 1MB chunk to repeatedly upload
    final chunkData = Uint8List(1000000);
    for (int i = 0; i < chunkData.length; i++) {
      chunkData[i] = (i % 256);
    }

    final stopwatch = Stopwatch()..start();
    List<Future<void>> uploads = [];

    // Setup periodic UI updates
    Timer? progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isTesting) {
        timer.cancel();
        return;
      }
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed > 0) {
        final currentMbps = (totalBytes * 8) / (elapsed * 1000);
        final progress = min(1.0, elapsed / testDuration.inMilliseconds);
        onProgress?.call('upload', progress, currentMbps);
      }
    });

    try {
      for (int i = 0; i < concurrentConnections; i++) {
        uploads.add(Future(() async {
          while (isTesting) {
            try {
              final request = http.Request('POST', Uri.parse(_uploadUrl))
                ..bodyBytes = chunkData
                ..headers['Content-Type'] = 'application/octet-stream';
              
              // We just fire and track what we attempted to send in the timeframe
              await client.send(request).timeout(const Duration(seconds: 2));
              if (isTesting) {
                totalBytes += chunkData.length;
              }
            } catch (_) {
              await Future.delayed(const Duration(milliseconds: 100));
            }
          }
        }));
      }

      await Future.delayed(testDuration);
    } finally {
      isTesting = false;
      progressTimer.cancel();
      client.close();
    }

    stopwatch.stop();
    final finalSeconds = stopwatch.elapsedMilliseconds / 1000.0;
    return finalSeconds > 0 ? (totalBytes * 8) / (finalSeconds * 1000000) : 0.0;
  }
}

