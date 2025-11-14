import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_rule.dart';
import '../../controllers/rules_controller.dart';
import '../../services/ad_service.dart';
import '../theme.dart';

class AdUnlockButton extends ConsumerStatefulWidget {
  final AppRule rule;

  const AdUnlockButton({
    super.key,
    required this.rule,
  });

  @override
  ConsumerState<AdUnlockButton> createState() => _AdUnlockButtonState();
}

class _AdUnlockButtonState extends ConsumerState<AdUnlockButton> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _watchAd() async {
    // Show unlock duration picker first
    final duration = await showDialog<Duration>(
      context: context,
      builder: (_) => const _UnlockDurationDialog(),
    );

    if (duration == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final adService = AdService();
    final messenger = ScaffoldMessenger.of(context);

    if (!adService.isRewardedAdReady) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Ad is loading. Please wait...")),
      );
      await adService.loadRewardedAd();
      if (!mounted) return;
    }

    final earned = await adService.showRewardedAd();
    
    if (!mounted) return;

    if (earned) {
      // Unlock for the full requested duration
      await ref.read(rulesProvider.notifier).setTempUnlock(widget.rule.packageName, duration);
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Unlocked for ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} 🎉",
          ),
          backgroundColor: AppColors.mint,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      // User didn't watch the ad fully
      final error = adService.lastLoadError;
      String errorMsg = 'Ad not available right now';
      if (error != null) {
        final code = error.code;
        if (code == 3) { // ERROR_CODE_NO_FILL
          errorMsg = 'No ads available. Please try again later.';
        } else if (code == 2) { // ERROR_CODE_NETWORK_ERROR
          errorMsg = 'Network error. Check your connection.';
        } else if (code == 1) { // ERROR_CODE_INVALID_REQUEST
          errorMsg = 'Ad configuration error. Please contact support.';
        } else {
          errorMsg = 'Unable to load ad (Error $code). Please try again.';
        }
      }
      setState(() {
        _errorMessage = errorMsg;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text("You must watch the full ad to unlock"),
          duration: Duration(seconds: 3),
        ),
      );
    }

    // Preload next ad for future use
    adService.loadRewardedAd();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUnlock = widget.rule.canWatchAdToUnlock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: canUnlock && !_isLoading ? _watchAd : null,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.play_circle_outline),
          label: const Text('Watch Ad to Unlock'),
          style: ElevatedButton.styleFrom(
            backgroundColor: canUnlock ? AppColors.mint : Colors.grey,
            foregroundColor: AppColors.ink,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _watchAd,
                  child: const Text('Retry'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
      ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How long do you want to unlock the app?"),
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
          child: const Text(
            "Watch Ad",
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
