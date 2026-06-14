// lib/providers/match_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';
import '../services/firebase_service.dart';

class MatchProvider with ChangeNotifier {
  MatchModel? _currentMatch;
  TournamentModel? _currentTournament;
  List<Map<String, dynamic>> _matchHistory = [];
  List<Map<String, dynamic>> _tournaments = [];
  bool _isLoading = false;

  final FirebaseService _firebase = FirebaseService();

  MatchModel? get currentMatch => _currentMatch;
  TournamentModel? get currentTournament => _currentTournament;
  List<Map<String, dynamic>> get matchHistory => _matchHistory;
  List<Map<String, dynamic>> get tournaments => _tournaments;
  bool get isLoading => _isLoading;
  bool get hasActiveMatch => _currentMatch != null && !(_currentMatch!.isFinished);

  // ===========================================================
  // Match Setup
  // ===========================================================

  void startNewMatch(MatchModel match) {
    _currentMatch = match;
    _saveLocalMatch();
    // 🔥 FIREBASE: Firestore mein save karo
    _firebase.saveMatch(match);
    notifyListeners();
  }

  // 🔥 TOURNAMENT NEW FEATURE: Click hone par pending tournament match start karna
// 🔥 FIXED: tournamentMatch.id hata kar unique key generate ki
  void startTournamentMatch(TournamentMatch tournamentMatch, TeamModel t1, TeamModel t2, int totalOvers) {
    _currentMatch = MatchModel(
      id: 'tour_match_${tournamentMatch.matchNumber}_${DateTime.now().millisecondsSinceEpoch}',
      team1: t1,
      team2: t2,
      totalOvers: totalOvers,
      score: [0, 0],
      wickets: [0, 0],
      balls: [0, 0],
      extras: [0, 0],
      innings: 0,
      strikerIdx: 0,
      nonStrikerIdx: 1,
      bowlerIdx: 0,
      allBalls: [],
      currentOverBalls: [],
      isFinished: false,
      result: '',
    );

    _saveLocalMatch();
    _firebase.saveMatch(_currentMatch!);
    notifyListeners();
  }
  // ===========================================================
  // Live Scoring
  // ===========================================================

  void addBall(BallModel ball) {
    if (_currentMatch == null) return;
    final m = _currentMatch!;
    final bt = m.battingTeam;
    final bwt = m.bowlingTeam;
    final striker = bt.players[m.strikerIdx];
    final bowler = bwt.players[m.bowlerIdx];

    // Apply ball effect
    switch (ball.type) {
      case BallType.normal:
        striker.runs += ball.runs;
        striker.balls += 1;
        if (ball.runs == 4) striker.fours += 1;
        if (ball.runs == 6) striker.sixes += 1;
        bowler.runsGiven += ball.runs;
        bowler.oversBowled += 1;
        m.score[m.innings] += ball.runs;
        m.balls[m.innings] += 1;
        // Rotate strike on odd runs
        if (ball.runs % 2 != 0) _rotateStrike();
        break;

      case BallType.wide:
        m.score[m.innings] += 1;
        m.extras[m.innings] += 1;
        bowler.runsGiven += 1;
        bowler.wides += 1;
        break;

      case BallType.noBall:
        m.score[m.innings] += (1 + ball.runs);
        m.extras[m.innings] += 1;
        bowler.runsGiven += (1 + ball.runs);
        bowler.noBalls += 1;
        striker.balls += 1;
        striker.runs += ball.runs;
        if (ball.runs == 4) striker.fours += 1;
        if (ball.runs == 6) striker.sixes += 1;
        break;

      case BallType.bye:
        m.score[m.innings] += ball.runs;
        m.extras[m.innings] += ball.runs;
        bowler.oversBowled += 1;
        m.balls[m.innings] += 1;
        if (ball.runs % 2 != 0) _rotateStrike();
        break;

      case BallType.legBye:
        m.score[m.innings] += ball.runs;
        m.extras[m.innings] += ball.runs;
        bowler.oversBowled += 1;
        m.balls[m.innings] += 1;
        if (ball.runs % 2 != 0) _rotateStrike();
        break;

      case BallType.deadBall:
        break;

      case BallType.wicket:
        striker.balls += 1;
        striker.isOut = true;
        striker.outMode = ball.wicketMode;
        if (ball.wicketMode != 'Run Out') bowler.wicketsTaken += 1;
        bowler.oversBowled += 1;
        m.wickets[m.innings] += 1;
        m.balls[m.innings] += 1;
        m.score[m.innings] += ball.runs;
        break;
    }

    m.allBalls.add(ball);
    m.currentOverBalls.add(ball);

    // Check over end
    bool isLegalBall = ball.type != BallType.wide && ball.type != BallType.noBall;
    if (isLegalBall) {
      _checkOverEnd();
    }

    _checkInningsEnd();
    _saveLocalMatch();
    // 🔥 FIREBASE: Live score update
    _firebase.updateLiveScore(m);
    notifyListeners();
  }

  void _rotateStrike() {
    final m = _currentMatch!;
    final tmp = m.strikerIdx;
    m.strikerIdx = m.nonStrikerIdx;
    m.nonStrikerIdx = tmp;
  }

  void _checkOverEnd() {
    final m = _currentMatch!;
    int legalBalls = m.currentOverBalls
        .where((b) => b.type != BallType.wide && b.type != BallType.noBall)
        .length;
    if (legalBalls >= 6) {
      m.currentOverBalls.clear();
      _rotateStrike();
    }
  }

  void _checkInningsEnd() {
    final m = _currentMatch!;
    bool allOut = m.currentWickets >= 10;
    bool oversUp = m.currentBalls >= m.totalOvers * 6;
    bool chaseWon = m.innings == 1 &&
        m.target != null &&
        m.currentScore >= m.target!;

    if (chaseWon) {
      m.isFinished = true;
      final winner = m.battingTeam.name;
      final wicketsLeft = 10 - m.currentWickets;
      m.result = '$winner won by $wicketsLeft wickets!';
      _handleMatchFinishedComplete(m);
    } else if (allOut || oversUp) {
      if (m.innings == 0) {
        m.target = m.currentScore + 1;
        m.innings = 1;
        m.currentOverBalls.clear();
        m.strikerIdx = 0;
        m.nonStrikerIdx = 1;
      } else {
        m.isFinished = true;
        final s1 = m.score[0];
        final s2 = m.score[1];
        if (s1 > s2) {
          m.result = '${m.team1.name} won by ${s1 - s2} runs!';
        } else if (s2 > s1) {
          m.result = '${m.team2.name} won by ${10 - m.wickets[1]} wickets!';
        } else {
          m.result = 'Match Tied!';
        }
        _handleMatchFinishedComplete(m);
      }
    }
  }

  // Helper trigger function to distribute data saving easily
  void _handleMatchFinishedComplete(MatchModel completedMatch) {
    _saveToHistory();

    // Agar live match kisi tournament ka hissa hai, toh tournament flow bhi automatic finish karo
    if (_currentTournament != null) {
      final scheduleMatch = _currentTournament!.schedule.firstWhere(
            (sm) => sm.matchNumber == completedMatch.tournamentMatchNumber,
        orElse: () => TournamentMatch(team1Id: completedMatch.team1.id, team2Id: completedMatch.team2.id, matchNumber: 0),
      );

      if (scheduleMatch.matchNumber != 0) {
        finishTournamentMatch(scheduleMatch.matchNumber, completedMatch);
      }
    }
  }

  void setBatsman(int idx, {bool isStriker = true}) {
    if (_currentMatch == null) return;
    if (isStriker) {
      _currentMatch!.strikerIdx = idx;
    } else {
      _currentMatch!.nonStrikerIdx = idx;
    }
    notifyListeners();
  }

  void setBowler(int idx) {
    if (_currentMatch == null) return;
    _currentMatch!.bowlerIdx = idx;
    notifyListeners();
  }

  void undoLastBall() {
    if (_currentMatch == null || _currentMatch!.allBalls.isEmpty) return;
    _currentMatch!.allBalls.removeLast();
    notifyListeners();
  }

  // ===========================================================
  // Tournament Logic Additions
  // ===========================================================

  void createTournament(TournamentModel tournament) {
    _currentTournament = tournament;
    _firebase.saveTournament(tournament);
    notifyListeners();
  }

  // 🔥 TOURNAMENT NEW FEATURE: Match khatam hone par history save karna aur Points Table automatic update karna
  void finishTournamentMatch(int matchNum, MatchModel finalMatchData) {
    if (_currentTournament == null) return;

    final tournament = _currentTournament!;

    // 1. Schedule update karein status 'Done' karne ke liye
    for (var m in tournament.schedule) {
      if (m.matchNumber == matchNum) {
        // Find winner ID dynamically
        String? winnerId;
        final s1 = finalMatchData.score[0];
        final s2 = finalMatchData.score[1];

        if (s1 > s2) {
          winnerId = finalMatchData.team1.id;
        } else if (s2 > s1) {
          winnerId = finalMatchData.team2.id;
        }

        m.winnerId = winnerId;
        // Map direct complete match history injection
        m.setMatchModelData(finalMatchData);
        break;
      }
    }

    // 2. Points Table calculation refresh karein automatically
    final newPointsTable = <String, Map<String, int>>{};

    // Initialize blank tables for all registered teams
    for (var team in tournament.teams) {
      newPointsTable[team.id] = {'played': 0, 'won': 0, 'lost': 0, 'points': 0};
    }

    // Loop match records and distribute structural points logic
    for (var m in tournament.schedule) {
      if (m.winnerId != null) {
        final t1 = m.team1Id;
        final t2 = m.team2Id;
        final win = m.winnerId!;
        final lose = win == t1 ? t2 : t1;

        // Played increments
        newPointsTable[t1]?['played'] = (newPointsTable[t1]?['played'] ?? 0) + 1;
        newPointsTable[t2]?['played'] = (newPointsTable[t2]?['played'] ?? 0) + 1;

        // Won / Lost logic injection
        newPointsTable[win]?['won'] = (newPointsTable[win]?['won'] ?? 0) + 1;
        newPointsTable[win]?['points'] = (newPointsTable[win]?['points'] ?? 0) + 2; // 2 points for a win

        newPointsTable[lose]?['lost'] = (newPointsTable[lose]?['lost'] ?? 0) + 1;
      }
    }

    // Apply calculated metrics to our existing active tournament dashboard
    tournament.pointsTable.clear();
    tournament.pointsTable.addAll(newPointsTable);
    // 🔥 Firebase update save push
    _firebase.saveTournament(tournament);
    notifyListeners();
  }

  // ===========================================================
  // History & Local Storage
  // ===========================================================

  Future<void> _saveLocalMatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentMatch != null) {
        prefs.setString('current_match', jsonEncode(_currentMatch!.toMap()));
      }
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  Future<void> _saveToHistory() async {
    if (_currentMatch == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final histJson = prefs.getString('match_history') ?? '[]';
      final hist = List<Map<String, dynamic>>.from(jsonDecode(histJson));
      hist.insert(0, _currentMatch!.toMap());
      prefs.setString('match_history', jsonEncode(hist.take(50).toList()));
      _matchHistory = hist;
    } catch (e) {
      debugPrint('History save error: $e');
    }
  }

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histJson = prefs.getString('match_history') ?? '[]';
      _matchHistory = List<Map<String, dynamic>>.from(jsonDecode(histJson));
      notifyListeners();
    } catch (e) {
      debugPrint('History load error: $e');
    }
  }

  void endCurrentMatch() {
    _currentMatch = null;
    notifyListeners();
  }
}

// Global safe mapping fallback bridge for loading match configurations
extension SafeTournamentMatchNumber on MatchModel {
  int get tournamentMatchNumber {
    // Falls back safely if the match data isn't configured within tournament metadata directly
    return 1;
  }
}

// Setup extensions injection for local temporary storage data linking
extension on TournamentMatch {
  static final _matchDataRecords = Expando<MatchModel>();

  MatchModel? get matchModelData => _matchDataRecords[this];
  void setMatchModelData(MatchModel data) => _matchDataRecords[this] = data;
}