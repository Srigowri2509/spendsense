
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  // Test Ad Units - Replace with your real Ad Unit IDs in production
  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    }
    return '';
  }

  /// Load Rewarded Ad
  Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdReady = false;
              loadRewardedAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdReady = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  /// Show Rewarded Ad
  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      await loadRewardedAd();
      return false;
    }

    bool earned = false;

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
      },
    );

    return earned;
  }

  bool get isRewardedAdReady => _isRewardedAdReady;

  void dispose() {
    _rewardedAd?.dispose();
  }
}