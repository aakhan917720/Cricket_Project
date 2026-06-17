// lib/screens/recent_matches.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../models/models.dart';
import 'match_history_detail_screen.dart';

class RecentMatchesScreen extends StatelessWidget {
  const RecentMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyRaw = context.watch<MatchProvider>().matchHistory;

    // Fixed warning: dynamic list casting cleaned up properly
    final List<MatchModel> recentMatches = historyRaw
        .map((m) => MatchModel.fromMap(Map<String, dynamic>.from(m as Map<dynamic, dynamic>)))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF060F1E), // Match with your AppTheme background
      appBar: AppBar(
        title: const Text("Recent Matches"),
        elevation: 0,
      ),
      body: recentMatches.isEmpty
          ? const Center(
        child: Text(
          "No recent matches found.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: recentMatches.length,
        itemBuilder: (context, index) {
          final match = recentMatches[index];
          return Card(
            color: const Color(0xFF111E2E),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                "${match.team1.name} vs ${match.team2.name}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  match.result,
                  style: const TextStyle(color: Colors.greenAccent),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchHistoryDetailScreen(match: match),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}