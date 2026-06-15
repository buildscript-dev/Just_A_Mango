import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reward tiers. Unlocked when score >= [scoreNeeded].
///
/// Rewards are in-game **Mango Coins** only — a cosmetic gameplay reward. They
/// are NOT real money and are NOT convertible to cash, so the app stays clear
/// of "cash convertible rewards / play-to-earn" classification.
class RewardTier {
  const RewardTier({required this.scoreNeeded, required this.coins});
  final int scoreNeeded;
  final int coins;

  String get claimedKey => 'redeem_claimed_$scoreNeeded';
}

const List<RewardTier> kRewardTiers = [
  RewardTier(scoreNeeded: 500, coins: 500),
  RewardTier(scoreNeeded: 1000, coins: 1000),
];

/// Redeem screen reached by long-pressing the score on the main page.
///
/// Rewards are in-game **Mango Coins** only — purely cosmetic. No real money,
/// no cash conversion, no payout. The claim is recorded locally for gameplay.
class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key, required this.score});

  final int score;

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final Set<int> _claimed = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final tier in kRewardTiers) {
        if (prefs.getBool(tier.claimedKey) ?? false) {
          _claimed.add(tier.scoreNeeded);
        }
      }
      _loaded = true;
    });
  }

  Future<void> _claim(RewardTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(tier.claimedKey, true);
    setState(() => _claimed.add(tier.scoreNeeded));
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reward claimed 🥭'),
        content: Text(
          'You unlocked ${tier.coins} Mango Coins!\n\n'
          'Mango Coins are an in-game reward only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem'),
        backgroundColor: const Color(0xFFFF8F00),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your score: ${widget.score}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mango Coins are an in-game reward — not real money.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 20),
                if (_loaded)
                  ...kRewardTiers.map(_buildTierCard)
                else
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(RewardTier tier) {
    final unlocked = widget.score >= tier.scoreNeeded;
    final claimed = _claimed.contains(tier.scoreNeeded);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tier.coins} 🥭 Coins',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text('Reach score ${tier.scoreNeeded}'),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: (unlocked && !claimed) ? () => _claim(tier) : null,
              child: Text(
                claimed
                    ? 'Claimed'
                    : unlocked
                        ? 'Redeem'
                        : 'Locked',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
