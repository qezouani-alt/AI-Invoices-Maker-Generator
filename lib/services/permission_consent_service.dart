import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppPermissionKind { camera, photos, microphone, speech, tracking }

class AppPermissionItem {
  const AppPermissionItem({
    required this.kind,
    required this.permission,
    required this.title,
    required this.description,
  });

  final AppPermissionKind kind;
  final Permission permission;
  final String title;
  final String description;
}

/// Coordinates the launch-time permission review without collecting any
/// permission data outside the device.
class PermissionConsentService {
  PermissionConsentService._();

  // v2 adds the iOS App Tracking Transparency choice. Re-showing the review
  // lets existing users make that new choice without re-requesting any
  // permissions they have already granted.
  static const _reviewedKey = 'launch_permissions_reviewed_v2';

  static List<AppPermissionItem> get items {
    final permissions = <AppPermissionItem>[
      const AppPermissionItem(
        kind: AppPermissionKind.camera,
        permission: Permission.camera,
        title: 'Camera',
        description: 'Scan receipts and capture invoice images.',
      ),
      const AppPermissionItem(
        kind: AppPermissionKind.photos,
        permission: Permission.photos,
        title: 'Photos',
        description: 'Choose a logo or attach a receipt image.',
      ),
      const AppPermissionItem(
        kind: AppPermissionKind.microphone,
        permission: Permission.microphone,
        title: 'Microphone',
        description: 'Use voice input to create invoices and expenses.',
      ),
    ];

    // iOS has a separate speech-recognition permission.
    if (Platform.isIOS) {
      permissions.add(
        const AppPermissionItem(
          kind: AppPermissionKind.speech,
          permission: Permission.speech,
          title: 'Speech recognition',
          description: 'Turn your voice into editable invoice details.',
        ),
      );
      permissions.add(
        const AppPermissionItem(
          kind: AppPermissionKind.tracking,
          permission: Permission.appTrackingTransparency,
          title: 'Personalized ads',
          description:
              'Allow ad partners to deliver and measure relevant advertising across apps and websites.',
        ),
      );
    }
    return permissions;
  }

  static Future<bool> hasReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reviewedKey) ?? false;
  }

  static Future<Map<AppPermissionKind, PermissionStatus>> getStatuses() async {
    final result = <AppPermissionKind, PermissionStatus>{};
    for (final item in items) {
      try {
        result[item.kind] = await item.permission.status;
      } catch (_) {
        result[item.kind] = PermissionStatus.denied;
      }
    }
    return result;
  }

  static Future<Map<AppPermissionKind, PermissionStatus>> requestAll() async {
    final result = <AppPermissionKind, PermissionStatus>{};
    for (final item in items) {
      try {
        final current = await item.permission.status;
        if (current.isGranted || current.isLimited) {
          result[item.kind] = current;
          continue;
        }
        result[item.kind] = await item.permission.request();
      } catch (_) {
        result[item.kind] = PermissionStatus.denied;
      }
    }
    return result;
  }

  static Future<void> markReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewedKey, true);
  }

  static bool isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }
}
