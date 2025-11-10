import 'package:flutter/material.dart';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'root_nav.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});
  
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with WidgetsBindingObserver {
  bool allGranted = false;
  bool _guidingFlow = false;

  static const MethodChannel _channel = MethodChannel('zensta/permissions');

  Future<bool> _canDrawOverlays() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('canDrawOverlays');
      return res == true;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> _hasUsageAccess() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('hasUsageAccess');
      return res == true;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> _isAccessibilityEnabled() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return res == true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _checkPermissions() async {
    // Run real checks on Android; on other platforms assume granted.
    final overlay = await _canDrawOverlays();
    final usage = await _hasUsageAccess();
    final acc = await _isAccessibilityEnabled();
    setState(() => allGranted = overlay && usage && acc);
  }

  void _openAccessibility() {
    if (Platform.isAndroid) {
      try {
        AndroidIntent(action: 'android.settings.ACCESSIBILITY_SETTINGS').launch();
        return;
      } catch (_) {}
    }
    AppSettings.openAppSettings();
  }

  void _openUsageAccess() {
    if (Platform.isAndroid) {
      try {
        AndroidIntent(action: 'android.settings.USAGE_ACCESS_SETTINGS').launch();
        return;
      } catch (_) {}
    }
    AppSettings.openAppSettings();
  }

  void _openOverlay() {
    if (Platform.isAndroid) {
      try {
        // Direct user to the overlay permission page. Some devices will show
        // the app-specific toggle; others show a list of apps.
        AndroidIntent(
          action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
        ).launch();
        return;
      } catch (_) {}
    }
    AppSettings.openAppSettings();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // initial quick check
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When returning from settings, re-check permissions and continue guided flow
      if (_guidingFlow) {
        _onResumeDuringGuidedFlow();
      } else {
        _checkPermissions();
      }
    }
  }

  Future<void> _onResumeDuringGuidedFlow() async {
    // After returning from an intent, re-check and progress to next missing permission
    final overlay = await _canDrawOverlays();
    if (!overlay) {
      // Open overlay again (user likely didn't grant yet)
      _openOverlay();
      return;
    }

    final usage = await _hasUsageAccess();
    if (!usage) {
      _openUsageAccess();
      return;
    }

    final acc = await _isAccessibilityEnabled();
    if (!acc) {
      _openAccessibility();
      return;
    }

    // all granted
    setState(() {
      _guidingFlow = false;
      allGranted = true;
    });
  }

  Future<void> _startGuidedPermissionFlow() async {
    if (!Platform.isAndroid) {
      // On non-Android open app settings fallback
      await AppSettings.openAppSettings();
      await Future.delayed(const Duration(seconds: 2));
      await _checkPermissions();
      return;
    }

    setState(() => _guidingFlow = true);
    // Start with overlay (most specific). The resume handler will continue the flow.
    _openOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text("Setup Zensta")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_clock,
              size: 80,
              color: AppColors.accent,
            ),
            const SizedBox(height: 24),
            const Text(
              "Grant Permissions",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Zensta needs these permissions to lock apps and track your progress",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _permIcon(
                  Icons.accessibility_new,
                  "Accessibility",
                  _openAccessibility,
                ),
                _permIcon(
                  Icons.query_stats,
                  "Usage",
                  _openUsageAccess,
                ),
                _permIcon(
                  Icons.layers,
                  "Overlay",
                  _openOverlay,
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              onPressed: () async {
                // Start guided flow on Android; otherwise open app settings.
                await _startGuidedPermissionFlow();
              },
              child: const Text(
                "Allow All Permissions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: allGranted ? AppColors.mint : Colors.grey,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              onPressed: allGranted
                  ? () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RootNav(),
                        ),
                      )
                  : null,
              child: const Text(
                "Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permIcon(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
          child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, size: 30, color: AppColors.accent),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}