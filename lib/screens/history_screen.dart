// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<MatchProvider>().matchHistory;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('📋 Match History')),
      body: history.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, size: 64, color: Color(0xFF6B8FA6)),
                const SizedBox(height: 16),
                Text('Koi match nahi hua abhi tak', style: GoogleFonts.poppins(
                  fontSize: 16, color: Colors.white70)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (_, i) {
              final m = history[i];
              final t1 = m['team1'] as Map<String, dynamic>? ?? {};
              final t2 = m['team2'] as Map<String, dynamic>? ?? {};
              final s = m['score'] as List<dynamic>? ?? [0, 0];
              final w = m['wickets'] as List<dynamic>? ?? [0, 0];
              return Container(
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
                        Expanded(child: Text(
                          '${t1['name'] ?? 'Team 1'} vs ${t2['name'] ?? 'Team 2'}',
                          style: GoogleFonts.poppins(fontSize: 15,
                              fontWeight: FontWeight.w700, color: Colors.white))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Khatam', style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.accentGreen)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _ScoreBox(
                          team: t1['name'] ?? 'T1',
                          score: '${s[0]}/${w[0]}',
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _ScoreBox(
                          team: t2['name'] ?? 'T2',
                          score: '${s[1]}/${w[1]}',
                        )),
                      ],
                    ),
                    if (m['result'] != null && (m['result'] as String).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(m['result'] as String, style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w600)),
                    ],
                  ],
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
          Text(team, style: GoogleFonts.poppins(
            fontSize: 12, color: const Color(0xFF6B8FA6))),
          const SizedBox(height: 4),
          Text(score, style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.accentGreen)),
        ],
      ),
    );
  }
}
