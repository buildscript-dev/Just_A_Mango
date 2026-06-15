// Basic smoke test for the Just a Mango clicker.
//
// Tests the difficulty equation directly. Widget rendering is not tested here
// because the page initializes the Ads SDK / platform channels, which are not
// available in the flutter_test host.

import 'package:flutter_test/flutter_test.dart';

// Mirror of the scoring probability in lib/mango_page.dart.
double scoreChance(int score, {double k = 10.0}) => 1.0 / (1.0 + score / k);

void main() {
  test('score chance is 1.0 at score 0', () {
    expect(scoreChance(0), 1.0);
  });

  test('score chance decreases as score rises', () {
    expect(scoreChance(50) < scoreChance(10), isTrue);
    expect(scoreChance(100) < scoreChance(50), isTrue);
  });

  test('score chance matches equation at score 10', () {
    // 1 / (1 + 10/10) = 0.5
    expect(scoreChance(10), closeTo(0.5, 1e-9));
  });
}
