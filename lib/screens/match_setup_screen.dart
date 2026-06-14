// lib/screens/match_setup_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/match_provider.dart';
import '../theme/app_theme.dart';
import '../services/firebase_service.dart';
import 'toss_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();

  // Match settings
  int _totalOvers = 20;
  int _playersPerTeam = 11;

  // Team 1
  final _team1NameCtrl = TextEditingController(text: 'Team A');
  File? _team1Logo;
  final List<TextEditingController> _team1Players = [];
  final List<File?> _team1Photos = [];

  // Team 2
  final _team2NameCtrl = TextEditingController(text: 'Team B');
  File? _team2Logo;
  final List<TextEditingController> _team2Players = [];
  final List<File?> _team2Photos = [];

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initPlayers(11);
  }

  void _initPlayers(int count) {
    _team1Players.clear();
    _team2Players.clear();
    _team1Photos.clear();
    _team2Photos.clear();

    for (int i = 0; i < count; i++) {
      _team1Players.add(TextEditingController(text: 'Player ${i + 1}'));
      _team2Players.add(TextEditingController(text: 'Player ${i + 1}'));
      _team1Photos.add(null);
      _team2Photos.add(null);
    }
  }

  void _updatePlayerCount(int count) {
    setState(() {
      _playersPerTeam = count;
      _initPlayers(count);
    });
  }

  Future<void> _pickTeamLogo(bool isTeam1) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        if (isTeam1) {
          _team1Logo = File(picked.path);
        } else {
          _team2Logo = File(picked.path);
        }
      });
    }
  }

  Future<void> _pickPlayerPhoto(bool isTeam1, int playerIdx) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() {
        if (isTeam1) {
          _team1Photos[playerIdx] = File(picked.path);
        } else {
          _team2Photos[playerIdx] = File(picked.path);
        }
      });
    }
  }

  Future<void> _goToToss() async {
    if (_team1NameCtrl.text.isEmpty || _team2NameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team ke naam zaruri hain!')));
      return;
    }

    // Build team models
    final team1 = TeamModel(
      id: _uuid.v4(),
      name: _team1NameCtrl.text,
      logoPath: _team1Logo?.path,
      players: List.generate(_playersPerTeam, (i) => PlayerModel(
        id: _uuid.v4(),
        name: _team1Players[i].text.isEmpty
            ? '${_team1NameCtrl.text} P${i + 1}'
            : _team1Players[i].text,
        photoPath: _team1Photos[i]?.path,
        jerseyNumber: i + 1,
      )),
    );

    final team2 = TeamModel(
      id: _uuid.v4(),
      name: _team2NameCtrl.text,
      logoPath: _team2Logo?.path,
      players: List.generate(_playersPerTeam, (i) => PlayerModel(
        id: _uuid.v4(),
        name: _team2Players[i].text.isEmpty
            ? '${_team2NameCtrl.text} P${i + 1}'
            : _team2Players[i].text,
        photoPath: _team2Photos[i]?.path,
        jerseyNumber: i + 1,
      )),
    );

    // 🔥 FIREBASE: Teams ko Firebase mein save karo
    final firebase = FirebaseService();
    await firebase.saveTeam(team1);
    await firebase.saveTeam(team2);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TossScreen(
            team1: team1,
            team2: team2,
            totalOvers: _totalOvers,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _team1NameCtrl.dispose();
    _team2NameCtrl.dispose();
    for (var c in _team1Players) c.dispose();
    for (var c in _team2Players) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Naya Match Setup'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGreen,
          labelColor: AppTheme.accentGreen,
          unselectedLabelColor: const Color(0xFF6B8FA6),
          tabs: const [
            Tab(text: 'Match'),
            Tab(text: 'Team 1'),
            Tab(text: 'Team 2'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MatchSettingsTab(
            totalOvers: _totalOvers,
            playersPerTeam: _playersPerTeam,
            onOversChanged: (v) => setState(() => _totalOvers = v),
            onPlayersChanged: _updatePlayerCount,
          ),
          _TeamSetupTab(
            teamNumber: 1,
            nameCtrl: _team1NameCtrl,
            logo: _team1Logo,
            players: _team1Players,
            photos: _team1Photos,
            onPickLogo: () => _pickTeamLogo(true),
            onPickPhoto: (i) => _pickPlayerPhoto(true, i),
            playersCount: _playersPerTeam,
          ),
          _TeamSetupTab(
            teamNumber: 2,
            nameCtrl: _team2NameCtrl,
            logo: _team2Logo,
            players: _team2Players,
            photos: _team2Photos,
            onPickLogo: () => _pickTeamLogo(false),
            onPickPhoto: (i) => _pickPlayerPhoto(false, i),
            playersCount: _playersPerTeam,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppTheme.darkBg,
        child: ElevatedButton.icon(
          onPressed: _goToToss,
          icon: const Icon(Icons.sports_cricket_rounded),
          label: const Text('Toss Ke Liye Jao →'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Match Settings Tab
// ============================================================
class _MatchSettingsTab extends StatelessWidget {
  final int totalOvers;
  final int playersPerTeam;
  final ValueChanged<int> onOversChanged;
  final ValueChanged<int> onPlayersChanged;

  const _MatchSettingsTab({
    required this.totalOvers,
    required this.playersPerTeam,
    required this.onOversChanged,
    required this.onPlayersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overs Selector (1-50)
          _SetupCard(
            title: '🏏 Overs (1-50)',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$totalOvers',
                      style: GoogleFonts.poppins(
                        fontSize: 48, fontWeight: FontWeight.w900,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('overs', style: GoogleFonts.poppins(
                      fontSize: 18, color: Colors.white70)),
                  ],
                ),
                Slider(
                  value: totalOvers.toDouble(),
                  min: 1, max: 50, divisions: 49,
                  activeColor: AppTheme.accentGreen,
                  inactiveColor: AppTheme.cardBorder,
                  onChanged: (v) => onOversChanged(v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [1, 5, 10, 20, 50].map((o) =>
                    GestureDetector(
                      onTap: () => onOversChanged(o),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: totalOvers == o
                              ? AppTheme.lightGreen
                              : AppTheme.cardBorder.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$o', style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: totalOvers == o ? Colors.white : Colors.grey,
                        )),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Players per team (1-11)
          _SetupCard(
            title: '👥 Players In Team (1-11)',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$playersPerTeam', style: GoogleFonts.poppins(
                      fontSize: 48, fontWeight: FontWeight.w900,
                      color: AppTheme.goldAccent,
                    )),
                    const SizedBox(width: 8),
                    Text('players', style: GoogleFonts.poppins(
                      fontSize: 18, color: Colors.white70)),
                  ],
                ),
                Slider(
                  value: playersPerTeam.toDouble(),
                  min: 1, max: 11, divisions: 10,
                  activeColor: AppTheme.goldAccent,
                  inactiveColor: AppTheme.cardBorder,
                  onChanged: (v) => onPlayersChanged(v.round()),
                ),
                Wrap(
                  spacing: 8,
                  children: [1, 5, 6, 7, 8, 9, 10, 11].map((n) =>
                    GestureDetector(
                      onTap: () => onPlayersChanged(n),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: playersPerTeam == n
                              ? const Color(0xFF7B6000)
                              : AppTheme.cardBorder.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$n', style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: playersPerTeam == n ? AppTheme.goldAccent : Colors.grey,
                        )),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Team Setup Tab (with player photos)
// ============================================================
class _TeamSetupTab extends StatelessWidget {
  final int teamNumber;
  final TextEditingController nameCtrl;
  final File? logo;
  final List<TextEditingController> players;
  final List<File?> photos;
  final VoidCallback onPickLogo;
  final ValueChanged<int> onPickPhoto;
  final int playersCount;

  const _TeamSetupTab({
    required this.teamNumber,
    required this.nameCtrl,
    required this.logo,
    required this.players,
    required this.photos,
    required this.onPickLogo,
    required this.onPickPhoto,
    required this.playersCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Team name + logo
          _SetupCard(
            title: 'Team $teamNumber Ki Details',
            child: Column(
              children: [
                Row(
                  children: [
                    // Logo picker
                    GestureDetector(
                      onTap: onPickLogo,
                      child: Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBorder,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentGreen.withOpacity(0.5)),
                        ),
                        child: logo != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(logo!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate,
                                    color: Color(0xFF6B8FA6), size: 26),
                                Text('Logo', style: GoogleFonts.poppins(
                                  fontSize: 10, color: const Color(0xFF6B8FA6))),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: 'Team Ka Naam',
                          prefixIcon: Icon(Icons.shield_outlined,
                              color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Players
          _SetupCard(
            title: 'Players ($playersCount)',
            child: Column(
              children: List.generate(playersCount, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // Player photo
                    GestureDetector(
                      onTap: () => onPickPhoto(i),
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBorder,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.cardBorder, width: 0.5),
                        ),
                        child: photos[i] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(photos[i]!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_add_alt,
                                    size: 20, color: Colors.grey[600]),
                                Text('Pic', style: TextStyle(
                                  fontSize: 9, color: Colors.grey[600])),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Jersey number
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('${i + 1}', style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: AppTheme.accentGreen,
                        )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name input
                    Expanded(
                      child: TextField(
                        controller: players[i],
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Player ${i + 1} ka naam',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable setup card
class _SetupCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SetupCard({required this.title, required this.child});

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
          Text(title, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: const Color(0xFF6B8FA6),
            letterSpacing: 0.3,
          )),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
