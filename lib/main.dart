import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_open_ad_manager.dart';
import 'mango_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the Google Mobile Ads SDK before showing any ads.
  await MobileAds.instance.initialize();
  // App Open ads: shows on cold start and on every foreground resume.
  AppOpenAdManager().start();
  runApp(const MangoApp());
}

class MangoApp extends StatelessWidget {
  const MangoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just a Mango',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFA000),
          brightness: Brightness.light,
        ),
      ),
      home: const MangoPage(),
    );
  }
}
