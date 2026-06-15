# Just a Mango — Design Spec

**Date:** 2026-06-15
**App name:** Just a Mango
**Package:** `just_a_mango`
**Stack:** Flutter (3.44.1, Dart 3.12.1)
**Platform:** Mobile (Android primary)

## Purpose

A bare tap-clicker game. User taps a big mango button to raise a score. Scoring
gets progressively harder via a difficulty equation. Monetized with ads (banner
+ spaced interstitials). No redeem / no real-money payout in this build.

## Screen Layout

Single screen, top-to-bottom:

1. **Score display** — large, readable number at top. `Score: N`.
2. **Mango button** — big centered tappable area. Mango via 🥭 emoji (no image
   assets, scales clean). Tap target fills most of the vertical space.
3. **Banner ad** — `google_mobile_ads` banner anchored directly below the mango
   button (standard adaptive/`AdSize.banner`). Always visible.

## Tap Behavior

On each tap of the mango button:

- Fire `HapticFeedback.heavyImpact` (strong haptic) — **every** tap.
- Play juicy squish animation (scale down→up) — **every** tap, regardless of
  whether the tap scored.
- Roll the difficulty equation to decide if score increments.

## Difficulty Equation

Probability a tap increments score:

```
P(score) = 1 / (1 + score / k)
```

- `k = 10` (tunable compile-time constant).
- `score = 0` → P = 1.0 (every tap counts).
- As score rises, P falls → more taps needed per point.

Expected taps to reach a target score `S` ≈ `S + S(S-1)/(2k)`:

| Target | ~Taps (k=10) |
|--------|--------------|
| 50     | ~172         |
| 100    | ~595         |
| 500    | ~12,975      |

Implementation: on tap, draw `r = Random.nextDouble()`. If `r < P(currentScore)`,
increment score; else no-op (haptic + animation still fire).

## Ads

Package: `google_mobile_ads`. Use **Google official test ad unit IDs** so the app
builds and runs without an AdMob account. Real IDs swap in later with no code
change beyond the ID constants.

### Banner

- Anchored below mango button. Loads on screen init. Standard banner size.
- Test unit ID: `ca-app-pub-3940256099942544/6300978111` (Android banner test).

### Interstitial (policy-safe — NEVER per click)

- First interstitial allowed only after score reaches **10**.
- After that, gated by BOTH:
  - **Score interval:** every `adInterval = 10` points since last shown.
  - **Time cooldown:** minimum `adCooldownSeconds = 60` since last shown.
- Both conditions must pass → show. Prevents AdMob frequency-policy violation /
  account suspension.
- Test unit ID: `ca-app-pub-3940256099942544/1033173712` (Android interstitial test).
- AdMob app ID (test) in `AndroidManifest.xml`:
  `ca-app-pub-3940256099942544~3347511713`.

## State & Persistence

- Single `StatefulWidget` page. State: `int _score`, ad controllers, last-ad
  tracking (`int _lastAdScore`, `DateTime _lastAdTime`).
- `shared_preferences` persists `_score` across app restarts. Load on init, save
  on each successful increment.

## Theme

- Warm mango gradient background (orange→yellow).
- Large bold score font, high contrast.

## File Structure

| File | Responsibility |
|------|----------------|
| `lib/main.dart` | App root, theme, AdMob init (`MobileAds.instance.initialize()`). |
| `lib/mango_page.dart` | Screen, tap logic, difficulty equation, score persistence, layout (score / button / banner). |
| `lib/ad_manager.dart` | Banner + interstitial load/show, cooldown + interval gating. |
| `pubspec.yaml` | Deps: `google_mobile_ads`, `shared_preferences`. |
| `android/app/src/main/AndroidManifest.xml` | AdMob app ID meta-data, INTERNET permission. |

## Out of Scope (this build)

- Redeem section / real or fake cash rewards.
- Upgrades, auto-clickers, prestige.
- iOS-specific ad config (Android-first; structure stays portable).
- Real AdMob account / production ad unit IDs.

## Tunable Constants (one place, top of relevant file)

| Const | Default | Meaning |
|-------|---------|---------|
| `k` | 10 | Difficulty steepness (higher = easier). |
| `adInterval` | 10 | Points between interstitials. |
| `adCooldownSeconds` | 60 | Min seconds between interstitials. |
| `firstAdScore` | 10 | Score that unlocks first interstitial. |
