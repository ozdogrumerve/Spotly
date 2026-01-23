import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Sadece konum izni verilmiş mi kontrol eder.
  static Future<bool> checkPermissionOnly() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // Konum servisinin açık olup olmadığını kontrol eder.
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Konum servisleri ayarlarını açar (ayarlar sayfası).
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Uygulama ayarlarını açar (izinleri değiştirmek için).
  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }

  // Geçerli konumu döner (izin ve servis açıksa).
  static Future<Position?> getCurrentPositionIfPossible() async {
    final hasPermission = await checkPermissionOnly();
    if (!hasPermission) return null;

    final enabled = await isLocationServiceEnabled();
    if (!enabled) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
