import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Request storage permissions based on Android version
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      // For Android 13+ (SDK 33+)
      if (await _isAndroid13OrHigher()) {
        // Request media permissions
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();

        if (photos.isDenied || videos.isDenied) {
          _showPermissionsDialog(context, "Storage");
          return false;
        }

        return true;
      } else {
        // For Android 12 and below
        final status = await Permission.storage.request();
        if (status.isDenied) {
          _showPermissionsDialog(context, "Storage");
          return false;
        }
        return true;
      }
    } else if (Platform.isIOS) {
      final photos = await Permission.photos.request();
      if (photos.isDenied) {
        _showPermissionsDialog(context, "Photos");
        return false;
      }
      return true;
    }

    return false;
  }

  // Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();

    // If camera permission denied, show dialog
    if (cameraStatus.isDenied) {
      _showPermissionsDialog(context, "Camera");
      return false;
    }

    // Also request microphone for video recording
    final micStatus = await Permission.microphone.request();

    // Microphone is helpful but not required for photos, so we don't return false here
    if (micStatus.isDenied) {
      print("Microphone permission denied. Video recording may not have audio.");
    }

    return true;
  }

  // Request all necessary permissions at once
  static Future<bool> requestAllPermissions(BuildContext context) async {
    final cameraGranted = await requestCameraPermission(context);
    final storageGranted = await requestStoragePermission(context);

    return cameraGranted && storageGranted;
  }

  // Check if device is running Android 13 or higher
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    return await Permission.photos.status != PermissionStatus.permanentlyDenied &&
        await Permission.videos.status != PermissionStatus.permanentlyDenied;
  }

  // Show a dialog explaining why permissions are needed with settings option
  static void _showPermissionsDialog(BuildContext context, String permissionType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          'This app needs $permissionType access to manage your photos and videos. '
              'Please grant this permission in Settings to continue using the app.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}