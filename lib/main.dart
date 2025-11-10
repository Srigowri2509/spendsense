import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ui/theme.dart';
import 'ui/pages/setup_page.dart';
import 'services/usage_tracking_service.dart';
import 'services/ad_service.dart';

/// Global Notification Plugin
final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

/// Initialize Notifications
Future<void> _initNotifications() async {
  tz.initializeTimeZones();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  final iOS = DarwinInitializationSettings();
  final settings = InitializationSettings(android: android, iOS: iOS);
  await notifications.initialize(settings);
}

/// Initialize Mobile Ads
Future<void> _initAds() async {
  await MobileAds.instance.initialize();
  // Preload rewarded ad
  await AdService().loadRewardedAd();
}

/// Initialize Usage Tracking
Future<void> _initUsageTracking() async {
  final service = UsageTrackingService();
  // Cleanup old data on startup
  await service.cleanupOldData();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Skip certain native plugin initializations on web where they are not
  // supported. Initializing them on unsupported platforms can throw and
  // prevent the app from starting (blank screen in web builds).
  if (!kIsWeb) {
    await _initNotifications();
    await _initAds();
    await _initUsageTracking();
  }

  runApp(const ProviderScope(child: ZenstaApp()));
}

class ZenstaApp extends StatelessWidget {
  const ZenstaApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zensta',
      theme: zenTheme(),
      home: const SetupPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}