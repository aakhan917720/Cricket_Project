// lib/main.dart
//
// 🔥 FIREBASE SETUP:
// 1. https://console.firebase.google.com → New Project
// 2. "flutterfire configure" command run karein project mein
// 3. firebase_options.dart auto-generate hoga
// 4. Neeche firebase_options.dart ka import uncomment karein
// 5. main() mein Firebase.initializeApp() uncomment karein

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// 🔥 FIREBASE UNCOMMENT: import 'package:firebase_core/firebase_core.dart';
// 🔥 FIREBASE UNCOMMENT: import 'firebase_options.dart';  // flutterfire configure se generate hoga

import 'theme/app_theme.dart';
import 'providers/match_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1F35),
  ));

  // Portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🔥 FIREBASE UNCOMMENT: Firebase initialize karein
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const CricketScorerApp());
}

class CricketScorerApp extends StatelessWidget {
  const CricketScorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchProvider()),
      ],
      child: MaterialApp(
        title: 'Cricket Scorer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        // Routes
        routes: {
          '/splash': (_) => const SplashScreen(),
        },
      ),
    );
  }
}
