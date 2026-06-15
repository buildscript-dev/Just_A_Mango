import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reward tiers. Unlocked when score >= [scoreNeeded].
class RewardTier {
  const RewardTier({required this.scoreNeeded, required this.rupees});
  final int scoreNeeded;
  final int rupees;

  String get claimedKey => 'redeem_claimed_$scoreNeeded';
}

const List<RewardTier> kRewardTiers = [
  RewardTier(scoreNeeded: 500, rupees: 500),
  RewardTier(scoreNeeded: 1000, rupees: 1000),
];

/// Redeem screen reached by long-pressing the score on the main page.
///
/// IMPORTANT: This screen only RECORDS a claim locally and shows a confirmation.
/// It does NOT transfer real money. Wiring an actual payout rail (UPI/KYC/fraud
/// defense) is out of scope and must be added before promising real cash.
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
          'Your claim for Rs. ${tier.rupees} is recorded.\n\n'
          '(Demo: no real money is transferred yet.)',
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
                    'Rs. ${tier.rupees}',
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
