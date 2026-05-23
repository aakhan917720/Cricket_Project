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
        // Wide = no ball count
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
        // No Ball = no ball count
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
        // Nothing changes
        break;

      case BallType.wicket:
        striker.balls += 1;
        striker.isOut = true;
        striker.outMode = ball.wicketMode;
        if (ball.wicketMode != 'Run Out') bowler.wicketsTaken += 1;
        bowler.oversBowled += 1;
        m.wickets[m.innings] += 1;
        m.balls[m.innings] += 1;
        m.score[m.innings] += ball.runs; // runs before wicket
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
      // Over complete
      m.currentOverBalls.clear();
      _rotateStrike(); // End of over strike rotation
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
      _saveToHistory();
    } else if (allOut || oversUp) {
      if (m.innings == 0) {
        // Start 2nd innings
        m.target = m.currentScore + 1;
        m.innings = 1;
        m.currentOverBalls.clear();
        m.strikerIdx = 0;
        m.nonStrikerIdx = 1;
        // Bowler will be selected by UI
      } else {
        // Match finished
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
        _saveToHistory();
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
    // Simple undo: remove last ball (basic implementation)
    _currentMatch!.allBalls.removeLast();
    // Note: Full undo would need to reverse all stats
    // For production, store snapshots before each ball
    notifyListeners();
  }

  // ===========================================================
  // Tournament
  // ===========================================================

  void createTournament(TournamentModel tournament) {
    _currentTournament = tournament;
    // 🔥 FIREBASE: Tournament save karo
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
