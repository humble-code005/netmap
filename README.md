# 📡 NetMap — India Network Scanner Pro

A premium mobile carrier analytics and network diagnostic tool built with **Flutter**, designed specifically for the Indian telecom market.

![Flutter](https://img.shields.io/badge/Flutter-3.41-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## ✨ Features

### 📱 Mobile Carrier Analytics
- **Live Detection** — Identifies your active SIM carrier (Jio, Airtel, Vi, BSNL) and network type (5G/4G/3G)
- **WiFi-Aware** — Automatically detects WiFi connections and displays SSID instead of carrier data
- **Telecom Circle Detection** — Identifies your Indian telecom region (Delhi NCR, Mumbai, Karnataka, etc.)

### ⚡ Professional Speed Test
- **Multi-Threaded Engine** — Uses 4 parallel HTTP streams for Ookla-style bandwidth saturation accuracy
- **Real-Time Gauge** — Custom-painted animated speedometer showing live Mbps during test
- **Detailed Metrics** — Ping (ms), Download (Mbps), Upload (Mbps) with history tracking

### 🗺️ Crowdsourced Signal Heatmap
- **Geospatial Gridding** — Signal data snapped to ~50m grid cells for geographic aggregation
- **Carrier Filtering** — View heatmap data filtered by specific carriers (Jio, Airtel, Vi, BSNL)
- **Dynamic Crowdsourcing** — Simulates multi-user data to build useful heatmaps from individual scans
- **CartoDB Dark Matter Tiles** — Premium dark map aesthetic with no API key required

### 📶 WiFi Scanner
- **Network Discovery** — Lists all nearby access points with SSID, BSSID, Signal (dBm), Channel, Frequency
- **Security Audit** — Identifies encryption types (WPA2, WPA3, Open)
- **Quality Scoring** — Proprietary 0-100 score based on signal strength and frequency band

### 📊 Analytics & History
- **Signal History Charts** — Track signal strength trends over time with FL Chart
- **Channel Analysis** — Visualize 2.4GHz and 5GHz channel congestion
- **CSV Export** — Export scan history for external analysis
- **Scan History** — Browse and review past scan results

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.41 (Dart 3.11) |
| Design | Material 3, Dark Mode, Glassmorphism |
| Database | SQLite (`sqflite`) — Schema v2 |
| Maps | `flutter_map` + CartoDB Dark Matter tiles |
| Carrier Info | `carrier_info` (Android/iOS SIM detection) |
| Speed Test | `http` package (multi-threaded streaming) |
| Location | `geolocator` (GPS) |
| Charts | `fl_chart` |

## 📦 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── scan_record.dart         # Scan data model (carrier, networks, GPS)
│   └── wifi_network_model.dart  # WiFi network data model
├── screens/
│   ├── home_screen.dart         # Main navigation shell
│   ├── scanner_screen.dart      # Live scanner dashboard
│   ├── speed_test_screen.dart   # Speed test UI with gauge
│   ├── heatmap_screen.dart      # Crowdsourced signal map
│   ├── history_screen.dart      # Scan history list
│   ├── channel_screen.dart      # Channel analysis
│   ├── network_detail_screen.dart # Individual network details
│   └── settings_screen.dart     # App settings
├── services/
│   ├── scanner_service.dart     # WiFi scanning engine
│   ├── mobile_network_service.dart # Carrier/WiFi detection
│   ├── speed_test_service.dart  # Multi-threaded bandwidth test
│   ├── database_service.dart    # SQLite CRUD + crowdsourcing
│   ├── location_service.dart    # Telecom circle detection
│   ├── crowd_service.dart       # Crowd data aggregation
│   └── notification_service.dart # In-app alerts
├── widgets/
│   ├── speed_gauge.dart         # Custom painted speedometer
│   ├── pro_widgets.dart         # Glassmorphic UI components
│   ├── network_list_tile.dart   # Network list item
│   ├── quality_indicator.dart   # Signal quality badge
│   ├── signal_chart.dart        # Signal trend chart
│   ├── channel_chart.dart       # Channel congestion chart
│   └── crowd_insight_card.dart  # Crowdsource insight widget
└── theme/
    └── app_theme.dart           # Dark theme, colors, typography
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Android Studio / VS Code
- Android device with USB debugging enabled (for real carrier data)

### Installation
```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/netmap.git
cd netmap

# Install dependencies
flutter pub get

# Run on connected Android device
flutter run

# Or build APK
flutter build apk --debug
```

### Permissions Required (Android)
- `ACCESS_FINE_LOCATION` — WiFi scanning & GPS for heatmap
- `READ_PHONE_STATE` — SIM carrier identification
- `INTERNET` — Speed test & map tiles

## 🎯 Target Market
Built specifically for the **Indian telecom ecosystem**:
- **Jio** (5G/4G)
- **Airtel** (5G/4G)
- **Vi (Vodafone Idea)** (4G)
- **BSNL** (4G/3G)

## 📄 License
This project is licensed under the MIT License.
