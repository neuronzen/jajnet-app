import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import 'onboarding.dart';
import 'screens.dart';
import 'services.dart';
import 'theme.dart';

class SplashScreenNew extends StatefulWidget {
  const SplashScreenNew({super.key});
  @override
  State<SplashScreenNew> createState() => _SplashScreenNewState();
}

class _SplashScreenNewState extends State<SplashScreenNew>
    with TickerProviderStateMixin {
  late final AnimationController _master;    // 2.8s master timeline
  late final AnimationController _dotPulse;  // center dot pulse
  late final AnimationController _wave;      // signal arcs repeat
  late final AnimationController _dots;      // loading dots
  late final AnimationController _rotate;    // bg rings rotate

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
    _dotPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    final loggedIn = AuthService.currentUser != null;
    if (!mounted) return;
    final Widget next;
    if (loggedIn) {
      next = const MainShell();
    } else if (seen) {
      next = const LoginScreenNew();
    } else {
      next = const OnboardingScreen();
    }
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  void dispose() {
    _master.dispose();
    _dotPulse.dispose();
    _wave.dispose();
    _dots.dispose();
    _rotate.dispose();
    super.dispose();
  }

  // Map master value to a staged 0..1 progress
  double _stage(double from, double to, {Curve curve = Curves.easeOut}) {
    final v = _master.value;
    if (v <= from) return 0;
    if (v >= to) return 1;
    return curve.transform((v - from) / (to - from));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB53D00),
              Color(0xFFE55A00),
              Color(0xFFFF6B00),
              Color(0xFFFF9F5A),
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Stack(
          children: [
            // Subtle grid pattern
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            // Rotating transparent rings (background)
            Positioned.fill(child: _backgroundRings()),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ..._signalArcs(),
                        ..._particles(size),
                        _centerDot(),
                        _logo(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _brandName(),
                  const SizedBox(height: 14),
                  _tagline(),
                  const Spacer(flex: 4),
                  _loadingDots(),
                  const SizedBox(height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ STAGE 1: Center dot ============
  Widget _centerDot() {
    return AnimatedBuilder(
      animation: Listenable.merge([_master, _dotPulse]),
      builder: (_, __) {
        final appear = _stage(0.0, 0.18, curve: Curves.easeIn);
        // Hide when logo starts appearing (Stage 3)
        final fade = 1.0 - _stage(0.5, 0.62);
        final opacity = appear * fade;
        if (opacity <= 0.01) return const SizedBox.shrink();
        final scale = 1.0 + _dotPulse.value * 0.3;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: 22,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============ STAGE 2: Signal arcs ============
  List<Widget> _signalArcs() {
    return List.generate(4, (i) {
      return AnimatedBuilder(
        animation: Listenable.merge([_master, _wave]),
        builder: (_, __) {
          // Stage: appear between 0.15 and 0.55 in master timeline
          final appear = _stage(0.15 + i * 0.06, 0.35 + i * 0.06);
          // Fade out as logo comes in
          final fade = 1.0 - _stage(0.5, 0.65);
          final baseOpacity = appear * fade * 0.7;
          if (baseOpacity <= 0.01) return const SizedBox.shrink();

          // Animated wave radius — outward pulse
          final waveP = ((_wave.value + i / 4) % 1.0);
          final size = 60.0 + i * 32 + waveP * 24;
          final opacity = baseOpacity * (1 - waveP) * 1.4;

          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(
                          opacity.clamp(0.0, 0.75)),
                      width: 1.8,
                    ),
                  ),
                ),
                // Small bright particle on the right edge
                Align(
                  alignment: const Alignment(1.0, -0.4),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                          opacity.clamp(0.0, 1.0)),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // ============ STAGE 2b: Particles ============
  List<Widget> _particles(Size size) {
    final r = math.Random(13);
    final data = List.generate(24, (i) {
      return {
        'x': r.nextDouble() * 2 - 1,
        'y': r.nextDouble() * 2 - 1,
        'delay': r.nextDouble() * 0.4,
        'speed': 0.6 + r.nextDouble() * 0.6,
        'size': 2.0 + r.nextDouble() * 2.0,
      };
    });

    return data.map((d) {
      return AnimatedBuilder(
        animation: Listenable.merge([_master, _wave]),
        builder: (_, __) {
          final appear = _stage(0.15 + d['delay'], 0.5);
          final fade = 1.0 - _stage(0.55, 0.7);
          final base = (appear * fade).clamp(0.0, 1.0);
          if (base <= 0.01) return const SizedBox.shrink();

          final w = _wave.value;
          final t = (w * d['speed'] + d['delay']) % 1.0;
          final x = d['x'] * 100;
          final y = d['y'] * 100 - t * 80;
          final opacity = base * (1 - t) * 0.9;

          return Transform.translate(
            offset: Offset(x, y),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: d['size'],
                height: d['size'],
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  // ============ STAGE 3: Logo ============
  Widget _logo() {
    return AnimatedBuilder(
      animation: _master,
      builder: (_, __) {
        final t = _stage(0.5, 0.75, curve: Curves.easeOutBack);
        if (t <= 0.01) return const SizedBox.shrink();

        // burst glow
        final burst = _stage(0.5, 0.85);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Burst glow
            Opacity(
              opacity: (1 - burst) * 0.6 + 0.4,
              child: Transform.scale(
                scale: 1.0 + burst * 0.8,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Logo card
            Transform.scale(
              scale: 0.3 + t * 0.7,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.35),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/logo/jajnet-logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.wifi_rounded,
                        size: 56,
                        color: JC.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============ STAGE 4: Brand name ============
  Widget _brandName() {
    return AnimatedBuilder(
      animation: _master,
      builder: (_, __) {
        final t = _stage(0.65, 0.85);
        if (t <= 0.01) return const SizedBox.shrink();
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 24),
            child: Column(
              children: [
                Text(
                  'JAJ Net',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                // Gold underline draw effect
                AnimatedBuilder(
                  animation: _master,
                  builder: (_, __) {
                    final w = _stage(0.75, 0.95);
                    return Container(
                      width: 50 * w,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB547),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============ STAGE 5: Tagline ============
  Widget _tagline() {
    return AnimatedBuilder(
      animation: _master,
      builder: (_, __) {
        final t = _stage(0.8, 0.98);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Text(
            'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14.5,
              color: Colors.white.withOpacity(0.94),
              letterSpacing: 0.4,
              height: 1.5,
            ),
          ),
        );
      },
    );
  }

  // ============ Loading dots ============
  Widget _loadingDots() {
    return AnimatedBuilder(
      animation: Listenable.merge([_master, _dots]),
      builder: (_, __) {
        final appear = _stage(0.85, 1.0);
        return Opacity(
          opacity: appear.clamp(0.0, 1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final phase = (_dots.value + i * 0.15) % 1.0;
              final scale = 0.65 + math.sin(phase * math.pi * 2) * 0.35 + 0.35;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                child: Transform.scale(
                  scale: scale.clamp(0.6, 1.4),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ============ Background rings ============
  Widget _backgroundRings() {
    return AnimatedBuilder(
      animation: _rotate,
      builder: (_, __) {
        return CustomPaint(
          painter: _RingsPainter(rotation: _rotate.value),
        );
      },
    );
  }
}

// ============ Custom Painters ============

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RingsPainter extends CustomPainter {
  final double rotation;
  _RingsPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width * 0.5, size.height * 0.42);
    for (int i = 0; i < 3; i++) {
      final r = 140.0 + i * 90;
      canvas.drawCircle(center, r, paint);
    }

    // slow rotating small dashes
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rotateCenter =
        Offset(size.width * 0.85, size.height * 0.15);
    final path = Path();
    final startA = rotation * 2 * math.pi;
    final endA = startA + math.pi / 4;
    path.addArc(
      Rect.fromCircle(center: rotateCenter, radius: 60),
      startA,
      endA - startA,
    );
    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.rotation != rotation;
}
