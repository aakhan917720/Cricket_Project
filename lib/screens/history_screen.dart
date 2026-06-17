// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import 'match_history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchProvider>();

    // Direct Filtering utilizing strongly-typed objects
    final filteredMatches = provider.matchHistory.where((m) {
      final name1 = m.team1.name.toLowerCase();
      final name2 = m.team2.name.toLowerCase();
      return name1.contains(_searchQuery) || name2.contains(_searchQuery);
    }).toList();

    final filteredTournaments = provider.tournaments.where((t) {
      return t.name.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.cardBg,
        title: Text('📜 Scoring History', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGreen,
          labelColor: AppTheme.accentGreen,
          unselectedLabelColor: const Color(0xFF6B8FA6),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [Tab(text: 'Single Matches'), Tab(text: 'Tournaments')],
        ),
      ),
      body: Column(
        children: [
          // Styled Search Bar container
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.cardBg,
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Team ya tournament search karein...',
                hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B8FA6)),
                filled: true,
                fillColor: const Color(0xFF071524),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Single Matches List view
                filteredMatches.isEmpty
                    ? _buildEmptyState('Koi single match nahi mila')
                    : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: filteredMatches.length,
                  itemBuilder: (context, idx) {
                    final match = filteredMatches[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                            '${match.team1.name} vs ${match.team2.name}',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              match.result.isNotEmpty ? match.result : 'Match completed',
                              style: GoogleFonts.poppins(color: AppTheme.accentGreen, fontSize: 12)
                          ),
                        ),
                        trailing: const Icon(Icons.bar_chart, color: AppTheme.accentGreen),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MatchHistoryDetailScreen(match: match))
                        ),
                      ),
                    );
                  },
                ),

                // Tab 2: Tournaments List view
                filteredTournaments.isEmpty
                    ? _buildEmptyState('Koi tournament nahi mila')
                    : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: filteredTournaments.length,
                  itemBuilder: (context, idx) {
                    final tourney = filteredTournaments[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
                        title: Text(
                            tourney.name,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                              '${tourney.teams.length} Teams | ${tourney.schedule.length} Matches',
                              style: GoogleFonts.poppins(color: const Color(0xFF6B8FA6), fontSize: 12)
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                        onTap: () {
                          provider.setCurrentTournament(tourney);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🏆 ${tourney.name} Active Tournament tab par select ho gaya!', style: GoogleFonts.poppins()),
                                backgroundColor: AppTheme.accentGreen,
                              )
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Text(
          msg,
          style: GoogleFonts.poppins(color: const Color(0xFF6B8FA6), fontSize: 14, fontWeight: FontWeight.w500)
      ),
    );
  }
}