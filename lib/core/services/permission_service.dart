import 'package:permission_handler/permission_handler.dart';

/// Mengelola izin runtime untuk kamera.
/// Izin lokasi dikelola sepenuhnya oleh LocationService via Geolocator.
class PermissionService {
  /// Minta izin kamera
  static Future<PermissionResult> requestAll() async {
    final status = await Permission.camera.request();

    return PermissionResult(
      cameraGranted: status.isGranted,
    );
  }

  /// Cek status kamera
  static Future<bool> isCameraGranted() async {
    return Permission.camera.isGranted;
  }

  /// Buka pengaturan aplikasi
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}

class PermissionResult {
  final bool cameraGranted;

  const PermissionResult({
    required this.cameraGranted,
  });
}
