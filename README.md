# 🏏 Cricket Scorer App - Flutter

## Features
- ✅ Splash Animation (Cricket Ball Spin)
- ✅ Beautiful Dashboard with Bottom Navigation
- ✅ Match Setup (Overs 1-50, Players 1-11)
- ✅ Player Photos (Camera/Gallery)
- ✅ Team Logo
- ✅ Toss Screen (Coin Flip Animation)
- ✅ 6 Ball Types (Normal, Wide, No Ball, Bye, Leg Bye, Dead Ball)
- ✅ Runs 0-6
- ✅ 6 Wicket Types
- ✅ Live Scoreboard (CRR, RRR, Target)
- ✅ Ball-by-Ball Tracker
- ✅ Scorecard Tab
- ✅ Tournament (1-50 Matches, Round Robin / Knockout)
- ✅ Points Table
- ✅ Match History
- ✅ Firebase Ready (marked with 🔥)

---

## 🔥 FIREBASE SETUP (Step by Step)

### Step 1: Firebase Console
```
1. https://console.firebase.google.com
2. "Add Project" → CricketScorer naam dein
3. Google Analytics: Optional (disable kar sakte hain)
```

### Step 2: Android App Add Karein
```
1. Console mein "Android" icon click karein
2. Package: com.example.cricket_scorer
3. App nickname: Cricket Scorer
4. google-services.json download karein
5. Is file ko → android/app/ folder mein rakhen
```

### Step 3: iOS App Add Karein
```
1. Console mein "iOS" icon click karein
2. Bundle ID: com.example.cricketScorer
3. GoogleService-Info.plist download karein
4. Is file ko → ios/Runner/ folder mein rakhen (Xcode mein drag karein)
```

### Step 4: FlutterFire CLI
```bash
# Install karein
dart pub global activate flutterfire_cli

# Project mein configure karein
flutterfire configure

# Yeh firebase_options.dart auto-generate kar dega
```

### Step 5: Android Gradle Files
```gradle
// android/build.gradle mein:
classpath 'com.google.gms:google-services:4.4.0'

// android/app/build.gradle mein (sabse neeche):
apply plugin: 'com.google.gms.google-services'
```

### Step 6: main.dart Uncomment Karein
```dart
// Yeh lines uncomment karein:
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// aur main() mein:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Step 7: firebase_service.dart Uncomment Karein
```
Har jagah jo 🔥 FIREBASE UNCOMMENT: likha hai, wahan se // hatao
```

### Step 8: Firestore Rules
```
Firebase Console → Firestore Database → Rules:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true; // Development ke liye
      // Production ke liye: if request.auth != null;
    }
  }
}
```

### Step 9: Firebase Storage Rules
```
Firebase Console → Storage → Rules:

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true; // Development ke liye
    }
  }
}
```

---

## 📦 Project Structure
```
lib/
├── main.dart                    ← App entry + 🔥 Firebase init
├── theme/
│   └── app_theme.dart           ← Colors, fonts, theme
├── models/
│   └── models.dart              ← PlayerModel, TeamModel, MatchModel, TournamentModel
├── services/
│   └── firebase_service.dart    ← 🔥 All Firebase operations
├── providers/
│   └── match_provider.dart      ← State management
└── screens/
    ├── splash_screen.dart       ← Animated splash
    ├── dashboard_screen.dart    ← Main dashboard + bottom nav
    ├── match_setup_screen.dart  ← Match configuration
    ├── toss_screen.dart         ← Coin flip toss
    ├── scoring_screen.dart      ← Live scoring
    ├── tournament_screen.dart   ← Tournament management
    └── history_screen.dart      ← Match history
```

---

## 🚀 Run Karein
```bash
flutter pub get
flutter run
```

---

## 📋 Firebase Collections (Firestore)
```
matches/
  {matchId}/
    - id, team1, team2, score, wickets, balls...
    
tournaments/
  {tournamentId}/
    - id, name, teams, schedule, pointsTable...

teams/
  {teamId}/
    - id, name, players[], logoUrl

players/ (sub-collection)
  {playerId}/
    - name, runs, balls, wickets...
```

---

## 🎨 Color Theme
- Primary: #1B5E20 (Deep Green)
- Accent: #4CAF50 (Cricket Green)
- Background: #0A1628 (Dark Navy)
- Gold: #FFD700 (Toss/Trophy)
- Card: #0D2137

---

## 🔥 Firebase Features Ready
1. ✅ Match save/load
2. ✅ Live score update (real-time)
3. ✅ Tournament save
4. ✅ Team & Player photos (Storage)
5. ✅ Match history
6. ✅ Anonymous auth
7. ✅ Email auth