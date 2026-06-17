// lib/screens/match_history_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MatchHistoryDetailScreen extends StatelessWidget {
  final MatchModel match;

  const MatchHistoryDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    // Score arrays se data safely nikalna null-safe fallback mechanics ke sath
    final t1Score = match.score.isNotEmpty ? match.score[0] : 0;
    final t2Score = match.score.length > 1 ? match.score[1] : 0;
    final t1Wickets = match.wickets.isNotEmpty ? match.wickets[0] : 0;
    final t2Wickets = match.wickets.length > 1 ? match.wickets[1] : 0;

    final t1Balls = match.balls.isNotEmpty ? match.balls[0] : 0;
    final t2Balls = match.balls.length > 1 ? match.balls[1] : 0;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
            '📊 Match Scorecard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Head-to-Head Main Score Board Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder, width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Team 1 Metrics
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                match.team1.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 6),
                            Text(
                                '$t1Score / $t1Wickets',
                                style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 22, fontWeight: FontWeight.w800)
                            ),
                            Text(
                                '(${_ballsToOvers(t1Balls)} ov)',
                                style: GoogleFonts.poppins(color: const Color(0xFF6B8FA6), fontSize: 12)
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                            'VS',
                            style: GoogleFonts.poppins(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.w900)
                        ),
                      ),

                      // Team 2 Metrics
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                match.team2.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 6),
                            Text(
                                '$t2Score / $t2Wickets',
                                style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 22, fontWeight: FontWeight.w800)
                            ),
                            Text(
                                '(${_ballsToOvers(t2Balls)} ov)',
                                style: GoogleFonts.poppins(color: const Color(0xFF6B8FA6), fontSize: 12)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Match Result Footer Announcement Section
                  if (match.result.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Divider(color: Colors.white12, height: 1),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      match.result,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: AppTheme.goldAccent, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildBattingTable(match.team1, '1st Innings Batting'),
            const SizedBox(height: 24),
            _buildBattingTable(match.team2, '2nd Innings Batting'),
          ],
        ),
      ),
    );
  }

  Widget _buildBattingTable(TeamModel team, String inningsTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
              '🏏 ${team.name} ($inningsTitle)',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder, width: 0.5),
          ),
          child: team.players.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Koi player stats available nahi hain',
                style: GoogleFonts.poppins(color: const Color(0xFF6B8FA6), fontSize: 12),
              ),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: team.players.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, idx) {
              final p = team.players[idx];

              // Strike rate metrics calculation
              final double sr = p.balls > 0 ? (p.runs / p.balls) * 100 : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)
                          ),
                          const SizedBox(height: 2),
                          Text(
                              'SR: ${sr.toStringAsFixed(1)}',
                              style: GoogleFonts.poppins(color: const Color(0xFF6B8FA6), fontSize: 11)
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildStatInlay('${p.runs}', 'R', isBold: true),
                          const SizedBox(width: 14),
                          _buildStatInlay('${p.balls}', 'B'),
                          const SizedBox(width: 14),
                          _buildStatInlay('${p.fours}', '4s'),
                          const SizedBox(width: 14),
                          _buildStatInlay('${p.sixes}', '6s'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatInlay(String value, String label, {bool isBold = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: isBold ? AppTheme.accentGreen : Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: const Color(0xFF6B8FA6), fontSize: 10),
        ),
      ],
    );
  }

  String _ballsToOvers(int totalBalls) {
    int overs = totalBalls ~/ 6;
    int balls = totalBalls % 6;
    return '$overs.$balls';
  }
}