import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
