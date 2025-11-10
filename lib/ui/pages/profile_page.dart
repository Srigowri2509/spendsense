import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:device_apps/device_apps.dart';
import 'package:app_settings/app_settings.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'privacy_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<UsageInfo> todayUsage = [];
  List<UsageInfo> yesterdayUsage = [];
  bool hasPermission = true;

  @override
  void initState() {
    super.initState();
    fetchUsageData();
  }

  Future<void> fetchUsageData() async {
    try {
      DateTime now = DateTime.now();
      DateTime startToday = DateTime(now.year, now.month, now.day);
      DateTime startYesterday = startToday.subtract(const Duration(days: 1));

      final todayList = await UsageStats.queryUsageStats(startToday, now);
      final yesterdayList = await UsageStats.queryUsageStats(
              startYesterday, startToday);

      setState(() {
        todayUsage = todayList;
        yesterdayUsage = yesterdayList;
      });
    } catch (e) {
      setState(() => hasPermission = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text("Analytics")),
        body: NoUsagePermission(
          onEnable: () => AppSettings.openAppSettings(),
        ),
      );
    }

    if (todayUsage.isEmpty && yesterdayUsage.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Analytics")),
        body: const Center(
          child: Text(
            "No data yet",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    int todayMs = todayUsage.fold(
        0, (sum, u) => sum + safeToInt(u.totalTimeInForeground));
    int yesterdayMs = yesterdayUsage.fold(
        0, (sum, u) => sum + safeToInt(u.totalTimeInForeground));

    int saved = (yesterdayMs - todayMs).clamp(0, yesterdayMs);
    String savedPercent = yesterdayMs == 0
        ? "0"
        : ((saved / yesterdayMs) * 100).clamp(0, 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: const Text("Analytics")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildStatCard(todayMs, yesterdayMs, saved, savedPercent),
          const SizedBox(height: 20),
          Text(
            "Today's Top Apps",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ..._buildTopApps(todayUsage),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.privacy_tip_outlined),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            label: const Text(
              "View Privacy Policy",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPage()),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Note: Zensta reads Android Usage Stats locally and does not upload any data.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(int todayMs, int yesterdayMs, int saved, String savedPercent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 8),
          )
        ],
        borderRadius: BorderRadius.circular(26),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          color: AppColors.card,
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daily Comparison",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text("Yesterday: ${_fmt(yesterdayMs)}"),
              Text("Today: ${_fmt(todayMs)}"),
              const SizedBox(height: 8),
              Text(
                "✅ You saved ${_fmt(saved)} ($savedPercent%)",
                style: const TextStyle(color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  List<Widget> _buildTopApps(List<UsageInfo> list) {
    final sorted = [...list];
    sorted.sort((a, b) => safeToInt(b.totalTimeInForeground)
        .compareTo(safeToInt(a.totalTimeInForeground)));
    return sorted.take(10).map((u) {
      final ms = safeToInt(u.totalTimeInForeground);
      if (ms < 60000) return const SizedBox.shrink();
      return FutureBuilder<Application?>(
        future: DeviceApps.getApp(u.packageName ?? "", true),
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final app = snap.data!;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: AppColors.card,
                child: ListTile(
                  leading: app is ApplicationWithIcon
                      ? Image.memory(app.icon, width: 36, height: 36)
                      : const Icon(Icons.apps),
                  title: Text(
                    app.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _fmt(ms),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  String _fmt(int ms) {
    final min = (ms / 60000).floor();
    final h = min ~/ 60;
    final m = min % 60;
    return "${h}h ${m}m";
  }
}

class NoUsagePermission extends StatelessWidget {
  final VoidCallback onEnable;

  const NoUsagePermission({super.key, required this.onEnable});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 18,
                offset: Offset(0, 8),
              )
            ],
            borderRadius: BorderRadius.circular(26),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              color: AppColors.card,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_person,
                    color: AppColors.accent,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Allow Usage Access",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "To show your real screen time and time saved, please enable Usage Access for Zensta.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onEnable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    child: const Text(
                      "Open Settings",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}