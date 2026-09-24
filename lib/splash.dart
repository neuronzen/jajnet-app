import 'dart:math';
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
  late final AnimationController _intro;
  late final AnimationController _halo;
  late final AnimationController _wave;
  late final AnimationController _bgShift;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _bgShift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 3800));
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
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, a, __, c) =>
  FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  void dispose() {
    _intro.dispose();
    _halo.dispose();
    _wave.dispose();
    _bgShift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgShift,
        builder: (_, __) {
final shift = _bgShift.value;
return Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: const [
        Color(0xFFFFB37A),
        Color(0xFFFF7A1A),
        Color(0xFFE55A00),
        Color(0xFFC94400),
      ],
      begin: Alignment(-1 + shift * 0.4, -1),
      end: Alignment(1, 1 - shift * 0.3),
    ),
  ),
  child: Stack(
    children: [
      ..._signalWaves(),
      ..._particles(size),
      SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              _logoWithHalo(),
              const SizedBox(height: 44),
              _animatedText(
                'JAJ Net',
                delay: 500,
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _animatedText(
                'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
                delay: 900,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.94),
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(flex: 3),
              _pulseDots(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    ],
  ),
);
        },
      ),
    );
  }

  List<Widget> _signalWaves() {
    return List.generate(5, (i) {
      return AnimatedBuilder(
        animation: _wave,
        builder: (_, __) {
final p = (_wave.value + i / 5.0) % 1.0;
final size = 80 + p * 480;
final opacity = (1.0 - p) * 0.5;
return Center(
  child: Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(
            opacity.clamp(0.0, 0.55)),
        width: 1.6,
      ),
    ),
  ),
);
        },
      );
    });
  }

  List<Widget> _particles(Size size) {
    final r = Random(13);
    return List.generate(40, (i) {
      final baseLeft = r.nextDouble() * size.width;
      final baseTop = r.nextDouble() * size.height;
      final dotSize = 1.5 + r.nextDouble() * 3.0;
      final delay = r.nextDouble();
      final swayAmp = 12 + r.nextDouble() * 30;
      final speed = 0.35 + r.nextDouble() * 0.55;
      final baseOpacity = 0.25 + r.nextDouble() * 0.5;
      return AnimatedBuilder(
        animation: _wave,
        builder: (_, __) {
final t = ((_wave.value * speed) + delay) % 1.0;
final xOff = sin(t * pi * 2) * swayAmp;
final yOff = -t * 140;
return Positioned(
  left: baseLeft + xOff,
  top: baseTop + yOff,
  child: Opacity(
    opacity: ((1 - t) * baseOpacity).clamp(0.0, 1.0),
    child: Container(
      width: dotSize,
      height: dotSize,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    ),
  ),
);
        },
      );
    });
  }

  Widget _logoWithHalo() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (_, __) {
        final t = Curves.easeOutBack
  .transform(_intro.value.clamp(0.0, 1.0));
        return SizedBox(
width: 220,
height: 220,
child: Stack(
  alignment: Alignment.center,
  children: [
    AnimatedBuilder(
      animation: _halo,
      builder: (_, __) {
        return Transform.rotate(
          angle: _halo.value * pi * 2,
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.7),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    ),
    Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.08),
      ),
    ),
    Transform.scale(
      scale: 0.3 + t * 0.7,
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Icon(
          Icons.wifi_rounded,
          size: 70,
          color: JC.primary,
        ),
      ),
    ),
  ],
),
        );
      },
    );
  }

  Widget _animatedText(String text, {
    required int delay,
    required TextStyle style,
  }) {
    return AnimatedBuilder(
      animation: _intro,
      builder: (_, __) {
        final threshold = delay / 2000.0;
        final t = ((_intro.value - threshold) / (1 - threshold))
  .clamp(0.0, 1.0);
        return Opacity(
opacity: t,
child: Transform.translate(
  offset: Offset(0, (1 - t) * 28),
  child: Text(text,
      textAlign: TextAlign.center, style: style),
),
        );
      },
    );
  }

  Widget _pulseDots() {
    return AnimatedBuilder(
      animation: _wave,
      builder: (_, __) {
        return Row(
mainAxisSize: MainAxisSize.min,
children: List.generate(3, (i) {
  final phase = (_wave.value + i * 0.2) % 1.0;
  final scale = 0.6 + (sin(phase * pi * 2) + 1) * 0.35;
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 5),
    child: Transform.scale(
      scale: scale,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}),
        );
      },
    );
  }
}
