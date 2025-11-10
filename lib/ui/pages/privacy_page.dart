import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        backgroundColor: AppColors.bg,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            """
Privacy Policy

Zensta values your privacy.  
We do not collect, transmit, or share any personal or app usage data.  
All statistics such as screen time saved are stored locally on your device only.

Permissions Explained:
• Accessibility Service : Used only to detect app launches so Zensta can block chosen apps during lock periods.  
• Usage Access : Required to calculate your total app usage time and display time saved.  
• Overlay Permission : Displays the lock popup when restricted apps are opened.

Ads:
• Rewarded ads are provided by Google AdMob to allow early unlocking of locked apps.
• Ad data is handled by Google according to their privacy policy.
• We do not collect or store any ad-related data.

Your data never leaves your device.  
If you uninstall the app, all stored data is deleted automatically.

© 2025 Zensta. All rights reserved.
""",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.ink,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}