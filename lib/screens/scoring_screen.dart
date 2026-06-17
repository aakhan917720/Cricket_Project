// lib/screens/scoring_screen.dart
import 'dart:io';
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
  late TabController _tabController;
  BallType _selectedBallType = BallType.normal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Register match with provider immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().startNewMatch(widget.match);
      _showBowlerPicker();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addBall(int runs) {
    final matchProvider = context.read<MatchProvider>();
    final match = matchProvider.currentMatch;
    if (match == null || match.isFinished) return;

    final ball = BallModel(
      type: _selectedBallType,
      runs: runs,
      isWicket: false,
      overNumber: match.currentBalls ~/ 6,
      ballNumber: match.currentBalls % 6,
      batterId: match.battingTeam.players[match.strikerIdx].id,
      bowlerId: match.bowlingTeam.players[match.bowlerIdx].id,
    );

    matchProvider.addBall(ball);
    _checkEvents();

    // Reset selection to normal ball after delivery
    setState(() {
      _selectedBallType = BallType.normal;
    });
  }

  void _addWicket(String mode) {
    final matchProvider = context.read<MatchProvider>();
    final match = matchProvider.currentMatch;
    if (match == null || match.isFinished) return;

    final ball = BallModel(
      type: BallType.wicket,
      runs: 0,
      isWicket: true,
      wicketMode: mode,
      overNumber: match.currentBalls ~/ 6,
      ballNumber: match.currentBalls % 6,
      batterId: match.battingTeam.players[match.strikerIdx].id,
      bowlerId: match.bowlingTeam.players[match.bowlerIdx].id,
    );

    matchProvider.addBall(ball);
    _checkEvents();
  }

  void _checkEvents() {
    final m = context.read<MatchProvider>().currentMatch;
    if (m == null) return;

    if (m.isFinished) {
      _showMatchResult(m);
      return;
    }
    // Check if innings changed
    if (m.innings == 1 && widget.match.innings == 0) {
      _showInningsBreak(m);
    }
    // Check if over just ended (new over needs bowler)
    if (m.currentBalls > 0 && m.currentBalls % 6 == 0 && m.currentOverBalls.isEmpty) {
      _showBowlerPicker();
    }
    // Check if wicket fell (new batsman needed)
    if (m.currentWickets > widget.match.currentWickets) {
      _showBatsmanPicker(m);
    }
  }

  void _showBowlerPicker() {
    final match = context.read<MatchProvider>().currentMatch;
    if (match == null) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlayerPickerSheet(
        title: '🎯 Bowler Chuno',
        players: match.bowlingTeam.players,
        onSelect: (idx) {
          context.read<MatchProvider>().setBowler(idx);
        },
      ),
    );
  }

  void _showBatsmanPicker(MatchModel match) {
    final available = match.battingTeam.players
        .asMap()
        .entries
        .where((e) => !e.value.isOut && e.key != match.strikerIdx && e.key != match.nonStrikerIdx)
        .toList();

    if (available.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlayerPickerSheet(
        title: '🏏 Naya Batsman Chuno',
        players: available.map((e) => e.value).toList(),
        onSelect: (idx) {
          // 🔥 FIXED: Available item ke correct mapping index (key) ko explicit true value ke sath pass kar rahe hain
          context.read<MatchProvider>().setBatsman(available[idx].key, true);
        },
      ),
    );
  }

  void _showInningsBreak(MatchModel match) {
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
            '${match.bowlingTeam.name} ko target: ${match.target}',
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

  void _showMatchResult(MatchModel match) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('🏆 Match Khatam!', style: GoogleFonts.poppins(
            color: AppTheme.accentGreen, fontWeight: FontWeight.w800, fontSize: 22),
            textAlign: TextAlign.center),
        content: Text(match.result, style: GoogleFonts.poppins(
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
    final matchProvider = context.watch<MatchProvider>();
    final currentMatch = matchProvider.currentMatch ?? widget.match;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text('${currentMatch.team1.name} vs ${currentMatch.team2.name}',
            style: GoogleFonts.poppins(fontSize: 15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            onPressed: () {
              context.read<MatchProvider>().undoLastBall();
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
          _buildScoringTab(currentMatch),
          _buildScorecardTab(currentMatch),
        ],
      ),
    );
  }

  Widget _buildScoringTab(MatchModel match) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ScoreBoard(match: match),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _BatsmenRow(match: match),
                const SizedBox(height: 12),
                _BowlerRow(match: match),
                const SizedBox(height: 12),
                _BallTrackerWidget(match: match),
                const SizedBox(height: 16),

                _SectionLabel(label: '⚾ Ball Type Chuno'),
                const SizedBox(height: 8),
                _BallTypeSelector(
                  selected: _selectedBallType,
                  onSelect: (t) => setState(() => _selectedBallType = t),
                ),
                const SizedBox(height: 16),

                _SectionLabel(label: '🏃 Runs'),
                const SizedBox(height: 8),
                _RunsGrid(
                  ballType: _selectedBallType,
                  onRun: _addBall,
                ),
                const SizedBox(height: 16),

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

  Widget _buildScorecardTab(MatchModel match) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _ScorecardSection(
            title: '🏏 ${match.battingTeam.name} - Batting',
            headers: const ['Batsman', 'R', 'B', '4s', '6s', 'SR'],
            rows: match.battingTeam.players.map((p) => [
              p.name, '${p.runs}', '${p.balls}',
              '${p.fours}', '${p.sixes}',
              p.strikeRate.toStringAsFixed(1),
            ]).toList(),
          ),
          const SizedBox(height: 14),
          _ScorecardSection(
            title: '🎯 ${match.bowlingTeam.name} - Bowling',
            headers: const ['Bowler', 'O', 'R', 'W', 'Eco'],
            rows: match.bowlingTeam.players.map((p) => [
              p.name, p.oversStr, '${p.runsGiven}',
              '${p.wicketsTaken}', p.economy.toStringAsFixed(1),
            ]).toList(),
          ),
          const SizedBox(height: 14),
          _ExtrasCard(match: match),
        ],
      ),
    );
  }
}

// ============================================================
// UI Component Widgets
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
    final battingTeam = match.battingTeam;

    final striker = battingTeam.players.isNotEmpty && match.strikerIdx < battingTeam.players.length
        ? battingTeam.players[match.strikerIdx]
        : null;

    final nonStriker = battingTeam.players.isNotEmpty && match.nonStrikerIdx < battingTeam.players.length
        ? battingTeam.players[match.nonStrikerIdx]
        : null;

    return Row(
      children: [
        Expanded(
          child: striker != null
              ? _BatsmanCard(player: striker, isStriker: true)
              : const SizedBox(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: nonStriker != null
              ? _BatsmanCard(player: nonStriker, isStriker: false)
              : const SizedBox(),
        ),
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
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: player.photoPath != null && player.photoPath!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(player.photoPath!), fit: BoxFit.cover),
                )
                    : Center(child: Text(
                  player.name.isNotEmpty ? player.name.substring(0, 1) : '?',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppTheme.accentGreen),
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
    final bowlingTeam = match.bowlingTeam;

    final bowler = bowlingTeam.players.isNotEmpty && match.bowlerIdx < bowlingTeam.players.length
        ? bowlingTeam.players[match.bowlerIdx]
        : null;

    if (bowler == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_baseball, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(bowler.name, style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          Text(
            '${bowler.oversStr} Over | W: ${bowler.wicketsTaken} | R: ${bowler.runsGiven} | Eco: ${bowler.economy.toStringAsFixed(1)}',
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B8FA6), fontWeight: FontWeight.w500),
          ),
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
          if (match.currentOverBalls.isEmpty)
            Text('Koi ball nahi abhi', style: GoogleFonts.poppins(
                fontSize: 12, color: const Color(0xFF6B8FA6)))
          else
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
        ],
      ),
    );
  }
}

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
            color: selected == t.type ? t.color.withOpacity(0.25) : AppTheme.cardBg,
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
        child: Container(
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
            columnWidths: const {
              0: FlexColumnWidth(2.5),
            },
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
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('${index + 1}', style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800, color: AppTheme.accentGreen))),
                  ),
                  title: Text(player.name, style: GoogleFonts.poppins(color: Colors.white)),
                  subtitle: Text(player.role, style: GoogleFonts.poppins(
                      fontSize: 12, color: const Color(0xFF6B8FA6))),
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(index);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}