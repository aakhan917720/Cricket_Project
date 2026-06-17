// lib/providers/match_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import '../models/models.dart';

class MatchProvider with ChangeNotifier {
  MatchModel? _currentMatch;
  TournamentModel? _currentTournament;
  List<MatchModel> _matchHistory = [];
  List<TournamentModel> _tournaments = [];
  bool _isLoading = false;
  bool showInningsBreakAnimation = false;

  // 🔥 CONSTRUCTOR: App chalte hi sara data background mein load karega
  MatchProvider() {
    loadAllSavedData();
  }

  MatchModel? get currentMatch => _currentMatch;
  TournamentModel? get currentTournament => _currentTournament;
  List<MatchModel> get matchHistory => _matchHistory;
  List<TournamentModel> get tournaments => _tournaments;
  bool get isLoading => _isLoading;
  bool get hasActiveMatch => _currentMatch != null && !(_currentMatch!.isFinished);

  // ===========================================================
  // 🔄 UI/Screen Backward Compatibility Methods (Errors Fix)
  // ===========================================================

  // Fixes: dashboard_screen.dart error
  Future<void> loadHistory() async {
    await loadAllSavedData();
  }

  // Fixes: history_screen.dart error
  void setCurrentTournament(TournamentModel tournament) {
    _currentTournament = tournament;
    _saveTournamentsToLocal();
    notifyListeners();
  }

  // Fixes: Match deletion error
  void deleteMatch(String matchId) {
    _matchHistory.removeWhere((m) => m.id == matchId);

    // Direct Cloud Realtime Database se delete karein
    FirebaseDatabase.instance.ref().child('matches').child(matchId).remove();

    _saveLocalMatch();
    notifyListeners();
  }

  // ===========================================================
  // Match Setup & Live Scoring Logic
  // ===========================================================

  void startNewMatch(MatchModel match) {
    _currentMatch = match;
    _saveLocalMatch();
    notifyListeners();
  }

  void startTournamentMatch(TournamentMatch tournamentMatch, TeamModel t1, TeamModel t2, int totalOvers) {
    if (t1.players.isEmpty) {
      t1.players = List.generate(11, (index) => PlayerModel(id: 't1_p_$index', name: '${t1.name} Bat ${index + 1}'));
    }
    if (t2.players.isEmpty) {
      t2.players = List.generate(11, (index) => PlayerModel(id: 't2_p_$index', name: '${t2.name} Bowl ${index + 1}'));
    }

    if (tournamentMatch.matchDetails != null && tournamentMatch.matchStatus == 'live') {
      _currentMatch = tournamentMatch.matchDetails;
    } else {
      _currentMatch = MatchModel(
        id: tournamentMatch.matchId,
        tournamentId: _currentTournament?.id,
        team1: t1,
        team2: t2,
        totalOvers: totalOvers,
        ballsPerOver: _currentTournament?.ballsPerOver ?? 6,
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
      tournamentMatch.matchStatus = 'live';
      tournamentMatch.matchDetails = _currentMatch;
    }

    if (_currentTournament != null) {
      _saveTournamentsToLocal();
    }

    _saveLocalMatch();
    notifyListeners();
  }

  void addBall(BallModel ball) {
    if (_currentMatch == null) return;
    final m = _currentMatch!;
    final bt = m.battingTeam;
    final bwt = m.bowlingTeam;
    final striker = bt.players[m.strikerIdx];
    final bowler = bwt.players[m.bowlerIdx];

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
        break;
      case BallType.bye:
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

    if (ball.type != BallType.wide && ball.type != BallType.noBall) {
      _checkOverEnd();
    }

    _checkInningsEnd();

    if (_currentTournament != null) {
      final index = _currentTournament!.schedule.indexWhere((sm) => sm.matchId == m.id);
      if (index != -1) {
        _currentTournament!.schedule[index].matchDetails = m;
      }
      _saveTournamentsToLocal();
      // ☁️ Live scoring data sync to tournament node
      FirebaseDatabase.instance.ref().child('tournaments').child(_currentTournament!.id).set(_currentTournament!.toMap());
    }

    _saveLocalMatch();
    notifyListeners();
  }

  void _rotateStrike() {
    if (_currentMatch == null) return;
    final m = _currentMatch!;
    final tmp = m.strikerIdx;
    m.strikerIdx = m.nonStrikerIdx;
    m.nonStrikerIdx = tmp;
  }

  void _checkOverEnd() {
    if (_currentMatch == null) return;
    final m = _currentMatch!;
    int legalBalls = m.currentOverBalls.where((b) => b.type != BallType.wide && b.type != BallType.noBall).length;
    if (legalBalls >= m.ballsPerOver) {
      m.currentOverBalls.clear();
      _rotateStrike();
    }
  }

  void _checkInningsEnd() {
    if (_currentMatch == null) return;
    final m = _currentMatch!;
    bool allOut = m.currentWickets >= 10;
    bool oversUp = m.currentBalls >= (m.totalOvers * m.ballsPerOver);
    bool chaseWon = m.innings == 1 && m.target != null && m.currentScore >= m.target!;

    if (chaseWon) {
      m.isFinished = true;
      m.result = '${m.battingTeam.name} won by ${10 - m.currentWickets} wickets!';
      _handleMatchFinishedComplete(m);
    } else if (allOut || oversUp) {
      if (m.innings == 0) {
        m.target = m.currentScore + 1;
        m.innings = 1;
        m.currentOverBalls.clear();
        m.strikerIdx = 0;
        m.nonStrikerIdx = 1;
        showInningsBreakAnimation = true;
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

  void dismissInningsAnimation() {
    showInningsBreakAnimation = false;
    notifyListeners();
  }

  void _handleMatchFinishedComplete(MatchModel completedMatch) {
    _saveToHistory(completedMatch);
    if (_currentTournament != null) {
      finishTournamentMatch(completedMatch.id, completedMatch);
    }
  }

  // ===========================================================
  // 🔥 STRIKER / NON-STRIKER CHANGE LOGIC
  // ===========================================================
  void setBatsman(int playerIndex, bool isStriker) {
    if (_currentMatch == null) return;

    if (isStriker) {
      _currentMatch!.strikerIdx = playerIndex;
    } else {
      _currentMatch!.nonStrikerIdx = playerIndex;
    }

    // Live State Save aur Cloud Sync
    _saveLocalMatch();
    if (_currentMatch!.tournamentId != null && _currentTournament != null) {
      final index = _currentTournament!.schedule.indexWhere((sm) => sm.matchId == _currentMatch!.id);
      if (index != -1) {
        _currentTournament!.schedule[index].matchDetails = _currentMatch;
      }
      _saveTournamentsToLocal();
      // ☁️ Firebase Sync for live index change
      FirebaseDatabase.instance.ref().child('tournaments').child(_currentTournament!.id).set(_currentTournament!.toMap());
    }
    notifyListeners();
  }

  // ===========================================================
  // 🔥 BOWLER CHANGE LOGIC
  // ===========================================================
  void setBowler(int playerIndex) {
    if (_currentMatch == null) return;

    _currentMatch!.bowlerIdx = playerIndex;

    // Live State Save aur Cloud Sync
    _saveLocalMatch();
    if (_currentMatch!.tournamentId != null && _currentTournament != null) {
      final index = _currentTournament!.schedule.indexWhere((sm) => sm.matchId == _currentMatch!.id);
      if (index != -1) {
        _currentTournament!.schedule[index].matchDetails = _currentMatch;
      }
      _saveTournamentsToLocal();
      // ☁️ Firebase Sync for live index change
      FirebaseDatabase.instance.ref().child('tournaments').child(_currentTournament!.id).set(_currentTournament!.toMap());
    }
    notifyListeners();
  }

  // ===========================================================
  // 🔥 UNDO LAST BALL LOGIC (Mukammal Reversal)
  // ===========================================================
  void undoLastBall() {
    if (_currentMatch == null || _currentMatch!.allBalls.isEmpty) return;

    final m = _currentMatch!;
    // Aakhri ball nikalen
    final lastBall = m.allBalls.removeLast();

    // Current over list se bhi nikalen agar over abhi chal raha tha
    if (m.currentOverBalls.isNotEmpty) {
      m.currentOverBalls.removeLast();
    }

    final bt = m.battingTeam;
    final bwt = m.bowlingTeam;
    final striker = bt.players[m.strikerIdx];
    final bowler = bwt.players[m.bowlerIdx];

    // Stats ko wapas reverse (minus) karein
    switch (lastBall.type) {
      case BallType.normal:
        striker.runs -= lastBall.runs;
        striker.balls -= 1;
        if (lastBall.runs == 4) striker.fours -= 1;
        if (lastBall.runs == 6) striker.sixes -= 1;
        bowler.runsGiven -= lastBall.runs;
        bowler.oversBowled -= 1;
        m.score[m.innings] -= lastBall.runs;
        m.balls[m.innings] -= 1;
        if (lastBall.runs % 2 != 0) _rotateStrike();
        break;

      case BallType.wide:
        m.score[m.innings] -= 1;
        m.extras[m.innings] -= 1;
        bowler.runsGiven -= 1;
        bowler.wides -= 1;
        break;

      case BallType.noBall:
        m.score[m.innings] -= (1 + lastBall.runs);
        m.extras[m.innings] -= 1;
        bowler.runsGiven -= (1 + lastBall.runs);
        bowler.noBalls -= 1;
        striker.balls -= 1;
        striker.runs -= lastBall.runs;
        break;

      case BallType.bye:
      case BallType.legBye:
        m.score[m.innings] -= lastBall.runs;
        m.extras[m.innings] -= lastBall.runs;
        bowler.oversBowled -= 1;
        m.balls[m.innings] -= 1;
        if (lastBall.runs % 2 != 0) _rotateStrike();
        break;

      case BallType.deadBall:
        break;

      case BallType.wicket:
        striker.balls -= 1;
        striker.isOut = false;
        striker.outMode = "";
        if (lastBall.wicketMode != 'Run Out') bowler.wicketsTaken -= 1;
        bowler.oversBowled -= 1;
        m.wickets[m.innings] -= 1;
        m.balls[m.innings] -= 1;
        m.score[m.innings] -= lastBall.runs;
        break;
    }

    // Schedule update aur Local storage sync
    if (_currentTournament != null) {
      final index = _currentTournament!.schedule.indexWhere((sm) => sm.matchId == m.id);
      if (index != -1) {
        _currentTournament!.schedule[index].matchDetails = m;
      }
      _saveTournamentsToLocal();
      // ☁️ Firebase Sync for Undo Operation
      FirebaseDatabase.instance.ref().child('tournaments').child(_currentTournament!.id).set(_currentTournament!.toMap());
    }

    _saveLocalMatch();
    notifyListeners();
  }

  // ===========================================================
  // Tournament Operations (Local + Firebase Sync)
  // ===========================================================

  void createTournament(TournamentModel tournament) {
    _currentTournament = tournament;
    if (!_tournaments.any((t) => t.id == tournament.id)) {
      _tournaments.insert(0, tournament);
    }
    _saveTournamentsToLocal();

    // ☁️ Direct Firebase Sync
    FirebaseDatabase.instance.ref().child('tournaments').child(tournament.id).set(tournament.toMap());
    notifyListeners();
  }

  void updateTournamentName(String tournamentId, String newName) {
    final index = _tournaments.indexWhere((t) => t.id == tournamentId);
    if (index != -1) {
      _tournaments[index].name = newName;
      if (_currentTournament?.id == tournamentId) {
        _currentTournament!.name = newName;
      }
      _saveTournamentsToLocal();

      // ☁️ Cloud updates
      FirebaseDatabase.instance.ref().child('tournaments').child(tournamentId).update({
        'name': newName,
      });
      notifyListeners();
    }
  }

  void deleteTournament(String tournamentId) {
    _tournaments.removeWhere((t) => t.id == tournamentId);
    if (_currentTournament?.id == tournamentId) {
      _currentTournament = _tournaments.isNotEmpty ? _tournaments.first : null;
    }
    _saveTournamentsToLocal();

    // ☁️ Cloud delete
    FirebaseDatabase.instance.ref().child('tournaments').child(tournamentId).remove();
    notifyListeners();
  }

  void finishTournamentMatch(String matchId, MatchModel finalMatchData) {
    if (_currentTournament == null) return;
    final tournament = _currentTournament!;

    for (var m in tournament.schedule) {
      if (m.matchId == matchId) {
        String? winnerId;
        final s1 = finalMatchData.score[0];
        final s2 = finalMatchData.score[1];

        if (s1 > s2) winnerId = finalMatchData.team1.id;
        if (s2 > s1) winnerId = finalMatchData.team2.id;

        m.winnerId = winnerId;
        m.result = finalMatchData.result;
        m.matchStatus = 'completed';
        m.matchDetails = finalMatchData;
        break;
      }
    }

    // Points Table Calculation
    final newPointsTable = <String, Map<String, int>>{};
    for (var team in tournament.teams) {
      newPointsTable[team.id] = {'played': 0, 'won': 0, 'lost': 0, 'points': 0};
    }

    for (var m in tournament.schedule) {
      if (m.matchStatus == 'completed' && m.winnerId != null) {
        final t1 = m.team1Id;
        final t2 = m.team2Id;
        final win = m.winnerId!;
        final lose = win == t1 ? t2 : t1;

        newPointsTable[t1]?['played'] = (newPointsTable[t1]?['played'] ?? 0) + 1;
        newPointsTable[t2]?['played'] = (newPointsTable[t2]?['played'] ?? 0) + 1;
        newPointsTable[win]?['won'] = (newPointsTable[win]?['won'] ?? 0) + 1;
        newPointsTable[win]?['points'] = (newPointsTable[win]?['points'] ?? 0) + 2;
        newPointsTable[lose]?['lost'] = (newPointsTable[lose]?['lost'] ?? 0) + 1;
      }
    }

    tournament.pointsTable.clear();
    tournament.pointsTable.addAll(newPointsTable);

    final tIdx = _tournaments.indexWhere((t) => t.id == tournament.id);
    if (tIdx != -1) {
      _tournaments[tIdx] = tournament;
    }

    _saveTournamentsToLocal();

    // ☁️ Cloud sync full updated state
    FirebaseDatabase.instance.ref().child('tournaments').child(tournament.id).set(tournament.toMap());
    notifyListeners();
  }

  // ===========================================================
  // 💾 Storage Management (Local Storage + Cloud Recovery)
  // ===========================================================

  Future<void> _saveLocalMatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentMatch != null) {
        await prefs.setString('current_match', jsonEncode(_currentMatch!.toMap()));
      } else {
        await prefs.remove('current_match');
      }
    } catch (_) {}
  }

  Future<void> _saveToHistory(MatchModel completedMatch) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_matchHistory.any((m) => m.id == completedMatch.id)) {
        _matchHistory.insert(0, completedMatch);
      }
      final list = _matchHistory.map((m) => m.toMap()).toList();
      await prefs.setString('match_history', jsonEncode(list.take(50).toList()));

      // Cloud database history sync
      FirebaseDatabase.instance.ref().child('matches').child(completedMatch.id).set(completedMatch.toMap());
    } catch (_) {}
  }

  Future<void> _saveTournamentsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _tournaments.map((t) => t.toMap()).toList();
      await prefs.setString('local_tournaments', jsonEncode(list));

      if (_currentTournament != null) {
        await prefs.setString('current_tournament_id', _currentTournament!.id);
      } else {
        await prefs.remove('current_tournament_id');
      }
    } catch (_) {}
  }

  Future<void> loadAllSavedData() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. First read local cache for rapid load
      final tourJson = prefs.getString('local_tournaments');
      if (tourJson != null && tourJson.isNotEmpty) {
        final List<dynamic> decodedTour = jsonDecode(tourJson);
        _tournaments = decodedTour.map((item) => TournamentModel.fromMap(item)).toList();
      }

      // 2. ☁️ Live Cloud Fetch (Realtime database over-rides local cache if internet available)
      final snapshot = await FirebaseDatabase.instance.ref().child('tournaments').get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> cloudData = snapshot.value as Map<dynamic, dynamic>;
        List<TournamentModel> tempTournaments = [];

        cloudData.forEach((key, value) {
          final Map<String, dynamic> tourMap = Map<String, dynamic>.from(value as Map);
          tempTournaments.add(TournamentModel.fromMap(tourMap));
        });

        _tournaments = tempTournaments.reversed.toList();
        // Sync back to local storage
        final list = _tournaments.map((t) => t.toMap()).toList();
        await prefs.setString('local_tournaments', jsonEncode(list));
      }

      // 3. Restore History & Match States
      final histJson = prefs.getString('match_history');
      if (histJson != null && histJson.isNotEmpty) {
        final List<dynamic> decodedHist = jsonDecode(histJson);
        _matchHistory = decodedHist.map((item) => MatchModel.fromMap(item)).toList();
      }

      final activeTourId = prefs.getString('current_tournament_id');
      if (activeTourId != null && _tournaments.isNotEmpty) {
        _currentTournament = _tournaments.firstWhere((t) => t.id == activeTourId, orElse: () => _tournaments.first);
      } else if (_tournaments.isNotEmpty) {
        _currentTournament = _tournaments.first;
      }

      final currentMatchJson = prefs.getString('current_match');
      if (currentMatchJson != null && currentMatchJson.isNotEmpty) {
        _currentMatch = MatchModel.fromMap(jsonDecode(currentMatchJson));
      }

    } catch (e) {
      print("Data sync error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void endCurrentMatch() {
    _currentMatch = null;
    _saveLocalMatch();
    notifyListeners();
  }
}