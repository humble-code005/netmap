import 'package:geolocator/geolocator.dart';

class LocationService {
  static String detectTelecomCircle(Position? position) {
    if (position == null) return 'Unknown Circle';
    
    final lat = position.latitude;
    final lon = position.longitude;

    // Approximate boundaries for Indian Telecom Circles
    // Note: These are rough bounding boxes for logic purposes.
    
    // Delhi NCR
    if (lat >= 28.4 && lat <= 28.8 && lon >= 76.8 && lon <= 77.4) return 'Delhi NCR';
    
    // Mumbai
    if (lat >= 18.8 && lat <= 19.3 && lon >= 72.7 && lon <= 73.0) return 'Mumbai';
    
    // Karnataka (Bangalore)
    if (lat >= 12.8 && lat <= 13.2 && lon >= 77.4 && lon <= 77.8) return 'Karnataka';
    
    // Tamil Nadu (Chennai)
    if (lat >= 12.9 && lat <= 13.2 && lon >= 80.1 && lon <= 80.4) return 'Tamil Nadu';
    
    // Maharashtra & Goa (excluding Mumbai)
    if (lat >= 15.5 && lat <= 22.0 && lon >= 72.5 && lon <= 80.5) return 'Maharashtra & Goa';
    
    // Gujarat
    if (lat >= 20.0 && lat <= 24.5 && lon >= 68.0 && lon <= 74.5) return 'Gujarat';
    
    // Andhra Pradesh & Telangana
    if (lat >= 13.5 && lat <= 19.5 && lon >= 77.0 && lon <= 84.5) return 'AP & Telangana';
    
    // West Bengal & Kolkata
    if (lat >= 21.5 && lat <= 27.5 && lon >= 85.5 && lon <= 89.5) return 'West Bengal';
    
    // North India broad
    if (lat > 25 && lat < 35 && lon > 72 && lon < 87) return 'North India';
    
    // East India broad
    if (lat > 22 && lat < 26 && lon > 87 && lon < 92) return 'East India';
    
    // South India broad
    if (lat > 8 && lat < 16 && lon > 74 && lon < 85) return 'South India';
    
    // West India broad
    if (lat > 16 && lat < 24 && lon > 68 && lon < 78) return 'West India';

    return 'Central India';
  }
}
