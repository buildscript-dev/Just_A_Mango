# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Play Core (deferred components / split install referenced by Flutter)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
