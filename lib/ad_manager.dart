import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_open_ad_manager.dart';

/// Centralizes ad unit IDs and rewarded-ad handling.
///
/// Real AdMob units are used for Android. iOS still uses Google TEST ids until
/// iOS units are created. App Open ads live in [AppOpenAdManager].
class AdManager {
  // --- Ad unit IDs ---
  // BANNER: real AdMob unit (Android). iOS on test id. (Android test: 6300978111.)
  static String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3604302597495132/7665107296'
      : 'ca-app-pub-3940256099942544/2934735716';

  // REWARDED: real AdMob unit (Android). iOS on test id.
  static String get rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3604302597495132/6420603533'
      : 'ca-app-pub-3940256099942544/1712485313';

  RewardedAd? _rewarded;
  bool _isLoadingRewarded = false;

  bool get isRewardedReady => _rewarded != null;

  /// Preload a rewarded ad so the boost button can show it instantly.
  void loadRewarded() {
    if (_rewarded != null || _isLoadingRewarded) return;
    _isLoadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _isLoadingRewarded = false;
        },
        onAdFailedToLoad: (error) {
          _rewarded = null;
          _isLoadingRewarded = false;
        },
      ),
    );
  }

  /// Show the rewarded ad. [onReward] fires only if the user earns the reward
  /// (watches enough). Next ad is preloaded after dismiss.
  void showRewarded({required VoidCallback onReward}) {
    final ad = _rewarded;
    if (ad == null) return;
    // Block the App Open ad from stacking while this rewarded ad is on screen.
    AppOpenAdManager.isShowingFullScreenAd = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        AppOpenAdManager.isShowingFullScreenAd = false;
        ad.dispose();
        _rewarded = null;
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppOpenAdManager.isShowingFullScreenAd = false;
        ad.dispose();
        _rewarded = null;
        loadRewarded();
      },
    );
    ad.show(onUserEarnedReward: (ad, reward) => onReward());
    _rewarded = null;
  }

  void dispose() {
    _rewarded?.dispose();
    _rewarded = null;
  }
}
