import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_rule.dart';
import '../../controllers/ad_unlock_controller.dart';
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adUnlockController = ref.read(adUnlockProvider.notifier);
      final rulesController = ref.read(rulesProvider.notifier);
      
      final success = await adUnlockController.watchAdToUnlock(
        widget.rule.packageName,
        () async {
          final adService = AdService();
          if (!adService.isRewardedAdReady) {
            await adService.loadRewardedAd();
          }
          return await adService.showRewardedAd();
        },
      );

      if (success) {
        // Update the rule with temporary unlock
        final unlockState = adUnlockController.getStateForPackage(
          widget.rule.packageName,
        );
        
        if (unlockState != null && unlockState.unlockExpiresAt != null) {
          final duration = unlockState.unlockExpiresAt!.difference(DateTime.now());
          await rulesController.setTempUnlock(widget.rule.packageName, duration);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unlocked for ${adUnlockController.getTotalUnlockDuration(widget.rule.packageName).inMinutes} minutes!',
              ),
              backgroundColor: AppColors.mint,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Ad not available right now';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load ad. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adUnlockState = ref.watch(adUnlockProvider);
    final adsWatched = adUnlockState[widget.rule.packageName]?.adsWatched ?? 0;
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
          label: Text(
            adsWatched > 0
                ? 'Watch Ad ($adsWatched watched)'
                : 'Watch Ad to Unlock',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canUnlock ? AppColors.mint : Colors.grey,
            foregroundColor: AppColors.ink,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
          ),
        ),
        if (!canUnlock)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Available after 50% progress',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
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
