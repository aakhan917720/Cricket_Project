enum BallType { normal, wide, noBall, bye, legBye, deadBall, wicket }
enum TournamentFormat { roundRobin, knockout, leagueAndKnockout }

// ============================================================
// 1. BALL MODEL
// ============================================================
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

  factory BallModel.fromMap(Map<String, dynamic> map) => BallModel(
    type: BallType.values.byName(map['type'] ?? 'normal'),
    runs: map['runs'] ?? 0,
    isWicket: map['isWicket'] ?? false,
    wicketMode: map['wicketMode'] ?? '',
    overNumber: map['overNumber'] ?? 0,
    ballNumber: map['ballNumber'] ?? 0,
    batterId: map['batterId'] ?? '',
    bowlerId: map['bowlerId'] ?? '',
  );
}

// ============================================================
// 2. PLAYER MODEL
// ============================================================
class PlayerModel {
  String id;
  String name;
  String? photoPath;
  String? photoUrl;
  int jerseyNumber;
  String role;

  int runs;
  int balls;
  int fours;
  int sixes;
  bool isOut;
  String outMode;

  int oversBowled; // Total valid balls bowled stored internally
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'photoPath': photoPath,
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
    photoPath: map['photoPath'],
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

  double get strikeRate => balls > 0 ? (runs / balls * 100) : 0.0;

  // 🔥 Fixed: Ab economy dynamic config per ball calculation karegi (Default ko 6 rakha hai fallback ke liye)
  double dynamicEconomy(int ballsPerOver) {
    return oversBowled > 0 ? (runsGiven / (oversBowled / ballsPerOver)) : 0.0;
  }

  double get economy => dynamicEconomy(6);

  // 🔥 Fixed: Over string breakdown dynamic balls ke mutabiq hoga
  String dynamicOversStr(int ballsPerOver) {
    int full = oversBowled ~/ ballsPerOver;
    int rem = oversBowled % ballsPerOver;
    return '$full.$rem';
  }

  String get oversStr => dynamicOversStr(6);
}

// ============================================================
// 3. TEAM MODEL
// ============================================================
class TeamModel {
  String id;
  String name;
  String? logoPath;
  String? logoUrl;
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
        shortName = shortName ?? (name.length > 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase());

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'logoPath': logoPath,
    'logoUrl': logoUrl,
    'shortName': shortName,
    'players': players.map((p) => p.toMap()).toList(),
  };

  factory TeamModel.fromMap(Map<String, dynamic> map) => TeamModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    logoPath: map['logoPath'],
    logoUrl: map['logoUrl'],
    shortName: map['shortName'] ?? '',
    players: (map['players'] as List<dynamic>? ?? [])
        .map((p) => PlayerModel.fromMap(p as Map<String, dynamic>))
        .toList(),
  );
}

// ============================================================
// 4. MAIN MATCH MODEL
// ============================================================
class MatchModel {
  String id;
  String? tournamentId;
  String venue;
  TeamModel team1;
  TeamModel team2;
  int totalOvers;
  int ballsPerOver;           // 🔥 Added: Match engine me track karne ke liye
  int innings;
  int batFirstTeamIdx;
  String tossWinner;
  String tossDecision;

  List<int> score;
  List<int> wickets;
  List<int> balls;
  List<int> extras;

  int strikerIdx;
  int nonStrikerIdx;
  int bowlerIdx;

  List<BallModel> allBalls;
  List<BallModel> currentOverBalls;

  bool isFinished;
  String result;
  String? winningTeamId;
  String? losingTeamId;
  int? target;

  DateTime startTime;
  DateTime? endTime;

  MatchModel({
    required this.id,
    this.tournamentId,
    this.venue = 'Local Stadium',
    required this.team1,
    required this.team2,
    required this.totalOvers,
    this.ballsPerOver = 6,    // 🔥 Added with default 6
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
    this.winningTeamId,
    this.losingTeamId,
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

  TeamModel get battingTeam => (innings == 0)
      ? (batFirstTeamIdx == 0 ? team1 : team2)
      : (batFirstTeamIdx == 0 ? team2 : team1);

  TeamModel get bowlingTeam => (innings == 0)
      ? (batFirstTeamIdx == 0 ? team2 : team1)
      : (batFirstTeamIdx == 0 ? team1 : team2);

  TeamModel get winningTeamData => winningTeamId == team1.id ? team1 : team2;
  TeamModel get losingTeamData => losingTeamId == team1.id ? team1 : team2;

  int get currentScore => score[innings];
  int get currentWickets => wickets[innings];
  int get currentBalls => balls[innings];

  // 🔥 Fixed: Hardcoded 6 ki jagah ballsPerOver use kiya
  String get oversDisplay {
    int full = currentBalls ~/ ballsPerOver;
    int rem = currentBalls % ballsPerOver;
    return '$full.$rem';
  }

  // 🔥 Fixed: Run rate calculation dynamic balls per over se hogi
  double get currentRunRate => currentBalls > 0 ? (currentScore / (currentBalls / ballsPerOver)) : 0.0;

  // 🔥 Fixed: Required run rate logic fixed for custom balls
  double get requiredRunRate {
    if (innings == 0 || target == null) return 0.0;
    int needed = target! - currentScore;
    int ballsLeft = (totalOvers * ballsPerOver) - currentBalls;
    return ballsLeft > 0 ? (needed / (ballsLeft / ballsPerOver)) : 0.0;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'tournamentId': tournamentId,
    'venue': venue,
    'team1': team1.toMap(),
    'team2': team2.toMap(),
    'totalOvers': totalOvers,
    'ballsPerOver': ballsPerOver, // 🔥 Added serialization
    'innings': innings,
    'batFirstTeamIdx': batFirstTeamIdx,
    'tossWinner': tossWinner,
    'tossDecision': tossDecision,
    'score': score,
    'wickets': wickets,
    'balls': balls,
    'extras': extras,
    'strikerIdx': strikerIdx,
    'nonStrikerIdx': nonStrikerIdx,
    'bowlerIdx': bowlerIdx,
    'allBalls': allBalls.map((b) => b.toMap()).toList(),
    'currentOverBalls': currentOverBalls.map((b) => b.toMap()).toList(),
    'isFinished': isFinished,
    'result': result,
    'winningTeamId': winningTeamId,
    'losingTeamId': losingTeamId,
    'target': target,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
  };

  factory MatchModel.fromMap(Map<String, dynamic> map) => MatchModel(
    id: map['id'] ?? '',
    tournamentId: map['tournamentId'],
    venue: map['venue'] ?? 'Local Stadium',
    team1: TeamModel.fromMap(map['team1'] ?? {}),
    team2: TeamModel.fromMap(map['team2'] ?? {}),
    totalOvers: map['totalOvers'] ?? 20,
    ballsPerOver: map['ballsPerOver'] ?? 6, // 🔥 Added parsing with fallback 6
    innings: map['innings'] ?? 0,
    batFirstTeamIdx: map['batFirstTeamIdx'] ?? 0,
    tossWinner: map['tossWinner'] ?? '',
    tossDecision: map['tossDecision'] ?? 'bat',
    score: List<int>.from(map['score'] ?? [0, 0]),
    wickets: List<int>.from(map['wickets'] ?? [0, 0]),
    balls: List<int>.from(map['balls'] ?? [0, 0]),
    extras: List<int>.from(map['extras'] ?? [0, 0]),
    strikerIdx: map['strikerIdx'] ?? 0,
    nonStrikerIdx: map['nonStrikerIdx'] ?? 1,
    bowlerIdx: map['bowlerIdx'] ?? 0,
    allBalls: (map['allBalls'] as List<dynamic>? ?? []).map((b) => BallModel.fromMap(b)).toList(),
    currentOverBalls: (map['currentOverBalls'] as List<dynamic>? ?? []).map((b) => BallModel.fromMap(b)).toList(),
    isFinished: map['isFinished'] ?? false,
    result: map['result'] ?? '',
    winningTeamId: map['winningTeamId'],
    losingTeamId: map['losingTeamId'],
    target: map['target'],
    startTime: DateTime.parse(map['startTime'] ?? DateTime.now().toIso8601String()),
    endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
  );
}

// ============================================================
// 5. TOURNAMENT MATCH MODEL (Enhanced with Schedule & History)
// ============================================================
class TournamentMatch {
  String matchId;           // Har match ki unique ID taaki click karne par open ho sake
  String team1Id;
  String team2Id;
  int matchNumber;
  String? result;
  String? winnerId;

  // 🔥 New Fields for Custom Date, Time & Status
  DateTime scheduleDateTime; // Users apni marzi se date aur time select kar sakein
  String matchStatus;       // 'scheduled', 'live', 'completed'

  // 🔥 History Core: Match khatam hone par ya live hone par pura data yahan save hoga
  MatchModel? matchDetails;

  TournamentMatch({
    required this.matchId,
    required this.team1Id,
    required this.team2Id,
    required this.matchNumber,
    required this.scheduleDateTime,
    this.matchStatus = 'scheduled',
    this.result,
    this.winnerId,
    this.matchDetails,
  });

  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'team1Id': team1Id,
    'team2Id': team2Id,
    'matchNumber': matchNumber,
    'scheduleDateTime': scheduleDateTime.toIso8601String(),
    'matchStatus': matchStatus,
    'result': result,
    'winnerId': winnerId,
    'matchDetails': matchDetails?.toMap(), // Complete Match History save karne ke liye
  };

  factory TournamentMatch.fromMap(Map<String, dynamic> map) => TournamentMatch(
    matchId: map['matchId'] ?? '',
    team1Id: map['team1Id'] ?? '',
    team2Id: map['team2Id'] ?? '',
    matchNumber: map['matchNumber'] ?? 0,
    scheduleDateTime: map['scheduleDateTime'] != null
        ? DateTime.parse(map['scheduleDateTime'])
        : DateTime.now(),
    matchStatus: map['matchStatus'] ?? 'scheduled',
    result: map['result'],
    winnerId: map['winnerId'],
    matchDetails: map['matchDetails'] != null
        ? MatchModel.fromMap(map['matchDetails'] as Map<String, dynamic>)
        : null,
  );
}

// ============================================================
// TOURNAMENT MODEL (Fully Integrated History)
// ============================================================
class TournamentModel {
  String id;
  String name;
  List<TeamModel> teams;
  int totalMatches;
  int overs;
  int ballsPerOver;
  TournamentFormat format;
  List<TournamentMatch> schedule;
  DateTime startDate;
  bool isActive;
  String? winnerId;

  TournamentModel({
    required this.id,
    required this.name,
    required this.teams,
    required this.totalMatches,
    required this.overs,
    this.ballsPerOver = 6,
    this.format = TournamentFormat.roundRobin,
    List<TournamentMatch>? schedule,
    DateTime? startDate,
    this.isActive = true,
    this.winnerId,
  })  : schedule = schedule ?? [],
        startDate = startDate ?? DateTime.now();

  // Points table automatic schedule history se values read karega
  Map<String, Map<String, int>> get pointsTable {
    Map<String, Map<String, int>> table = {};
    for (final t in teams) {
      table[t.id] = {'played': 0, 'won': 0, 'lost': 0, 'points': 0};
    }
    for (final m in schedule) {
      // Points sirf tabhi update honge jab matchStatus 'completed' hoga
      if (m.matchStatus == 'completed' && m.winnerId != null) {
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'totalMatches': totalMatches,
    'overs': overs,
    'ballsPerOver': ballsPerOver,
    'format': format.name,
    'startDate': startDate.toIso8601String(),
    'isActive': isActive,
    'winnerId': winnerId,
    'teams': teams.map((t) => t.toMap()).toList(),
    'schedule': schedule.map((s) => s.toMap()).toList(),
  };

  factory TournamentModel.fromMap(Map<String, dynamic> map) {
    return TournamentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      teams: (map['teams'] as List<dynamic>?)
          ?.map((t) => TeamModel.fromMap(t as Map<String, dynamic>))
          .toList() ?? [],
      totalMatches: map['totalMatches'] ?? 0,
      overs: map['overs'] ?? 20,
      ballsPerOver: map['ballsPerOver'] ?? 6,
      schedule: (map['schedule'] as List<dynamic>?)
          ?.map((m) => TournamentMatch.fromMap(m as Map<String, dynamic>))
          .toList() ?? [],
      format: TournamentFormat.values.byName(map['format'] ?? 'roundRobin'),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : DateTime.now(),
      isActive: map['isActive'] ?? true,
      winnerId: map['winnerId'],
    );
  }
}