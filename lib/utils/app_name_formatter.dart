import 'package:installed_apps/app_info.dart';

class AppNameFormatter {
  static String getCleanName(AppInfo app) {
    String name = app.name;

    // Remove patterns like "android/", "com.", etc.
    if (name.contains('/')) {
      name = name.split('/').last;
    }

    // Remove common package prefixes
    if (name.startsWith('com.')) {
      final parts = name.split('.');
      if (parts.length > 2) {
        name = parts.last;
      }
    }

    // Capitalize first letter if needed
    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }

    return name;
  }

  static String getCleanNameFromString(String appName) {
    String name = appName;

    // Remove patterns like "android/", "com.", etc.
    if (name.contains('/')) {
      name = name.split('/').last;
    }

    // Remove common package prefixes
    if (name.startsWith('com.')) {
      final parts = name.split('.');
      if (parts.length > 2) {
        name = parts.last;
      }
    }

    // Capitalize first letter if needed
    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1);
    }

    return name;
  }
}
