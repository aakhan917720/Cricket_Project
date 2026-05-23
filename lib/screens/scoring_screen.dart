// lib/screens/scoring_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';

class ScoringScreen extends StatefulWidget {
  final MatchModel match;
  const ScoringScreen({super.key, required this.match});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen>
    with SingleTickerProviderStateMixin {
  late MatchModel _match;
  late TabController _tabController;
  BallType _selectedBallType = BallType.normal;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _tabController = TabController(length: 2, vsync: this);
    // Register with provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().startNewMatch(_match);
    });
    // Show initial selections
    WidgetsBinding.instance.addPostFrameCallback((_) => _showBowlerPicker());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addBall(int runs) {
    if (_match.isFinished) return;
    final ball = BallModel(
      type: _selectedBallType,
      runs: runs,
      isWicket: false,
      overNumber: _match.currentBalls ~/ 6,
      ballNumber: _match.currentBalls % 6,
      batterId: _match.battingTeam.players[_match.strikerIdx].id,
      bowlerId: _match.bowlingTeam.players[_match.bowlerIdx].id,
    );
    context.read<MatchProvider>().addBall(ball);
    setState(() {
      _match = context.read<MatchProvider>().currentMatch ?? _match;
    });
    _checkEvents();
  }

  void _addWicket(String mode) {
    if (_match.isFinished) return;
    final ball = BallModel(
      type: BallType.wicket,
      runs: 0,
      isWicket: true,
      wicketMode: mode,
      overNumber: _match.currentBalls ~/ 6,
      ballNumber: _match.currentBalls % 6,
      batterId: _match.battingTeam.players[_match.strikerIdx].id,
      bowlerId: _match.bowlingTeam.players[_match.bowlerIdx].id,
    );
    context.read<MatchProvider>().addBall(ball);
    setState(() {
      _match = context.read<MatchProvider>().currentMatch ?? _match;
    });
    _checkEvents();
  }

  void _checkEvents() {
    final m = context.read<MatchProvider>().currentMatch;
    if (m == null) return;
    setState(() => _match = m);

    if (m.isFinished) {
      _showMatchResult();
      return;
    }
    // Check if innings changed
    if (m.innings == 1 && _match.innings == 0) {
      _showInningsBreak();
    }
    // Check if over just ended (new over needs bowler)
    if (m.currentBalls > 0 && m.currentBalls % 6 == 0 && m.currentOverBalls.isEmpty) {
      _showBowlerPicker();
    }
    // Check if wicket (new batsman)
    if (m.currentWickets > _match.currentWickets) {
      _showBatsmanPicker();
    }
  }

  void _showBowlerPicker() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlayerPickerSheet(
        title: '🎯 Bowler Chuno',
        players: _match.bowlingTeam.players,
        onSelect: (idx) {
          context.read<MatchProvider>().setBowler(idx);
          setState(() => _match = context.read<MatchProvider>().currentMatch ?? _match);
        },
      ),
    );
  }

  void _showBatsmanPicker() {
    final available = _match.battingTeam.players
        .asMap()
        .entries
        .where((e) => !e.value.isOut && e.key != _match.strikerIdx && e.key != _match.nonStrikerIdx)
        .toList();

    if (available.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlayerPickerSheet(
        title: '🏏 Nayi Batsman Chuno',
        players: available.map((e) => e.value).toList(),
        onSelect: (idx) {
          context.read<MatchProvider>().setBatsman(available[idx].key);
          setState(() => _match = context.read<MatchProvider>().currentMatch ?? _match);
        },
      ),
    );
  }

  void _showInningsBreak() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('⚡ Innings Break', style: GoogleFonts.poppins(
          color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('1st Innings khatam!', style: GoogleFonts.poppins(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            '${_match.bowlingTeam.name} ko target: ${_match.target}',
            style: GoogleFonts.poppins(color: AppTheme.goldAccent, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBowlerPicker();
            },
            child: const Text('2nd Innings Shuru Karo'),
          ),
        ],
      ),
    );
  }

  void _showMatchResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('🏆 Match Khatam!', style: GoogleFonts.poppins(
          color: AppTheme.accentGreen, fontWeight: FontWeight.w800, fontSize: 22),
          textAlign: TextAlign.center),
        content: Text(_match.result, style: GoogleFonts.poppins(
          color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
            child: const Text('Dashboard Par Jao'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text('${_match.team1.name} vs ${_match.team2.name}',
          style: GoogleFonts.poppins(fontSize: 15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            onPressed: () {
              context.read<MatchProvider>().undoLastBall();
              setState(() => _match = context.read<MatchProvider>().currentMatch ?? _match);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGreen,
          labelColor: AppTheme.accentGreen,
          unselectedLabelColor: const Color(0xFF6B8FA6),
          tabs: const [Tab(text: 'Score'), Tab(text: 'Scorecard')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScoringTab(),
          _buildScorecardTab(),
        ],
      ),
    );
  }

  Widget _buildScoringTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Scoreboard
          _ScoreBoard(match: _match),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Current batsmen
                _BatsmenRow(match: _match),
                const SizedBox(height: 10),
                // Bowler
                _BowlerRow(match: _match),
                const SizedBox(height: 10),
                // Ball tracker this over
                _BallTrackerWidget(match: _match),
                const SizedBox(height: 12),

                // ============================================
                // BALL TYPE SELECTOR (6 types)
                // ============================================
                _SectionLabel(label: '⚾ Ball Type Chuno'),
                const SizedBox(height: 8),
                _BallTypeSelector(
                  selected: _selectedBallType,
                  onSelect: (t) => setState(() => _selectedBallType = t),
                ),
                const SizedBox(height: 14),

                // ============================================
                // RUNS (0-6)
                // ============================================
                _SectionLabel(label: '🏃 Runs'),
                const SizedBox(height: 8),
                _RunsGrid(
                  ballType: _selectedBallType,
                  onRun: _addBall,
                ),
                const SizedBox(height: 14),

                // ============================================
                // WICKETS
                // ============================================
                _SectionLabel(label: '🎯 Wicket'),
                const SizedBox(height: 8),
                _WicketGrid(onWicket: _addWicket),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Batting scorecard
          _ScorecardSection(
            title: '🏏 ${_match.battingTeam.name} - Batting',
            headers: const ['Batsman', 'R', 'B', '4s', '6s', 'SR'],
            rows: _match.battingTeam.players.map((p) => [
              p.name, '${p.runs}', '${p.balls}',
              '${p.fours}', '${p.sixes}',
              p.strikeRate.toStringAsFixed(1),
            ]).toList(),
          ),
          const SizedBox(height: 14),
          _ScorecardSection(
            title: '🎯 ${_match.bowlingTeam.name} - Bowling',
            headers: const ['Bowler', 'O', 'R', 'W', 'Eco'],
            rows: _match.bowlingTeam.players.map((p) => [
              p.name, p.oversStr, '${p.runsGiven}',
              '${p.wicketsTaken}', p.economy.toStringAsFixed(1),
            ]).toList(),
          ),
          const SizedBox(height: 14),
          // Extras
          _ExtrasCard(match: _match),
        ],
      ),
    );
  }
}

// ============================================================
// Widgets
// ============================================================

class _ScoreBoard extends StatelessWidget {
  final MatchModel match;
  const _ScoreBoard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2137), Color(0xFF1B5E20)],
        ),
      ),
      child: Column(
        children: [
          // Team name + innings
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(5)),
                child: Text('LIVE', style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Text(
                '${match.battingTeam.name} | ${match.innings == 0 ? "1st" : "2nd"} Innings',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${match.currentScore}/${match.currentWickets}',
                style: GoogleFonts.poppins(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.oversDisplay, style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white70)),
                  Text('CRR: ${match.currentRunRate.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.accentGreen)),
                ],
              ),
            ],
          ),
          if (match.innings == 1 && match.target != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Target: ${match.target} | Need: ${match.target! - match.currentScore}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.goldAccent),
                  ),
                  Text('RRR: ${match.requiredRunRate.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.goldAccent)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BatsmenRow extends StatelessWidget {
  final MatchModel match;
  const _BatsmenRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final striker = match.battingTeam.players[match.strikerIdx];
    final nonStriker = match.battingTeam.players[match.nonStrikerIdx];

    return Row(
      children: [
        Expanded(child: _BatsmanCard(player: striker, isStriker: true)),
        const SizedBox(width: 8),
        Expanded(child: _BatsmanCard(player: nonStriker, isStriker: false)),
      ],
    );
  }
}

class _BatsmanCard extends StatelessWidget {
  final PlayerModel player;
  final bool isStriker;
  const _BatsmanCard({required this.player, required this.isStriker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isStriker ? AppTheme.lightGreen.withOpacity(0.15) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isStriker ? AppTheme.accentGreen : AppTheme.cardBorder,
          width: isStriker ? 1 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Photo
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: player.photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        import_dart_io.File(player.photoPath!), fit: BoxFit.cover),
                    )
                  : Center(child: Text(
                      player.name.substring(0, 1),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, color: AppTheme.accentGreen),
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(player.name,
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          overflow: TextOverflow.ellipsis)),
                        if (isStriker)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.sports_cricket, size: 14, color: Color(0xFF4CAF50)),
                          ),
                      ],
                    ),
                    Text(
                      '${player.balls}b | ${player.fours}x4 | ${player.sixes}x6',
                      style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF6B8FA6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${player.runs}', style: GoogleFonts.poppins(
            fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.accentGreen)),
          Text('SR: ${player.strikeRate.toStringAsFixed(1)}',
            style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF6B8FA6))),
        ],
      ),
    );
  }
}

class _BowlerRow extends StatelessWidget {
  final MatchModel match;
  const _BowlerRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final bowler = match.bowlingTeam.players[match.bowlerIdx];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(bowler.name.substring(0, 1),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800,
                  color: const Color(0xFF42A5F5)))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bowler.name, style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('${bowler.oversStr} ov | ${bowler.runsGiven} runs',
                  style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF6B8FA6))),
              ],
            ),
          ),
          Text('${bowler.wicketsTaken}/${bowler.runsGiven}',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800,
                color: AppTheme.goldAccent)),
        ],
      ),
    );
  }
}

class _BallTrackerWidget extends StatelessWidget {
  final MatchModel match;
  const _BallTrackerWidget({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Is Over Ki Balls', style: GoogleFonts.poppins(
            fontSize: 11, color: const Color(0xFF6B8FA6))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: match.currentOverBalls.map((b) {
              Color bg;
              Color fg;
              switch (b.type) {
                case BallType.wide: bg = AppTheme.wideBall.withOpacity(0.2); fg = AppTheme.wideBall; break;
                case BallType.noBall: bg = AppTheme.noBall.withOpacity(0.2); fg = AppTheme.noBall; break;
                case BallType.bye: bg = AppTheme.byeBall.withOpacity(0.2); fg = AppTheme.byeBall; break;
                case BallType.legBye: bg = AppTheme.legByeBall.withOpacity(0.2); fg = AppTheme.legByeBall; break;
                case BallType.deadBall: bg = AppTheme.deadBall.withOpacity(0.2); fg = AppTheme.deadBall; break;
                case BallType.wicket: bg = AppTheme.wicketBall.withOpacity(0.2); fg = AppTheme.wicketBall; break;
                default:
                  if (b.runs == 4) { bg = const Color(0xFF1565C0).withOpacity(0.2); fg = const Color(0xFF42A5F5); }
                  else if (b.runs == 6) { bg = const Color(0xFF7B1FA2).withOpacity(0.2); fg = const Color(0xFFCE93D8); }
                  else { bg = AppTheme.lightGreen.withOpacity(0.2); fg = AppTheme.accentGreen; }
              }
              return Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: bg, shape: BoxShape.circle,
                  border: Border.all(color: fg.withOpacity(0.5)),
                ),
                child: Center(child: Text(b.isWicket ? 'W' : b.displayLabel,
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: fg))),
              );
            }).toList(),
          ),
          if (match.currentOverBalls.isEmpty)
            Text('Koi ball nahi abi', style: GoogleFonts.poppins(
              fontSize: 12, color: const Color(0xFF6B8FA6))),
        ],
      ),
    );
  }
}

// ============================================================
// Ball Type Selector - 6 types
// ============================================================
class _BallTypeSelector extends StatelessWidget {
  final BallType selected;
  final ValueChanged<BallType> onSelect;

  const _BallTypeSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final types = [
      _BallTypeItem(BallType.normal, 'Normal', '⚾', AppTheme.accentGreen),
      _BallTypeItem(BallType.wide, 'Wide', '➡️', AppTheme.wideBall),
      _BallTypeItem(BallType.noBall, 'No Ball', '🚫', AppTheme.noBall),
      _BallTypeItem(BallType.bye, 'Bye', '🏃', AppTheme.byeBall),
      _BallTypeItem(BallType.legBye, 'Leg Bye', '🦵', AppTheme.legByeBall),
      _BallTypeItem(BallType.deadBall, 'Dead', '💀', AppTheme.deadBall),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: types.map((t) => GestureDetector(
        onTap: () => onSelect(t.type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected == t.type
                ? t.color.withOpacity(0.25)
                : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected == t.type ? t.color : AppTheme.cardBorder,
              width: selected == t.type ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(t.label, style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: selected == t.type ? t.color : Colors.grey,
              )),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _BallTypeItem {
  final BallType type;
  final String label;
  final String emoji;
  final Color color;
  _BallTypeItem(this.type, this.label, this.emoji, this.color);
}

// ============================================================
// Runs Grid (0-6)
// ============================================================
class _RunsGrid extends StatelessWidget {
  final BallType ballType;
  final ValueChanged<int> onRun;

  const _RunsGrid({required this.ballType, required this.onRun});

  @override
  Widget build(BuildContext context) {
    final runItems = [
      _RunItem(0, '0', const Color(0xFF37474F), const Color(0xFF546E7A)),
      _RunItem(1, '1', const Color(0xFF1B5E20), AppTheme.accentGreen),
      _RunItem(2, '2', const Color(0xFF1B5E20), AppTheme.accentGreen),
      _RunItem(3, '3', const Color(0xFF1B5E20), AppTheme.accentGreen),
      _RunItem(4, '4', const Color(0xFF0D47A1), const Color(0xFF42A5F5)),
      _RunItem(5, '5', const Color(0xFF4A148C), const Color(0xFFCE93D8)),
      _RunItem(6, '6', const Color(0xFF7B1FA2), const Color(0xFFE040FB)),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: runItems.map((r) => GestureDetector(
        onTap: () => onRun(r.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: r.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(r.label, style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w900, color: r.fg)),
          ),
        ),
      )).toList(),
    );
  }
}

class _RunItem {
  final int value;
  final String label;
  final Color bg;
  final Color fg;
  _RunItem(this.value, this.label, this.bg, this.fg);
}

// ============================================================
// Wicket Grid
// ============================================================
class _WicketGrid extends StatelessWidget {
  final ValueChanged<String> onWicket;
  const _WicketGrid({required this.onWicket});

  @override
  Widget build(BuildContext context) {
    final modes = [
      '🎯 Bowled', '🙌 Caught', '🦵 LBW',
      '🏃 Run Out', '🧤 Stumped', '💥 Hit Wicket',
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.5,
      children: modes.map((m) => GestureDetector(
        onTap: () {
          final mode = m.split(' ').skip(1).join(' ');
          onWicket(mode);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF7B0000).withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withOpacity(0.4), width: 0.5),
          ),
          child: Center(
            child: Text(m, style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFEF9A9A))),
          ),
        ),
      )).toList(),
    );
  }
}

// ============================================================
// Scorecard
// ============================================================
class _ScorecardSection extends StatelessWidget {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  const _ScorecardSection({
    required this.title, required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title, style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          Table(
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF1E3A5F)),
                children: headers.map((h) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(h, style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B8FA6))),
                )).toList(),
              ),
              ...rows.map((row) => TableRow(
                children: row.map((cell) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(cell, style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.white)),
                )).toList(),
              )),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ExtrasCard extends StatelessWidget {
  final MatchModel match;
  const _ExtrasCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Extras', style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('${match.extras[match.innings]}', style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.goldAccent)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: const Color(0xFF6B8FA6), letterSpacing: 0.3)),
    );
  }
}

// Player picker sheet
class _PlayerPickerSheet extends StatelessWidget {
  final String title;
  final List<PlayerModel> players;
  final ValueChanged<int> onSelect;

  const _PlayerPickerSheet({
    required this.title, required this.players, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          ...players.asMap().entries.map((e) => ListTile(
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('${e.key + 1}', style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800, color: AppTheme.accentGreen))),
            ),
            title: Text(e.value.name, style: GoogleFonts.poppins(color: Colors.white)),
            subtitle: Text(e.value.role, style: GoogleFonts.poppins(
              fontSize: 12, color: const Color(0xFF6B8FA6))),
            onTap: () {
              Navigator.pop(context);
              onSelect(e.key);
            },
          )),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// Fix: need dart:io import for File
import 'dart:io' as import_dart_io show File;
