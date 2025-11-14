
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  LoadAdError? _lastLoadError;

  // Ad Unit IDs - Production
  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6034518904177644/7479318191'; // Your Android Rewarded Ad Unit ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6034518904177644/7479318191'; // Use same or create iOS unit
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
          _lastLoadError = error;
          print('AdMob: Failed to load rewarded ad: ${error.code} - ${error.message}');
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
  LoadAdError? get lastLoadError => _lastLoadError;

  void dispose() {
    _rewardedAd?.dispose();
  }
}