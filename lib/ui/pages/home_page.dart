import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/rules_controller.dart';
import '../../services/ad_service.dart';
import '../theme.dart';
import '../../models/app_rule.dart';
import '../widgets/lock_card.dart';
import '../widgets/group_card.dart';
import '../widgets/fab_add.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final AdService _adService = AdService();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _adService.loadRewardedAd();
    // Start a periodic timer to update UI clocks/progress in real-time.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      // Rebuild the page to update remaining/progress displays.
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(rulesProvider);
    final groups = ref.read(rulesProvider.notifier).groups;

    return Scaffold(
      appBar: AppBar(title: const Text("Zensta")),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _HeaderHero(),
          ),
          const SizedBox(height: 8),
          if (rules.isEmpty)
            const _EmptyState()
          else
            ...rules.map((r) => LockCard(
                  rule: r,
                  onWatchAd: () => _handleWatchAd(r.packageName),
                )),
          if (groups.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Text(
                "Groups",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ...groups.map((g) => GroupCard(group: g)),
          ],
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: const FabAdd(),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _handleWatchAd(String packageName) async {
    // Capture the messenger early to avoid using `context` after awaits.
    final messenger = ScaffoldMessenger.of(context);
    if (!_adService.isRewardedAdReady) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Ad is still loading. Please try again.")),
      );
      await _adService.loadRewardedAd();
      return;
    }

    // Show unlock duration picker
    final duration = await showDialog<Duration>(
      context: context,
      builder: (_) => const _UnlockDurationDialog(),
    );

    if (duration == null) return;

    final earned = await _adService.showRewardedAd();
    
  if (!mounted) return;
    if (earned) {
      await ref.read(rulesProvider.notifier).reduceLockBy(packageName, duration);

      // Read updated rule
      AppRule? after;
      for (final r in ref.read(rulesProvider)) {
        if (r.packageName == packageName) {
          after = r;
          break;
        }
      }

      if (after != null) {
        if (after.mode == LockMode.scheduled) {
          // If remaining <= duration, controller sets a temp unlock until window end
          if (after.tempUnlockUntil != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text("Unlocked until end of scheduled window 🎉"),
                backgroundColor: AppColors.mint,
              ),
            );
          } else {
            messenger.showSnackBar(
              SnackBar(
                content: Text("Temporarily unlocked for ${duration.inMinutes} minutes 🎉"),
                backgroundColor: AppColors.mint,
              ),
            );
          }
        } else {
          // Quick timer: either reduced remaining time or fully unlocked
          if (!after.active) {
            messenger.showSnackBar(
              SnackBar(
                content: Text("Timer ended — unlocked 🎉"),
                backgroundColor: AppColors.mint,
              ),
            );
          } else {
            messenger.showSnackBar(
              SnackBar(
                content: Text("Reduced remaining time by ${duration.inMinutes} minutes 🎉"),
                backgroundColor: AppColors.mint,
              ),
            );
          }
        }
      } else {
        // No rule found after operation — treat as unlocked
        messenger.showSnackBar(
          SnackBar(
            content: Text("Unlocked 🎉"),
            backgroundColor: AppColors.mint,
          ),
        );
      }
    } else if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text("You must watch the full ad to unlock")),
      );
    }

    // Preload next ad
    _adService.loadRewardedAd();
  }
}

class _HeaderHero extends StatelessWidget {
  const _HeaderHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF1EA),
                Color(0xFFEFD6CD),
                Color(0xFFF4F1DE),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stay in flow",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Lock distracting apps with timers or schedules. Watch ads for early access ✨",
                      style: GoogleFonts.poppins(
                        color: AppColors.ink.withValues(alpha: 191),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Icon(
            Icons.self_improvement,
            color: AppColors.accent,
            size: 42,
          ),
          const SizedBox(height: 8),
          Text(
            "Nothing locked yet",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap + to choose an app and set a timer or schedule.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.ink.withValues(alpha: 179),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockDurationDialog extends StatefulWidget {
  const _UnlockDurationDialog();

  @override
  State<_UnlockDurationDialog> createState() => _UnlockDurationDialogState();
}

class _UnlockDurationDialogState extends State<_UnlockDurationDialog> {
  Duration selected = const Duration(minutes: 10);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Unlock Duration"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("How long do you need the app unlocked?"),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _durationChip(const Duration(minutes: 10)),
              _durationChip(const Duration(minutes: 20)),
              _durationChip(const Duration(minutes: 30)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selected),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
          ),
          child: const Text(
            "Continue",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _durationChip(Duration d) {
    return ChoiceChip(
      label: Text("${d.inMinutes} min"),
      selected: selected == d,
      onSelected: (_) => setState(() => selected = d),
      selectedColor: AppColors.chipBg,
    );
  }
}