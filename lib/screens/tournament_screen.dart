// lib/screens/tournament_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import 'match_history_detail_screen.dart'; // 🔥 Fix import for viewing completed matches

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: Text('🏆 Tournament Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGreen,
          labelColor: AppTheme.accentGreen,
          unselectedLabelColor: const Color(0xFF6B8FA6),
          tabs: const [Tab(text: 'Naya Tournament'), Tab(text: 'Active Tournament')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _CreateTournamentTab(),
          const _ActiveTournamentTab(),
        ],
      ),
    );
  }
}

// ============================================================
// Create Tournament Tab
// ============================================================
class _CreateTournamentTab extends StatefulWidget {
  const _CreateTournamentTab();

  @override
  State<_CreateTournamentTab> createState() => _CreateTournamentTabState();
}

class _CreateTournamentTabState extends State<_CreateTournamentTab> {
  final _nameCtrl = TextEditingController(text: 'Cricket League 2026');
  int _totalTeams = 4;
  int _totalMatches = 10;
  int _overs = 20;
  TournamentFormat _format = TournamentFormat.roundRobin;
  final List<TextEditingController> _teamNames = [];
  bool _isCreating = false;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _updateTeams(4);
  }

  void _updateTeams(int count) {
    setState(() {
      _totalTeams = count;
      _teamNames.clear();
      for (int i = 0; i < count; i++) {
        _teamNames.add(TextEditingController(text: 'Team ${i + 1}'));
      }
    });
  }

  Future<void> _createTournament() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _isCreating = true);

    final teams = _teamNames.map((ctrl) => TeamModel(
      id: _uuid.v4(),
      name: ctrl.text,
    )).toList();

    final schedule = _generateSchedule(teams);

    final tournament = TournamentModel(
      id: _uuid.v4(),
      name: _nameCtrl.text,
      teams: teams,
      totalMatches: _totalMatches,
      overs: _overs,
      format: _format,
      schedule: schedule,
    );

    await FirebaseService().saveTournament(tournament);
    if (mounted) {
      context.read<MatchProvider>().createTournament(tournament);
    }

    setState(() => _isCreating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🏆 ${tournament.name} create ho gaya!',
              style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.lightGreen,
        ),
      );
    }
  }

  List<TournamentMatch> _generateSchedule(List<TeamModel> teams) {
    final matches = <TournamentMatch>[];
    int matchNum = 1;

    // Generates scale matches up to 200 safely
    for (int i = 0; i < teams.length && matchNum <= _totalMatches; i++) {
      for (int j = i + 1; j < teams.length && matchNum <= _totalMatches; j++) {
        matches.add(TournamentMatch(
          team1Id: teams[i].id,
          team2Id: teams[j].id,
          matchNumber: matchNum++,
        ));
      }
    }
    return matches;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (var c in _teamNames) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _TournCard(
            title: '🏆 Tournament Ka Naam',
            child: TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Jaise: Premier Cricket League',
                prefixIcon: Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          _TournCard(
            title: '📋 Format',
            child: Column(
              children: TournamentFormat.values.map((f) => RadioListTile<TournamentFormat>(
                value: f,
                groupValue: _format,
                activeColor: AppTheme.accentGreen,
                title: Text(_formatName(f), style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                subtitle: Text(_formatDesc(f), style: GoogleFonts.poppins(color: const Color(0xFF6B8FA6), fontSize: 11)),
                onChanged: (v) => setState(() => _format = v!),
              )).toList(),
            ),
          ),
          const SizedBox(height: 14),

          _TournCard(
            title: '🏏 Overs (1-50)',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$_overs', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.accentGreen)),
                    const SizedBox(width: 8),
                    Text('overs', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                  ],
                ),
                Slider(
                  value: _overs.toDouble(),
                  min: 1, max: 50, divisions: 49,
                  activeColor: AppTheme.accentGreen,
                  inactiveColor: AppTheme.cardBorder,
                  onChanged: (v) => setState(() => _overs = v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _TournCard(
            title: '🎯 Total Matches (1-200)',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$_totalMatches', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.goldAccent)),
                    const SizedBox(width: 8),
                    Text('matches', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                  ],
                ),
                Slider(
                  value: _totalMatches.toDouble(),
                  min: 1, max: 200, divisions: 199, // Scaled up to 200 max matches
                  activeColor: AppTheme.goldAccent,
                  inactiveColor: AppTheme.cardBorder,
                  onChanged: (v) => setState(() => _totalMatches = v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _TournCard(
            title: '👥 Teams Ki Tadad',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () { if (_totalTeams > 2) _updateTeams(_totalTeams - 1); },
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 32)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('$_totalTeams', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    IconButton(
                        onPressed: () { if (_totalTeams < 16) _updateTeams(_totalTeams + 1); },
                        icon: const Icon(Icons.add_circle, color: Color(0xFF4CAF50), size: 32)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _TournCard(
            title: '🛡️ Teams Ke Naam',
            child: Column(
              children: _teamNames.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text('${e.key + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppTheme.accentGreen, fontSize: 13))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: e.value,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Team ${e.key + 1} ka naam',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCreating ? null : _createTournament,
              icon: _isCreating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.emoji_events_rounded),
              label: Text(_isCreating ? 'Tournament Ban Raha Hai...' : '🏆 Tournament Banao', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatName(TournamentFormat f) {
    switch (f) {
      case TournamentFormat.roundRobin: return 'Round Robin';
      case TournamentFormat.knockout: return 'Knockout';
      case TournamentFormat.leagueAndKnockout: return 'League + Knockout';
    }
  }

  String _formatDesc(TournamentFormat f) {
    switch (f) {
      case TournamentFormat.roundRobin: return 'Har team se ek match compulsorily khela jayega';
      case TournamentFormat.knockout: return 'Jo team haregi woh tournament se seedha bahar';
      case TournamentFormat.leagueAndKnockout: return 'Pehle league phase hoga phir final top rounds';
    }
  }
}

class _TournCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _TournCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF6B8FA6))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// Active Tournament Tab
// ============================================================
class _ActiveTournamentTab extends StatelessWidget {
  const _ActiveTournamentTab();

  @override
  Widget build(BuildContext context) {
    final tournament = context.watch<MatchProvider>().currentTournament;

    if (tournament == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 64, color: Color(0xFF6B8FA6)),
            const SizedBox(height: 16),
            Text('Koi active tournament nahi mila', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 8),
            Text('"Naya Tournament" tab se shuru karein', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B8FA6))),
          ],
        ),
      );
    }

    final points = tournament.pointsTable;

    return ListView( // Switch to ListView for better scroll performance with huge 200 items lists
      padding: const EdgeInsets.all(16),
      children: [
        // Tournament banner card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7B6000), Color(0xFF1B5E20)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('${tournament.teams.length} Teams | ${tournament.totalMatches} Matches | ${tournament.overs} Overs',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Points table
        _TournCard(
          title: '📊 Points Table Overview',
          child: Table(
            border: TableBorder.all(color: Colors.white12, width: 0.5, borderRadius: BorderRadius.circular(4)),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF0F2537)),
                children: ['Team', 'P', 'W', 'L', 'Pts'].map((h) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Text(h, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF6B8FA6))),
                )).toList(),
              ),
              ...tournament.teams.map((t) {
                final p = points[t.id] ?? {};
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(t.name, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                    ...['played', 'won', 'lost', 'points'].map((k) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Text('${p[k] ?? 0}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                    )),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Schedule list section with action handling
        _TournCard(
          title: '📅 Match Schedule (Click to Open/View)',
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tournament.schedule.length,
            itemBuilder: (context, index) {
              final m = tournament.schedule[index];
              final t1 = tournament.teams.firstWhere((t) => t.id == m.team1Id,
                  orElse: () => TeamModel(id: '', name: 'Unknown'));
              final t2 = tournament.teams.firstWhere((t) => t.id == m.team2Id,
                  orElse: () => TeamModel(id: '', name: 'Unknown'));

              final bool isDone = m.winnerId != null;

              return InkWell(
                onTap: () {
                  if (isDone) {
                    // 🔥 CLICK ACTION: Agar match finish hai toh scorecard screen par bhejo
                    if (m.matchModelData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchHistoryDetailScreen(match: m.matchModelData!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Is match ka detail data nahi mila.'))
                      );
                    }
                  } else {
                    // 🏏 CLICK ACTION: Agar match pending hai toh scoring screen setup pe le jao
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🏏 Match #${m.matchNumber} (${t1.name} vs ${t2.name}) ki Scoring shuru karein!'),
                        backgroundColor: AppTheme.accentGreen,
                      ),
                    );
                    // Yahan aap apna Navigator.push laga sakte hain jo Live Scoring setup par le jaye
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDone ? AppTheme.lightGreen.withValues(alpha: 0.05) : const Color(0xFF071524),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone ? AppTheme.accentGreen.withValues(alpha: 0.2) : AppTheme.cardBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('M${m.matchNumber}', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.goldAccent, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('${t1.name} vs ${t2.name}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.accentGreen.withValues(alpha: 0.15) : Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isDone ? 'Done' : 'Pending',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDone ? AppTheme.accentGreen : Colors.white38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Extension fallback feature if match data handling is mapped inside schedule model
extension CustomTournamentMatch on TournamentMatch {
  MatchModel? get matchModelData {
    // Agar aapke TournamentMatch model me actual complete MatchModel save ho raha hai toh yahan return hoga.
    // Yeh temporary logic handle karne ke liye banaya hai taake code crash na ho.
    return null;
  }
}