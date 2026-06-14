// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/match_provider.dart' show MatchProvider;
import '../theme/app_theme.dart';
import 'match_history_detail_screen.dart'; // 🔥 Fix: Sahi detail screen import ki

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> historyRaw = context.watch<MatchProvider>().matchHistory;
    final List<MatchModel> history = historyRaw
        .map((m) => MatchModel.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg,
        title: Text('📋 Match History', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
      body: history.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Color(0xFF6B8FA6)),
            const SizedBox(height: 16),
            Text(
              'Koi match nahi hua abhi tak',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, i) {
          final match = history[i];
          final team1Name = match.team1.name;
          final team2Name = match.team2.name;

          return GestureDetector(
            onTap: () {
              // 🚀 FIXED ACTION: Ab click karne par actual history detail screen par jayega
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchHistoryDetailScreen(match: match),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$team1Name vs $team2Name',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen.withValues(alpha: 0.2), // Updated to withValues
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Khatam',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.accentGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreBox(
                          team: match.team1.shortName,
                          score: '${match.score[0]}/${match.wickets[0]}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ScoreBox(
                          team: match.team2.shortName,
                          score: '${match.score[1]}/${match.wickets[1]}',
                        ),
                      ),
                    ],
                  ),
                  if (match.result.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 8),
                    Text(
                      match.result,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String team;
  final String score;
  const _ScoreBox({required this.team, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF071524),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            team,
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B8FA6)),
          ),
          const SizedBox(height: 4),
          Text(
            score,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentGreen,
            ),
          ),
        ],
      ),
    );
  }
}