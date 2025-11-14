import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/rules_controller.dart';
import '../../services/ad_service.dart';
import '../theme.dart';
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
    
    // Show unlock duration picker first
    final duration = await showDialog<Duration>(
      context: context,
      builder: (_) => const _UnlockDurationDialog(),
    );

    if (duration == null || !mounted) return;

    // Calculate number of ads needed (10 minutes per ad)
    final adCount = (duration.inMinutes / 10).ceil();
    
    if (!_adService.isRewardedAdReady) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Ad is still loading. Please try again.")),
      );
      await _adService.loadRewardedAd();
      return;
    }

    // Show progress dialog for multiple ads
    int adsWatched = 0;

    for (int i = 0; i < adCount; i++) {
      if (!mounted) return;

      // Show progress if multiple ads
      if (adCount > 1 && i > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Watching ad ${i + 1} of $adCount..."),
            duration: const Duration(seconds: 2),
          ),
        );
        // Wait a bit before showing next ad
        await Future.delayed(const Duration(seconds: 1));
      }

      if (!_adService.isRewardedAdReady) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Ad is loading. Please wait...")),
        );
        await _adService.loadRewardedAd();
        if (!mounted) return;
      }

      final earned = await _adService.showRewardedAd();
      
      if (!mounted) return;

      if (earned) {
        adsWatched++;
        // Preload next ad if there are more to watch
        if (i < adCount - 1) {
          _adService.loadRewardedAd();
        }
      } else {
        // User didn't watch the ad fully
        messenger.showSnackBar(
          const SnackBar(
            content: Text("You must watch the full ad to unlock"),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // All ads watched successfully
    if (adsWatched == adCount && mounted) {
      // Unlock for the full requested duration
      await ref.read(rulesProvider.notifier).setTempUnlock(packageName, duration);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Unlocked for ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} 🎉\n"
            "Watched $adCount ad${adCount > 1 ? 's' : ''}",
          ),
          backgroundColor: AppColors.mint,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // Preload next ad for future use
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

  int _getAdCount(Duration duration) => (duration.inMinutes / 10).ceil();

  @override
  Widget build(BuildContext context) {
    final adCount = _getAdCount(selected);
    return AlertDialog(
      title: const Text("Unlock Duration"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How long do you want to unlock the app?"),
          const SizedBox(height: 8),
          Text(
            "You'll need to watch $adCount ad${adCount > 1 ? 's' : ''} (10 min per ad)",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.ink.withValues(alpha: 150),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _durationChip(const Duration(minutes: 10)),
              _durationChip(const Duration(minutes: 20)),
              _durationChip(const Duration(minutes: 30)),
              _durationChip(const Duration(minutes: 60)),
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
          child: Text(
            "Watch $adCount Ad${adCount > 1 ? 's' : ''}",
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _durationChip(Duration d) {
    final adCount = _getAdCount(d);
    return ChoiceChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("${d.inMinutes} min"),
          Text(
            "$adCount ad${adCount > 1 ? 's' : ''}",
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
      selected: selected == d,
      onSelected: (_) => setState(() => selected = d),
      selectedColor: AppColors.chipBg,
    );
  }
}