import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Status hasil pengecekan layanan lokasi
enum LocationServiceStatus {
  /// GPS/Lokasi perangkat aktif dan izin diberikan — siap digunakan
  ready,

  /// GPS/Lokasi perangkat tidak aktif (dimatikan di Settings perangkat)
  serviceDisabled,

  /// Izin lokasi ditolak oleh pengguna (masih bisa diminta lagi)
  permissionDenied,

  /// Izin lokasi ditolak permanen (user harus buka Settings app)
  permissionDeniedForever,
}

class LocationService {
  // ----------------------------------------------------------------
  //  Status & helpers
  // ----------------------------------------------------------------

  /// Cek apakah layanan GPS di perangkat aktif
  static Future<bool> isGpsEnabled() => Geolocator.isLocationServiceEnabled();

  /// Buka halaman pengaturan lokasi sistem (untuk mengaktifkan GPS)
  static Future<void> openGpsSettings() => Geolocator.openLocationSettings();

  /// Cek status lengkap GPS + perizinan tanpa meminta izin baru.
  static Future<LocationServiceStatus> checkServiceStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationServiceStatus.serviceDisabled;
    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  /// Pastikan GPS aman digunakan:
  /// - Cek GPS perangkat aktif
  /// - Minta izin lokasi via Geolocator jika belum ada
  static Future<LocationServiceStatus> ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationServiceStatus.serviceDisabled;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _mapPermission(permission);
  }

  // ----------------------------------------------------------------
  //  Stream-based position (metode utama yang digunakan CameraScreen)
  // ----------------------------------------------------------------

  /// Buat stream posisi yang:
  /// 1. Segera emit posisi terakhir yang diketahui (jika ada) untuk tampilan instan
  /// 2. Kemudian emit posisi-posisi baru dari GPS secara berkelanjutan
  ///
  /// Caller bertanggung jawab untuk cancel subscription saat tidak dibutuhkan.
  static Stream<Position> positionStream() async* {
    // Langkah 1 – Emit posisi terakhir segera (tidak perlu GPS lock baru)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) yield lastKnown;
    } catch (_) {}

    // Langkah 2 – Stream posisi baru secara berkelanjutan
    // distanceFilter = 10m: hanya update jika bergerak > 10 meter
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
      ),
    );
  }

  // ----------------------------------------------------------------
  //  One-shot (tetap tersedia untuk kegunaan lain)
  // ----------------------------------------------------------------

  /// Dapatkan posisi sekarang sekali pakai.
  /// Fallback ke posisi terakhir jika fresh position timeout.
  static Future<Position?> getCurrentPosition() async {
    try {
      final status = await ensureReady();
      if (status != LocationServiceStatus.ready) return null;

      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 20),
          ),
        );
      } on Exception catch (e) {
        debugPrint('[LocationService] getCurrentPosition timeout: $e');
        return lastKnown;
      }
    } catch (e, st) {
      debugPrint('[LocationService] fatal: $e\n$st');
      return null;
    }
  }

  // ----------------------------------------------------------------
  //  Geocoding
  // ----------------------------------------------------------------

  /// Reverse geocoding: koordinat → nama lokasi (bisa null jika offline)
  static Future<String?> getLocationName(double lat, double long) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, long);
      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      final parts = <String>[
        if (p.subLocality?.isNotEmpty == true) p.subLocality!,
        if (p.locality?.isNotEmpty == true) p.locality!,
        if (p.subAdministrativeArea?.isNotEmpty == true)
          p.subAdministrativeArea!,
      ];
      return parts.isNotEmpty ? parts.join(', ') : null;
    } catch (e) {
      debugPrint('[LocationService] geocoding error: $e');
      return null;
    }
  }

  /// Format koordinat menjadi string yang bisa dibaca
  static String formatLatLong(double lat, double long) {
    final latStr = lat >= 0
        ? '${lat.toStringAsFixed(5)}°N'
        : '${(-lat).toStringAsFixed(5)}°S';
    final longStr = long >= 0
        ? '${long.toStringAsFixed(5)}°E'
        : '${(-long).toStringAsFixed(5)}°W';
    return '$latStr, $longStr';
  }

  // ----------------------------------------------------------------
  //  Internal
  // ----------------------------------------------------------------

  static LocationServiceStatus _mapPermission(LocationPermission p) {
    switch (p) {
      case LocationPermission.deniedForever:
        return LocationServiceStatus.permissionDeniedForever;
      case LocationPermission.denied:
        return LocationServiceStatus.permissionDenied;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationServiceStatus.ready;
      default:
        return LocationServiceStatus.permissionDenied;
    }
  }
}
