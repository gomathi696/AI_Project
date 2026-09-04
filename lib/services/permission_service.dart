import 'package:permission_handler/permission_handler.dart';

/// Wraps the permission checks the navigation screen needs before it can
/// start the camera loop. Kept separate from UI so Phase 2 can call
/// `ensureCameraPermission()` again right before opening the camera
/// without duplicating this logic.
class PermissionService {
  static Future<bool> ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  static Future<bool> isCameraPermanentlyDenied() async {
    return Permission.camera.isPermanentlyDenied;
  }
}
