import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_rule.dart';
import '../../controllers/rules_controller.dart';
import '../../controllers/ad_unlock_controller.dart';
import '../theme.dart';
import 'app_icon.dart';
import 'ad_unlock_button.dart';
import 'unlock_timer_widget.dart';

class LockCard extends ConsumerWidget {
  final AppRule rule;
  final VoidCallback? onWatchAd;

  const LockCard({
    super.key,
    required this.rule,
    this.onWatchAd,
  });

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return "$h:${two(m)}:${two(s)}";
    return "${two(m)}:${two(s)}";
  }

  String _modeLabel() => rule.mode == LockMode.quick ? "Timer" : "Scheduled";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final letter = rule.appName.isNotEmpty ? rule.appName[0].toUpperCase() : "?";
    final locked = rule.active;
    final progress = rule.progressPercent;
    final canWatchAd = rule.canWatchAdToUnlock && locked;
    
    // Check if temporarily unlocked
    final adUnlockState = ref.watch(adUnlockProvider);
    final unlockState = adUnlockState[rule.packageName];
    final isTemporarilyUnlocked = unlockState?.isActive ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  AppIcon(
                    package: rule.packageName,
                    fallbackLetter: letter,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rule.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.chipBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer,
                          size: 16,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          locked
                              ? _fmt(rule.remaining)
                              : (rule.mode == LockMode.scheduled
                                  ? "Next window"
                                  : "Done"),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Temporary unlock timer
              if (isTemporarilyUnlocked && unlockState!.unlockExpiresAt != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: UnlockTimerWidget(
                    expiresAt: unlockState.unlockExpiresAt!,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Progress bar
              if (locked) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress < 50 ? AppColors.accent : AppColors.mint,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${progress.toStringAsFixed(0)}% complete",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 153),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Message indicator
              if (rule.customMessage != null &&
                  rule.customMessage!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rule.customMessage!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 179),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Ad unlock button
              if (locked && canWatchAd && !isTemporarilyUnlocked) ...[
                AdUnlockButton(rule: rule),
                const SizedBox(height: 10),
              ],

              // Bottom row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 46),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _modeLabel(),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(rulesProvider.notifier).tryRemove(rule);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Remove"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String two(int n) => n.toString().padLeft(2, '0');
