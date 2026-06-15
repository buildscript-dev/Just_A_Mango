import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_manager.dart';
import 'redeem_page.dart';

/// Difficulty steepness. Higher = easier (more taps count). Scoring chance is
/// P(score) = 1 / (1 + score / kDifficulty).
const double kDifficulty = 10.0;

/// Score granted when the user finishes a rewarded ad.
const int kRewardBoost = 50;

const String _kScoreKey = 'mango_score';

class MangoPage extends StatefulWidget {
  const MangoPage({super.key});

  @override
  State<MangoPage> createState() => _MangoPageState();
}

class _MangoPageState extends State<MangoPage>
    with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  final AdManager _ads = AdManager();

  int _score = 0;
  bool _loaded = false;

  late final AnimationController _squishController;
  late final Animation<double> _squish;

  BannerAd? _banner;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    // Scale 1.0 -> 0.85 -> 1.0 squish on each tap.
    _squish = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _squishController, curve: Curves.easeOut),
    );
    _restoreScore();
    _ads.loadRewarded();
    // Adaptive banner needs screen width — load after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
  }

  Future<void> _restoreScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _score = prefs.getInt(_kScoreKey) ?? 0;
      _loaded = true;
    });
  }

  Future<void> _persistScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kScoreKey, _score);
  }

  Future<void> _loadBanner() async {
    if (!mounted) return;
    final width = MediaQuery.of(context).size.width.truncate();
    // Adaptive anchored banner: best fill / eCPM for the available width.
    final AdSize size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
              Orientation.portrait,
              width,
            ) ??
            AdSize.banner;

    final banner = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _bannerReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _bannerReady = false);
        },
      ),
    );
    _banner = banner;
    banner.load();
  }

  /// Probability a tap increments the score at the current score.
  double _scoreChance() => 1.0 / (1.0 + _score / kDifficulty);

  Future<void> _onTap() async {
    // Haptic + animation fire on EVERY tap, scored or not, for responsiveness.
    HapticFeedback.heavyImpact();
    _squishController.forward().then((_) => _squishController.reverse());

    final scored = _rng.nextDouble() < _scoreChance();
    if (!scored) return;

    setState(() => _score++);
    await _persistScore();
  }

  void _watchAdForBoost() {
    if (!_ads.isRewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready yet — try again shortly.')),
      );
      _ads.loadRewarded();
      return;
    }
    _ads.showRewarded(onReward: () async {
      setState(() => _score += kRewardBoost);
      await _persistScore();
    });
  }

  void _openRedeem() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RedeemPage(score: _score),
      ),
    );
  }

  @override
  void dispose() {
    _squishController.dispose();
    _banner?.dispose();
    _ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                // Long-press the score to open the redeem section.
                onLongPress: _openRedeem,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    Text(
                      'Score',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                    ),
                    Text(
                      _loaded ? '$_score' : '—',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 72,
                          ),
                    ),
                    Text(
                      'hold to redeem',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _onTap,
                    child: ScaleTransition(
                      scale: _squish,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          // Soft mango-cream button surface.
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
                          ),
                          borderRadius: BorderRadius.circular(48),
                          border: Border.all(
                            color: const Color(0xFFE65100),
                            width: 4,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '🥭',
                            style: TextStyle(fontSize: 140),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Rewarded-ad boost: opt-in, highest-paying, policy-safe.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: _watchAdForBoost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text(
                    'Watch ad  →  +$kRewardBoost',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              // Banner ad anchored directly below the mango button.
              if (_bannerReady && _banner != null)
                SizedBox(
                  width: _banner!.size.width.toDouble(),
                  height: _banner!.size.height.toDouble(),
                  child: AdWidget(ad: _banner!),
                )
              else
                const SizedBox(height: 50),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
