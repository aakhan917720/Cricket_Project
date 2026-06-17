// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart'; // 🔥 MatchModel use karne ke liye models file import ki
import 'match_setup_screen.dart';
import 'tournament_screen.dart';
import 'history_screen.dart';
import 'scoring_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;

  final List<Widget> _pages = const [
    _HomeTab(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentIndex == 0 ? _pages[0] : const _HomeTab(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F35),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E3A5F), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.sports_cricket_rounded,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.add_circle_outline_rounded,
                label: 'Naya Match',
                isActive: _currentIndex == 1,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MatchSetupScreen()),
                  ).then((_) => setState(() => _currentIndex = 0));
                },
              ),
              _NavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Tournament',
                isActive: _currentIndex == 2,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TournamentScreen()),
                  ).then((_) => setState(() => _currentIndex = 0));
                },
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                isActive: _currentIndex == 3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ).then((_) => setState(() => _currentIndex = 0));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Home Tab
// ============================================================
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Top Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF0D2137)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_cricket_rounded,
                          color: Color(0xFF4CAF50), size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Cricket Scorer',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Professional Cricket Scoring App',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF81C784),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.hasActiveMatch) ...[
                    _ActiveMatchCard(match: provider.currentMatch!),
                    const SizedBox(height: 16),
                  ],

                  _SectionTitle(title: 'Quick Stats'),
                  const SizedBox(height: 12),
                  _StatsGrid(matchHistory: provider.matchHistory),
                  const SizedBox(height: 20),

                  _SectionTitle(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveMatchCard extends StatelessWidget {
  final dynamic match;
  const _ActiveMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ScoringScreen(match: match))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4CAF50), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('LIVE', style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white,
                  )),
                ),
                const SizedBox(width: 10),
                Text(
                  '${match.team1.name} vs ${match.team2.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${match.currentScore}/${match.currentWickets}',
                  style: GoogleFonts.poppins(
                    fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(match.oversDisplay,
                        style: GoogleFonts.poppins(fontSize: 18,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('CRR: ${match.currentRunRate.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontSize: 13,
                            color: const Color(0xFF81C784))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.touch_app, size: 14, color: Color(0xFF81C784)),
                const SizedBox(width: 4),
                Text('Score update karne ke liye tap karein',
                    style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF81C784))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🔥 FIXED WIDGET (List<Map> se hata kar List<MatchModel> kiya)
// ============================================================
class _StatsGrid extends StatelessWidget {
  final List<MatchModel> matchHistory; // 👈 Map ki jagah sahi type likh diya
  const _StatsGrid({required this.matchHistory});

  @override
  Widget build(BuildContext context) {
    final total = matchHistory.length;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(icon: Icons.sports_cricket, label: 'Total Matches', value: '$total',
            color: const Color(0xFF4CAF50)),
        _StatCard(icon: Icons.emoji_events, label: 'Tournaments', value: '0',
            color: const Color(0xFFFFD700)),
        _StatCard(icon: Icons.people, label: 'Teams', value: '0',
            color: const Color(0xFF42A5F5)),
        _StatCard(icon: Icons.trending_up, label: 'Avg Score', value: '--',
            color: const Color(0xFFFF7043)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(label, style: GoogleFonts.poppins(
                  fontSize: 11, color: const Color(0xFF6B8FA6))),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction('Naya Match', Icons.add_circle_outline, const Color(0xFF2E7D32),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchSetupScreen()))),
      _QuickAction('Tournament', Icons.emoji_events_outlined, const Color(0xFF1565C0),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentScreen()))),
      _QuickAction('History', Icons.history_rounded, const Color(0xFF6A1B9A),
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
      _QuickAction('Settings', Icons.settings_outlined, const Color(0xFF37474F),
              () => _showSettings(context)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: actions.map((a) => GestureDetector(
        onTap: a.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: a.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a.color.withOpacity(0.4), width: 0.8),
          ),
          child: Row(
            children: [
              Icon(a.icon, color: a.color, size: 22),
              const SizedBox(width: 8),
              Text(a.label, style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.label, this.icon, this.color, this.onTap);
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Settings', style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),
          _SettingsTile(icon: Icons.cloud_sync, label: 'Firebase Sync',
              subtitle: '🔥 Firebase setup karne ke baad active hoga',
              trailing: const Icon(Icons.toggle_off, color: Colors.grey, size: 32)),
          _SettingsTile(icon: Icons.notifications, label: 'Notifications', trailing:
          const Icon(Icons.toggle_on, color: Color(0xFF4CAF50), size: 32)),
          _SettingsTile(icon: Icons.dark_mode, label: 'Dark Mode', trailing:
          const Icon(Icons.toggle_on, color: Color(0xFF4CAF50), size: 32)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget trailing;
  const _SettingsTile({required this.icon, required this.label,
    this.subtitle, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle!, style: GoogleFonts.poppins(
          color: const Color(0xFF6B8FA6), fontSize: 11)) : null,
      trailing: trailing,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 18, color: const Color(0xFF4CAF50),
            margin: const EdgeInsets.only(right: 8)),
        Text(title, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.label,
    required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1B5E20).withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF4CAF50) : const Color(0xFF6B8FA6),
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? const Color(0xFF4CAF50) : const Color(0xFF6B8FA6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}