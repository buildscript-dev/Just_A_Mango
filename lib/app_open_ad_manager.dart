import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads and shows App Open ads when the app is brought to the foreground.
///
/// Register as a [WidgetsBindingObserver] in main(). Shows on cold start (once
/// the first ad loads) and on every resume, guarded so it never stacks.
class AppOpenAdManager with WidgetsBindingObserver {
  // Real AdMob App Open unit (Android). iOS on test id until an iOS unit exists.
  static String get _adUnitId => Platform.isAndroid
      ? 'ca-app-pub-3604302597495132/4847372265'
      : 'ca-app-pub-3940256099942544/5575463023';

  /// Set by ANY fullscreen ad (rewarded, etc.) while it is on screen. Prevents
  /// the App Open ad from stacking on top of another ad — a policy violation
  /// that triggers invalid-traffic flags.
  static bool isShowingFullScreenAd = false;

  /// Minimum gap between App Open ads. Protects against over-serving on rapid
  /// resumes (also an invalid-traffic risk).
  static const Duration _minInterval = Duration(minutes: 4);

  AppOpenAd? _ad;
  bool _isShowing = false;
  bool _isLoading = false;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _load(showWhenReady: true); // cold start
  }

  void _load({bool showWhenReady = false}) {
    if (_ad != null || _isLoading) {
      if (showWhenReady) _showIfAvailable();
      return;
    }
    _isLoading = true;
    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoading = false;
          if (showWhenReady) _showIfAvailable();
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _isLoading = false;
        },
      ),
    );
  }

  void _showIfAvailable() {
    final ad = _ad;
    if (ad == null || _isShowing) return;
    // Don't stack on another ad, and respect the frequency cap.
    if (isShowingFullScreenAd) return;
    if (DateTime.now().difference(_lastShown) < _minInterval) return;

    _isShowing = true;
    isShowingFullScreenAd = true;
    _lastShown = DateTime.now();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        isShowingFullScreenAd = false;
        ad.dispose();
        _ad = null;
        _load(); // preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowing = false;
        isShowingFullScreenAd = false;
        ad.dispose();
        _ad = null;
        _load();
      },
    );
    ad.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showIfAvailable();
      if (_ad == null) _load();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ad?.dispose();
    _ad = null;
  }
}
