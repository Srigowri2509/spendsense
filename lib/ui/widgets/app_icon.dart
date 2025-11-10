import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import '../theme.dart';

class AppIcon extends StatefulWidget {
  final String package;
  final String fallbackLetter;

  const AppIcon({
    super.key,
    required this.package,
    required this.fallbackLetter,
  });

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      AppInfo? match;
      for (final a in apps) {
        if (a.packageName == widget.package) {
          match = a;
          break;
        }
      }
      if (!mounted) return;
      if (match != null && match.icon != null && match.icon!.isNotEmpty) {
        setState(() => bytes = match!.icon);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (bytes != null && bytes!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: MemoryImage(bytes!),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.mint.withValues(alpha: 64),
      child: Text(
        widget.fallbackLetter,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}