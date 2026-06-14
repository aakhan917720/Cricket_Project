import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MatchHistoryDetailScreen extends StatelessWidget {
  final MatchModel match;

  const MatchHistoryDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    // Sahi tariqe se score aur wickets extract karna
    final t1Score = match.score.isNotEmpty ? match.score[0] : 0;
    final t2Score = match.score.length > 1 ? match.score[1] : 0;
    final t1Wickets = match.wickets.isNotEmpty ? match.wickets[0] : 0;
    final t2Wickets = match.lengthWickets > 1 ? match.wickets[1] : 0;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: Text('📊 Match Scorecard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Summary Card (Main Header)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTeamHeader(match.team1.name, '$t1Score/$t1Wickets', match.team1.shortName),
                      Text('VS', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white30)),
                      _buildTeamHeader(match.team2.name, '$t2Score/$t2Wickets', match.team2.shortName),
                    ],
                  ),
                  if (match.result.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        match.result,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.accentGreen, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Team 1 Scorecard (Batsmen & Bowlers)
            _buildTeamScorecardSection(match.team1),
            const SizedBox(height: 24),

            // 3. Team 2 Scorecard (Batsmen & Bowlers)
            _buildTeamScorecardSection(match.team2),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader(String name, String totalScore, String short) {
    return Column(
      children: [
        Text(short, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B8FA6), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          name.length > 12 ? '${name.substring(0, 10)}..' : name,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(totalScore, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accentGreen)),
      ],
    );
  }

  Widget _buildTeamScorecardSection(TeamModel team) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏏 ${team.name} Performance',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),

        // Batsmen Table
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder, width: 0.5),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF0D1B2A),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Batsman', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('R', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('B', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('4s', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('6s', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              // Table Rows (Players List)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: team.players.length,
                itemBuilder: (context, idx) {
                  final p = team.players[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                              if (p.isOut)
                                Text(p.outMode.isNotEmpty ? p.outMode : 'Out', style: GoogleFonts.poppins(fontSize: 11, color: Colors.redAccent))
                              else
                                Text('Not Out', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.accentGreen)),
                            ],
                          ),
                        ),
                        Expanded(child: Text('${p.runs}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold))),
                        Expanded(child: Text('${p.balls}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70))),
                        Expanded(child: Text('${p.fours}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70))),
                        Expanded(child: Text('${p.sixes}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70))),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Bowlers Table (Sirf unka data dikhane ke liye jinhone bowling ki)
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder, width: 0.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E1010), // Slight reddish background for bowling section
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('Bowler', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Overs', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Runs', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Wkt', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: team.players.where((p) => p.oversBowled > 0).length,
                itemBuilder: (context, idx) {
                  final bowlingPlayers = team.players.where((p) => p.oversBowled > 0).toList();
                  final p = bowlingPlayers[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(p.name, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500))),
                        Expanded(child: Text(p.oversStr, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white))),
                        Expanded(child: Text('${p.runsGiven}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: Colors.orangeAccent))),
                        Expanded(child: Text('${p.wicketsTaken}', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.accentGreen, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                },
              ),
              if (team.players.where((p) => p.oversBowled > 0).isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Is inning me kisi ne bowling nahi ki.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white38)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom Extension to prevent crash if match object parameters are missing
extension SafeMatchModel on MatchModel {
  int get lengthWickets {
    try {
      return wickets.length;
    } catch (_) {
      return 0;
    }
  }
}