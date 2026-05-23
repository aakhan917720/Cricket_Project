// lib/models/player_model.dart
class PlayerModel {
  String id;
  String name;
  String? photoPath;    // Local file path
  String? photoUrl;     // 🔥 FIREBASE: Firebase Storage URL
  int jerseyNumber;
  String role;          // Batsman / Bowler / All-Rounder / WK

  // Batting stats
  int runs;
  int balls;
  int fours;
  int sixes;
  bool isOut;
  String outMode;       // Bowled, Caught, LBW, Run Out, Stumped, Hit Wicket

  // Bowling stats
  int oversBowled;
  int runsGiven;
  int wicketsTaken;
  int maidenOvers;
  int wides;
  int noBalls;

  PlayerModel({
    required this.id,
    required this.name,
    this.photoPath,
    this.photoUrl,
    this.jerseyNumber = 0,
    this.role = 'Batsman',
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.outMode = '',
    this.oversBowled = 0,
    this.runsGiven = 0,
    this.wicketsTaken = 0,
    this.maidenOvers = 0,
    this.wides = 0,
    this.noBalls = 0,
  });

  double get strikeRate =>
      balls > 0 ? (runs / balls * 100) : 0.0;

  double get economy =>
      oversBowled > 0 ? (runsGiven / (oversBowled / 6)) : 0.0;

  String get oversStr {
    int full = oversBowled ~/ 6;
    int rem = oversBowled % 6;
    return '$full.$rem';
  }

  // 🔥 FIREBASE: Firestore se save/load karne ke liye
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'photoUrl': photoUrl,
    'jerseyNumber': jerseyNumber,
    'role': role,
    'runs': runs,
    'balls': balls,
    'fours': fours,
    'sixes': sixes,
    'isOut': isOut,
    'outMode': outMode,
    'oversBowled': oversBowled,
    'runsGiven': runsGiven,
    'wicketsTaken': wicketsTaken,
    'maidenOvers': maidenOvers,
    'wides': wides,
    'noBalls': noBalls,
  };

  factory PlayerModel.fromMap(Map<String, dynamic> map) => PlayerModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    photoUrl: map['photoUrl'],
    jerseyNumber: map['jerseyNumber'] ?? 0,
    role: map['role'] ?? 'Batsman',
    runs: map['runs'] ?? 0,
    balls: map['balls'] ?? 0,
    fours: map['fours'] ?? 0,
    sixes: map['sixes'] ?? 0,
    isOut: map['isOut'] ?? false,
    outMode: map['outMode'] ?? '',
    oversBowled: map['oversBowled'] ?? 0,
    runsGiven: map['runsGiven'] ?? 0,
    wicketsTaken: map['wicketsTaken'] ?? 0,
    maidenOvers: map['maidenOvers'] ?? 0,
    wides: map['wides'] ?? 0,
    noBalls: map['noBalls'] ?? 0,
  );
}

// ============================================================
// lib/models/team_model.dart
// ============================================================
class TeamModel {
  String id;
  String name;
  String? logoPath;
  String? logoUrl;      // 🔥 FIREBASE: Firebase Storage URL
  List<PlayerModel> players;
  String shortName;

  TeamModel({
    required this.id,
    required this.name,
    this.logoPath,
    this.logoUrl,
    List<PlayerModel>? players,
    String? shortName,
  })  : players = players ?? [],
        shortName = shortName ?? name.substring(0, name.length > 3 ? 3 : name.length).toUpperCase();

  // 🔥 FIREBASE: Firestore map
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'shortName': shortName,
    'players': players.map((p) => p.toMap()).toList(),
  };

  factory TeamModel.fromMap(Map<String, dynamic> map) => TeamModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    logoUrl: map['logoUrl'],
    shortName: map['shortName'] ?? '',
    players: (map['players'] as List<dynamic>? ?? [])
        .map((p) => PlayerModel.fromMap(p as Map<String, dynamic>))
        .toList(),
  );
}

// ============================================================
// lib/models/ball_model.dart
// ============================================================
enum BallType { normal, wide, noBall, bye, legBye, deadBall, wicket }

class BallModel {
  BallType type;
  int runs;
  bool isWicket;
  String wicketMode;
  int overNumber;
  int ballNumber;
  String batterId;
  String bowlerId;

  BallModel({
    required this.type,
    required this.runs,
    this.isWicket = false,
    this.wicketMode = '',
    required this.overNumber,
    required this.ballNumber,
    required this.batterId,
    required this.bowlerId,
  });

  String get displayLabel {
    if (isWicket) return 'W';
    switch (type) {
      case BallType.wide: return 'Wd';
      case BallType.noBall: return 'Nb';
      case BallType.bye: return 'By';
      case BallType.legBye: return 'LB';
      case BallType.deadBall: return 'Db';
      default: return runs == 0 ? '·' : '$runs';
    }
  }

  // 🔥 FIREBASE: Firestore map
  Map<String, dynamic> toMap() => {
    'type': type.name,
    'runs': runs,
    'isWicket': isWicket,
    'wicketMode': wicketMode,
    'overNumber': overNumber,
    'ballNumber': ballNumber,
    'batterId': batterId,
    'bowlerId': bowlerId,
  };
}

// ============================================================
// lib/models/match_model.dart
// ============================================================
class MatchModel {
  String id;
  String? tournamentId;  // 🔥 FIREBASE: Tournament ke saath link
  TeamModel team1;
  TeamModel team2;
  int totalOvers;
  int innings;           // 0 = 1st, 1 = 2nd
  int batFirstTeamIdx;   // 0 = team1, 1 = team2
  String tossWinner;
  String tossDecision;   // bat / bowl

  // Scores
  List<int> score;
  List<int> wickets;
  List<int> balls;
  List<int> extras;

  // Batting
  int strikerIdx;
  int nonStrikerIdx;
  int bowlerIdx;

  // Ball tracking
  List<BallModel> allBalls;
  List<BallModel> currentOverBalls;

  // Match result
  bool isFinished;
  String result;
  int? target;

  DateTime startTime;
  DateTime? endTime;

  MatchModel({
    required this.id,
    this.tournamentId,
    required this.team1,
    required this.team2,
    required this.totalOvers,
    this.innings = 0,
    this.batFirstTeamIdx = 0,
    this.tossWinner = '',
    this.tossDecision = 'bat',
    List<int>? score,
    List<int>? wickets,
    List<int>? balls,
    List<int>? extras,
    this.strikerIdx = 0,
    this.nonStrikerIdx = 1,
    this.bowlerIdx = 0,
    List<BallModel>? allBalls,
    List<BallModel>? currentOverBalls,
    this.isFinished = false,
    this.result = '',
    this.target,
    DateTime? startTime,
    this.endTime,
  })  : score = score ?? [0, 0],
        wickets = wickets ?? [0, 0],
        balls = balls ?? [0, 0],
        extras = extras ?? [0, 0],
        allBalls = allBalls ?? [],
        currentOverBalls = currentOverBalls ?? [],
        startTime = startTime ?? DateTime.now();

  TeamModel get battingTeam =>
      innings == 0
          ? (batFirstTeamIdx == 0 ? team1 : team2)
          : (batFirstTeamIdx == 0 ? team2 : team1);

  TeamModel get bowlingTeam =>
      innings == 0
          ? (batFirstTeamIdx == 0 ? team2 : team1)
          : (batFirstTeamIdx == 0 ? team1 : team2);

  int get currentScore => score[innings];
  int get currentWickets => wickets[innings];
  int get currentBalls => balls[innings];

  String get oversDisplay {
    int full = currentBalls ~/ 6;
    int rem = currentBalls % 6;
    return '$full.$rem';
  }

  double get currentRunRate =>
      currentBalls > 0 ? (currentScore / (currentBalls / 6)) : 0.0;

  double get requiredRunRate {
    if (innings == 0 || target == null) return 0.0;
    int needed = target! - currentScore;
    int ballsLeft = totalOvers * 6 - currentBalls;
    return ballsLeft > 0 ? (needed / (ballsLeft / 6)) : 0.0;
  }

  // 🔥 FIREBASE: Firestore save karne ke liye
  Map<String, dynamic> toMap() => {
    'id': id,
    'tournamentId': tournamentId,
    'team1': team1.toMap(),
    'team2': team2.toMap(),
    'totalOvers': totalOvers,
    'innings': innings,
    'batFirstTeamIdx': batFirstTeamIdx,
    'tossWinner': tossWinner,
    'tossDecision': tossDecision,
    'score': score,
    'wickets': wickets,
    'balls': balls,
    'extras': extras,
    'isFinished': isFinished,
    'result': result,
    'target': target,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
  };
}

// ============================================================
// lib/models/tournament_model.dart
// ============================================================
enum TournamentFormat { roundRobin, knockout, leagueAndKnockout }

class TournamentMatch {
  String team1Id;
  String team2Id;
  int matchNumber;
  String? result;
  String? winnerId;

  TournamentMatch({
    required this.team1Id,
    required this.team2Id,
    required this.matchNumber,
    this.result,
    this.winnerId,
  });

  Map<String, dynamic> toMap() => {
    'team1Id': team1Id,
    'team2Id': team2Id,
    'matchNumber': matchNumber,
    'result': result,
    'winnerId': winnerId,
  };
}

class TournamentModel {
  String id;
  String name;
  List<TeamModel> teams;
  int totalMatches;     // 1-50
  int overs;
  TournamentFormat format;
  List<TournamentMatch> schedule;
  DateTime startDate;
  bool isActive;
  String? winnerId;     // 🔥 FIREBASE: Winner team ID

  TournamentModel({
    required this.id,
    required this.name,
    required this.teams,
    required this.totalMatches,
    required this.overs,
    this.format = TournamentFormat.roundRobin,
    List<TournamentMatch>? schedule,
    DateTime? startDate,
    this.isActive = true,
    this.winnerId,
  })  : schedule = schedule ?? [],
        startDate = startDate ?? DateTime.now();

  // Points table calculation
  Map<String, Map<String, int>> get pointsTable {
    Map<String, Map<String, int>> table = {};
    for (final t in teams) {
      table[t.id] = {'played': 0, 'won': 0, 'lost': 0, 'nrr': 0, 'points': 0};
    }
    for (final m in schedule) {
      if (m.winnerId != null) {
        table[m.team1Id]!['played'] = (table[m.team1Id]!['played'] ?? 0) + 1;
        table[m.team2Id]!['played'] = (table[m.team2Id]!['played'] ?? 0) + 1;
        if (m.winnerId == m.team1Id) {
          table[m.team1Id]!['won'] = (table[m.team1Id]!['won'] ?? 0) + 1;
          table[m.team1Id]!['points'] = (table[m.team1Id]!['points'] ?? 0) + 2;
          table[m.team2Id]!['lost'] = (table[m.team2Id]!['lost'] ?? 0) + 1;
        } else {
          table[m.team2Id]!['won'] = (table[m.team2Id]!['won'] ?? 0) + 1;
          table[m.team2Id]!['points'] = (table[m.team2Id]!['points'] ?? 0) + 2;
          table[m.team1Id]!['lost'] = (table[m.team1Id]!['lost'] ?? 0) + 1;
        }
      }
    }
    return table;
  }

  // 🔥 FIREBASE: Firestore save
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'totalMatches': totalMatches,
    'overs': overs,
    'format': format.name,
    'startDate': startDate.toIso8601String(),
    'isActive': isActive,
    'winnerId': winnerId,
    'teamIds': teams.map((t) => t.id).toList(),
    'schedule': schedule.map((s) => s.toMap()).toList(),
  };
}
