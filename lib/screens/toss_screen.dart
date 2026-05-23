// lib/screens/toss_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'scoring_screen.dart';

class TossScreen extends StatefulWidget {
  final TeamModel team1;
  final TeamModel team2;
  final int totalOvers;

  const TossScreen({
    super.key,
    required this.team1,
    required this.team2,
    required this.totalOvers,
  });

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _coinController;
  late Animation<double> _flipAnimation;

  bool _isFlipping = false;
  bool _tossComplete = false;
  String? _tossWinner;     // Team name
  String? _tossDecision;   // 'bat' or 'bowl'
  int _selectedTeamIdx = 0; // 0 = team1, 1 = team2
  String _selectedCall = 'heads'; // heads / tails

  final _random = math.Random();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 6 * math.pi)
        .animate(CurvedAnimation(parent: _coinController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  Future<void> _flipCoin() async {
    if (_isFlipping) return;
    setState(() {
      _isFlipping = true;
      _tossComplete = false;
    });

    await _coinController.forward(from: 0);

    // Determine result
    final coinResult = _random.nextBool() ? 'heads' : 'tails';
    final won = coinResult == _selectedCall;

    setState(() {
      _isFlipping = false;
      _tossComplete = true;
      _tossWinner = won
          ? ((_selectedTeamIdx == 0) ? widget.team1.name : widget.team2.name)
          : ((_selectedTeamIdx == 0) ? widget.team2.name : widget.team1.name);
    });
  }

  void _selectDecision(String decision) {
    setState(() => _tossDecision = decision);
  }

  void _startMatch() {
    if (_tossWinner == null || _tossDecision == null) return;

    int batFirstTeamIdx;
    if (_tossDecision == 'bat') {
      // Toss winner bats
      batFirstTeamIdx = _tossWinner == widget.team1.name ? 0 : 1;
    } else {
      // Toss winner bowls, other team bats
      batFirstTeamIdx = _tossWinner == widget.team1.name ? 1 : 0;
    }

    final match = MatchModel(
      id: _uuid.v4(),
      team1: widget.team1,
      team2: widget.team2,
      totalOvers: widget.totalOvers,
      batFirstTeamIdx: batFirstTeamIdx,
      tossWinner: _tossWinner!,
      tossDecision: _tossDecision!,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ScoringScreen(match: match)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Toss')),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Teams display
                Row(
                  children: [
                    Expanded(child: _TeamCard(
                      team: widget.team1,
                      isSelected: _selectedTeamIdx == 0,
                      onTap: () => setState(() => _selectedTeamIdx = 0),
                    )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('VS', style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        color: AppTheme.goldAccent,
                      )),
                    ),
                    Expanded(child: _TeamCard(
                      team: widget.team2,
                      isSelected: _selectedTeamIdx == 1,
                      onTap: () => setState(() => _selectedTeamIdx = 1),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Toss karne wali team chuno',
                  style: GoogleFonts.poppins(fontSize: 13,
                      color: const Color(0xFF6B8FA6)),
                ),
                const SizedBox(height: 30),

                // Coin call
                Text('Call Karo', style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CallButton(
                      label: '👑 Heads',
                      isSelected: _selectedCall == 'heads',
                      onTap: () => setState(() => _selectedCall = 'heads'),
                    ),
                    const SizedBox(width: 16),
                    _CallButton(
                      label: '🦅 Tails',
                      isSelected: _selectedCall == 'tails',
                      onTap: () => setState(() => _selectedCall = 'tails'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Animated Coin
                AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (_, __) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(_flipAnimation.value),
                      child: Container(
                        width: 130, height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.goldAccent,
                              const Color(0xFFFF8F00),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldAccent.withOpacity(0.4),
                              blurRadius: 20, spreadRadius: 2),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isFlipping ? '🪙' :
                                (_tossComplete ? '✅' : '🪙'),
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),

                // Flip button
                if (!_tossComplete)
                  ElevatedButton.icon(
                    onPressed: _isFlipping ? null : _flipCoin,
                    icon: const Icon(Icons.rotate_right),
                    label: Text(_isFlipping ? 'Flip ho raha hai...' : '🪙 Coin Flip Karo!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                // Toss result
                if (_tossComplete) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Text('🎉 Toss Jeeta!', style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppTheme.accentGreen,
                        )),
                        const SizedBox(height: 6),
                        Text(_tossWinner!, style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: Colors.white,
                        )),
                        const SizedBox(height: 20),
                        Text('Ab kya karna chahte hain?', style: GoogleFonts.poppins(
                          fontSize: 14, color: const Color(0xFF6B8FA6))),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _DecisionButton(
                              label: '🏏 Batting',
                              isSelected: _tossDecision == 'bat',
                              onTap: () => _selectDecision('bat'),
                            ),
                            const SizedBox(width: 14),
                            _DecisionButton(
                              label: '⚾ Bowling',
                              isSelected: _tossDecision == 'bowl',
                              onTap: () => _selectDecision('bowl'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_tossDecision != null)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _startMatch,
                              icon: const Icon(Icons.sports_cricket_rounded),
                              label: const Text('Match Shuru Karo! 🏏'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final bool isSelected;
  final VoidCallback onTap;

  const _TeamCard({
    required this.team, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightGreen.withOpacity(0.2)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.accentGreen : AppTheme.cardBorder,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Column(
          children: [
            // Logo
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: team.logoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(team.logoPath!), fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      team.shortName,
                      style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 8),
            Text(team.name, style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
              textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Selected', style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CallButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldAccent.withOpacity(0.2)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.goldAccent : AppTheme.cardBorder,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Text(label, style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: isSelected ? AppTheme.goldAccent : Colors.grey,
        )),
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DecisionButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightGreen : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentGreen : AppTheme.cardBorder),
        ),
        child: Text(label, style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : Colors.grey,
        )),
      ),
    );
  }
}
