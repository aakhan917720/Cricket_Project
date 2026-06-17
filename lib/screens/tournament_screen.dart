// lib/screens/tournament_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // Date formating ke liye add kiya gaya hai
import '../models/models.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import 'match_history_detail_screen.dart';
import 'scoring_screen.dart';

class TournamentScreen extends StatelessWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.cardBg,
          title: Text(
            '🏆 Tournament Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.accentGreen,
            labelColor: AppTheme.accentGreen,
            unselectedLabelColor: const Color(0xFF6B8FA6),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Naya Tournament'),
              Tab(text: 'Active Tournament'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Builder(
              builder: (context) => _CreateTournamentTab(
                onSuccess: () {
                  DefaultTabController.of(context).animateTo(1);
                },
              ),
            ),
            const _ActiveTournamentTab(),
          ],
        ),
      ),
    );
  }
}

class _CreateTournamentTab extends StatefulWidget {
  final VoidCallback onSuccess;
  const _CreateTournamentTab({required this.onSuccess});

  @override
  State<_CreateTournamentTab> createState() => _CreateTournamentTabState();
}

class _CreateTournamentTabState extends State<_CreateTournamentTab> {
  final _nameCtrl = TextEditingController(text: 'Cricket League 2026');
  int _totalTeams = 4;
  int _totalMatches = 6;
  int _overs = 20;
  int _ballsPerOver = 6;
  final List<TextEditingController> _teamNames = [];

  // 🔥 Har match ke liye user selected dates track karne ki list
  final List<DateTime> _matchDates = [];

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
      _matchDates.clear();

      for (int i = 0; i < count; i++) {
        _teamNames.add(TextEditingController(text: 'Team ${i + 1}'));
      }

      _totalMatches = (count * (count - 1)) ~/ 2;
      // Default dates fill kar rahe hain (Aj ki date + dynamic additions)
      for (int i = 0; i < _totalMatches; i++) {
        _matchDates.add(DateTime.now().add(Duration(days: i)));
      }
    });
  }

  // 🔥 User se dynamic Date aur Time picker input lene ka function
  Future<void> _selectMatchDateTime(int index) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _matchDates[index],
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_matchDates[index]),
      );

      if (pickedTime != null) {
        setState(() {
          _matchDates[index] = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createTournament() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pehle tournament ka naam likhein!', style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() => _isCreating = true);

    final teams = _teamNames.map((ctrl) => TeamModel(
      id: _uuid.v4(),
      name: ctrl.text.trim().isEmpty ? 'Team ${_teamNames.indexOf(ctrl) + 1}' : ctrl.text.trim(),
      players: [],
    )).toList();

    final schedule = <TournamentMatch>[];
    int mNum = 0;

    for (int i = 0; i < teams.length; i++) {
      for (int j = i + 1; j < teams.length; j++) {
        schedule.add(TournamentMatch(
          matchId: 'M-${DateTime.now().millisecondsSinceEpoch}-$mNum',
          team1Id: teams[i].id,
          team2Id: teams[j].id,
          matchNumber: mNum + 1,
          scheduleDateTime: _matchDates[mNum], // Custom date integrate ho gayi
          matchStatus: 'scheduled',
        ));
        mNum++;
      }
    }

    final tournament = TournamentModel(
      id: _uuid.v4(),
      name: _nameCtrl.text.trim(),
      teams: teams,
      totalMatches: schedule.length,
      overs: _overs,
      ballsPerOver: _ballsPerOver,
      schedule: schedule,
    );

    try {
      await FirebaseService().saveTournament(tournament);
      if (mounted) {
        context.read<MatchProvider>().createTournament(tournament);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏆 ${tournament.name} successfully create ho gaya!', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.lightGreen,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
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
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentGreen)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _TournCard(
            title: '🏏 Overs (1-50)',
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$_overs', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.accentGreen)),
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
            title: '⚾ Balls Per Over (1-6)',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$_ballsPerOver', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.goldAccent)),
                    const SizedBox(width: 8),
                    Text('balls', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                  ],
                ),
                Slider(
                  value: _ballsPerOver.toDouble(),
                  min: 1, max: 6, divisions: 5,
                  activeColor: AppTheme.goldAccent,
                  inactiveColor: AppTheme.cardBorder,
                  onChanged: (v) => setState(() => _ballsPerOver = v.round()),
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
                      child: Text('$_totalTeams', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    IconButton(
                        onPressed: () { if (_totalTeams < 16) _updateTeams(_totalTeams + 1); },
                        icon: const Icon(Icons.add_circle, color: Color(0xFF4CAF50), size: 32)),
                  ],
                ),
                Text('Total generated matches: $_totalMatches', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.goldAccent)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TournCard(
            title: '🛡️ Teams Ke Naam',
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _teamNames.length,
              itemBuilder: (context, idx) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text('${idx + 1}', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: AppTheme.accentGreen, fontSize: 13))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _teamNames[idx],
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Team ka naam',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: InputBorder.none,
                          fillColor: Color(0xFF071524),
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔥 NAYA CARD: Har match ke liye Custom Date-Time configuration UI
          const SizedBox(height: 14),
          _TournCard(
            title: '📅 Matches Ka Date & Time Set Karein',
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _matchDates.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Match ${index + 1} Schedule:',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                      ),
                      TextButton.icon(
                        onPressed: () => _selectMatchDateTime(index),
                        icon: const Icon(Icons.calendar_month, color: AppTheme.accentGreen, size: 18),
                        label: Text(
                          DateFormat('dd MMM, hh:mm a').format(_matchDates[index]),
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(backgroundColor: const Color(0xFF071524)),
                      ),
                    ],
                  ),
                );
              },
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
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sirf _ActiveTournamentTab class ke andar build method mein badlao karein:
class _ActiveTournamentTab extends StatelessWidget {
  const _ActiveTournamentTab();

  void _showEditDialog(BuildContext context, MatchProvider provider, String id, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text('Edit Tournament Name', style: GoogleFonts.poppins(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.updateTournamentName(id, ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchProvider>();
    final tournament = provider.currentTournament;

    if (tournament == null) {
      return Center(
        child: Text('Koi active tournament nahi hai', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
      );
    }

    final points = tournament.pointsTable;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 🔥 TOURNAMENT CONTROL HEADER CARD (With Edit & Delete Controls)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '🏆 ${tournament.name}',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                    onPressed: () => _showEditDialog(context, provider, tournament.id, tournament.name),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                    onPressed: () {
                      // Prompt Confirmation
                      provider.deleteTournament(tournament.id);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 14),

        _TournCard(
          title: '📊 Points Table Overview',
          child: Table(
            border: TableBorder.all(color: Colors.white12),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: ['Team', 'P', 'W', 'L', 'Pts']
                    .map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(h, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: const Color(0xFF6B8FA6), fontWeight: FontWeight.bold)),
                ))
                    .toList(),
              ),
              ...tournament.teams.map((t) {
                final p = points[t.id] ?? {'played': 0, 'won': 0, 'lost': 0, 'points': 0};
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(t.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                    Text('${p['played']}', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white)),
                    Text('${p['won']}', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white)),
                    Text('${p['lost']}', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white)),
                    Text('${p['points']}', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _TournCard(
          title: '📅 Schedule List (Khelne ke liye click karein)',
          child: Column(
            children: tournament.schedule.map((m) {
              final t1 = tournament.teams.firstWhere((t) => t.id == m.team1Id, orElse: () => TeamModel(id: '', name: 'Unknown', players: []));
              final t2 = tournament.teams.firstWhere((t) => t.id == m.team2Id, orElse: () => TeamModel(id: '', name: 'Unknown', players: []));

              final bool isDone = m.matchStatus == 'completed';
              final bool isLive = m.matchStatus == 'live';

              return Card(
                color: const Color(0xFF071524),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('${t1.name} vs ${t2.name}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  subtitle: Text(isLive ? '⏸️ Click to Resume Match' : '📅 Tap to start whenever you want', style: TextStyle(color: isLive ? AppTheme.accentGreen : Colors.white38, fontSize: 11)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: isDone ? Colors.green.withValues(alpha: 0.2) : (isLive ? Colors.blue.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(
                      isDone ? 'Done' : (isLive ? 'Live' : 'Pending'),
                      style: TextStyle(color: isDone ? Colors.green : (isLive ? Colors.blue : Colors.orange), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  onTap: () {
                    // 🔥 Kisi bhi waqt koi bhi match start/resume ho sakta hai
                    provider.startTournamentMatch(m, t1, t2, tournament.overs);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ScoringScreen(match: provider.currentMatch!)));
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
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