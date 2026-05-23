// lib/screens/splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ballController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;

  late Animation<double> _ballRotation;
  late Animation<double> _ballScale;
  late Animation<double> _fadeAnim;
  late Animation<double> _logoScale;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Ball spin animation
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ballRotation = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _ballController, curve: Curves.easeInOut));
    _ballScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ballController, curve: Curves.elasticOut));

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Logo scale
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut));

    // Slide animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Ball spins in
    await _ballController.forward();

    // Logo fades in
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    _scaleController.forward();

    // Text slides up
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();

    // Wait then navigate
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Fade out and navigate
      await _fadeController.reverse();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const DashboardScreen(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ballController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF1B5E20),
              Color(0xFF0A1628),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Cricket Ball
                  AnimatedBuilder(
                    animation: _ballController,
                    builder: (_, __) {
                      return Transform.scale(
                        scale: _ballScale.value,
                        child: Transform.rotate(
                          angle: _ballRotation.value,
                          child: const _CricketBallWidget(size: 100),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // App Title
                  ScaleTransition(
                    scale: _logoScale,
                    child: Text(
                      'Cricket Scorer',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4CAF50),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle slide up
                  SlideTransition(
                    position: _slideAnim,
                    child: Text(
                      'Professional Cricket Scoring',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF81C784),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Animated pitch lines
                  SlideTransition(
                    position: _slideAnim,
                    child: const _PitchAnimation(),
                  ),

                  const SizedBox(height: 40),

                  // Loading dots
                  SlideTransition(
                    position: _slideAnim,
                    child: const _LoadingDots(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painted cricket ball
class _CricketBallWidget extends StatelessWidget {
  final double size;
  const _CricketBallWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CricketBallPainter(),
    );
  }
}

class _CricketBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ball body
    final paint = Paint()
      ..color = const Color(0xFFB71C1C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);

    // Shine effect
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.3, center.dy - radius * 0.3),
      radius * 0.3,
      shinePaint,
    );

    // Seam
    final seamPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Horizontal seam
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.6),
      -math.pi * 0.3,
      math.pi * 0.6,
      false,
      seamPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.6),
      math.pi * 0.7,
      math.pi * 0.6,
      false,
      seamPaint,
    );

    // Seam stitches
    final stitchPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 5; i++) {
      double x = center.dx + (i - 2) * radius * 0.2;
      canvas.drawLine(
        Offset(x, center.dy - 6),
        Offset(x, center.dy + 6),
        stitchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PitchAnimation extends StatelessWidget {
  const _PitchAnimation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) => Container(
            width: 8,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            double phase = (_controller.value - i * 0.2).clamp(0.0, 1.0);
            double opacity = math.sin(phase * math.pi).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
