// lib/screens/match_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MatchDetailScreen extends StatelessWidget {
  final MatchModel match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final team1 = match.team1;
    final team2 = match.team2;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          backgroundColor: AppTheme.cardBg,
          elevation: 2,
          title: Text(
            '${team1.shortName} vs ${team2.shortName} Scorecard',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.accentGreen,
            labelColor: AppTheme.accentGreen,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: team1.name),
              Tab(text: team2.name),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Team 1 ki Batting aur Team 2 ki Bowling (Jin players ne match khela unhi ka data dikhega)
            _buildScorecardView(
              battingPlayers: team1.players.where((p) => p.balls > 0).toList(),
              bowlingPlayers: team2.players.where((p) => p.oversBowled > 0).toList(),
            ),
            // Tab 2: Team 2 ki Batting aur Team 1 ki Bowling
            _buildScorecardView(
              battingPlayers: team2.players.where((p) => p.balls > 0).toList(),
              bowlingPlayers: team1.players.where((p) => p.oversBowled > 0).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecardView({
    required List<PlayerModel> battingPlayers,
    required List<PlayerModel> bowlingPlayers,
  }) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ================= BATTING TABLE =================
        Row(
          children: [
            const Icon(Icons.sports_cricket, color: AppTheme.accentGreen, size: 20),
            const SizedBox(width: 8),
            Text('Batting Scorecard',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder, width: 0.5),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5), // Batsman name & details
              1: FlexColumnWidth(0.8), // Runs (R)
              2: FlexColumnWidth(0.8), // Balls (B)
              3: FlexColumnWidth(0.6), // 4s
              4: FlexColumnWidth(0.6), // 6s
              5: FlexColumnWidth(1.0), // Strike Rate (SR)
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFF071524),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                children: [
                  _th('Batsman'), _th('R'), _th('B'), _th('4s'), _th('6s'), _th('SR'),
                ],
              ),
              if (battingPlayers.isEmpty)
                TableRow(children: [_td('No batting data available', maxLines: 1), _td(''), _td(''), _td(''), _td(''), _td('')])
              else
                ...battingPlayers.map((player) {
                  final String outStatus = player.isOut
                      ? (player.outMode.isNotEmpty ? '(${player.outMode})' : '(Out)')
                      : 'Not Out';
                  return TableRow(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5))),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.name, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                            Text(outStatus, style: GoogleFonts.poppins(fontSize: 10, color: player.isOut ? Colors.white38 : AppTheme.accentGreen)),
                          ],
                        ),
                      ),
                      _td(player.runs.toString(), isBold: true),
                      _td(player.balls.toString()),
                      _td(player.fours.toString()),
                      _td(player.sixes.toString()),
                      // Strike rate humare PlayerModel ka dynamic getter function use kar raha hai
                      _td(player.strikeRate.toStringAsFixed(1), color: const Color(0xFF6B8FA6)),
                    ],
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // ================= BOWLING TABLE =================
        Row(
          children: [
            const Icon(Icons.sports_baseball, color: AppTheme.accentGreen, size: 20),
            const SizedBox(width: 8),
            Text('Bowling Scorecard',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder, width: 0.5),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5), // Bowler Name
              1: FlexColumnWidth(0.8), // Overs (O)
              2: FlexColumnWidth(0.7), // Maiden (M)
              3: FlexColumnWidth(0.7), // Runs (R)
              4: FlexColumnWidth(0.7), // Wickets (W)
              5: FlexColumnWidth(1.0), // Economy (Econ)
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFF071524),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                children: [
                  _th('Bowler'), _th('O'), _th('M'), _th('R'), _th('W'), _th('Econ'),
                ],
              ),
              if (bowlingPlayers.isEmpty)
                TableRow(children: [_td('No bowling data available', maxLines: 1), _td(''), _td(''), _td(''), _td(''), _td('')])
              else
                ...bowlingPlayers.map((player) {
                  return TableRow(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5))),
                    children: [
                      _td(player.name, isBold: true, textAlign: Alignment.centerLeft),
                      // PlayerModel ka structure properties format string use kar raha hai full.rem ke liye
                      _td(player.oversStr),
                      _td(player.maidenOvers.toString()),
                      _td(player.runsGiven.toString()),
                      _td(player.wicketsTaken.toString(), isBold: true, color: AppTheme.accentGreen),
                      // PlayerModel ka dynamic economy formula automatic runtime calculation karega
                      _td(player.economy.toStringAsFixed(1), color: const Color(0xFF6B8FA6)),
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B8FA6), fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _td(String text, {bool isBold = false, Color color = Colors.white, Alignment textAlign = Alignment.center, int? maxLines}) {
    return Container(
      alignment: textAlign,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}