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
PRIVACY POLICY

Last Updated: January 2025

1. INTRODUCTION

Zensta ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we handle information when you use our mobile application (the "Service"). By using Zensta, you agree to the collection and use of information in accordance with this policy.

2. INFORMATION WE COLLECT

Zensta is designed with privacy as a core principle. We do not collect, transmit, store, or share any personal information, usage data, or analytics data outside of your device. All data processing occurs exclusively on your device.

3. DATA STORAGE

All data associated with your use of Zensta, including:
• App lock configurations and schedules
• Usage statistics and analytics
• Lock history and preferences

is stored locally on your device using on-device storage mechanisms. This data never leaves your device and is not transmitted to any external servers or third parties.

4. REQUIRED PERMISSIONS

Zensta requires certain Android permissions to provide its core functionality:

Accessibility Service: This permission is used solely to detect when restricted applications are launched, enabling Zensta to display blocking interfaces during active lock periods. We do not access, store, or transmit any accessibility-related data.

Usage Access: This permission is required to calculate your total device usage time and generate usage statistics displayed within the application. All usage data is processed and stored exclusively on your device.

System Alert Window (Overlay Permission): This permission allows Zensta to display blocking interfaces when restricted applications are opened during active lock periods. No data is collected or transmitted through this permission.

5. ADVERTISING

Zensta utilizes Google AdMob to display rewarded advertisements. When you choose to watch advertisements to unlock applications early, the following applies:

• Ad serving and analytics are managed by Google AdMob according to Google's Privacy Policy
• We do not collect, process, or store any advertisement-related data
• Advertisement interactions are processed by Google's advertising services, not by Zensta
• For information about how Google handles advertising data, please review Google's Privacy Policy

6. DATA RETENTION AND DELETION

All data stored by Zensta remains on your device until you uninstall the application. Upon uninstallation, all locally stored data is automatically and permanently deleted from your device. We do not maintain any backup copies of your data, as no data is transmitted to our servers.

7. CHILDREN'S PRIVACY

Our Service is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us so we can delete such information.

8. CHANGES TO THIS PRIVACY POLICY

We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.

9. CONTACT US

If you have any questions about this Privacy Policy, please contact us through the application or visit our support channels.

10. DATA SECURITY

While we implement appropriate technical measures to protect your data on your device, please note that no method of electronic storage is 100% secure. We cannot guarantee absolute security of your locally stored data, but we ensure that no data is transmitted from your device, minimizing potential privacy risks.

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