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
  late final AnimationController _pulse;
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(milliseconds: 3400));
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
    _intro.dispose();
    _pulse.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: JC.heroGradient),
        child: Stack(
children: [
  ..._waves(),
  ..._particles(size),
  SafeArea(
    child: Column(
      children: [
        const Spacer(flex: 3),
        _logo(),
        const SizedBox(height: 40),
        _name(),
        const SizedBox(height: 14),
        _tagline(),
        const Spacer(flex: 4),
        _loader(),
        const SizedBox(height: 44),
      ],
    ),
  ),
],
        ),
      ),
    );
  }

  List<Widget> _waves() {
    return List.generate(4, (i) {
      return AnimatedBuilder(
        animation: _wave,
        builder: (_, __) {
final p = (_wave.value + i / 4) % 1.0;
final scale = 0.4 + p * 2.2;
final opacity = (1.0 - p) * 0.4;
return Center(
  child: Transform.scale(
    scale: scale,
    child: Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white
              .withOpacity(opacity.clamp(0.0, 1.0)),
          width: 1.4,
        ),
      ),
    ),
  ),
);
        },
      );
    });
  }

  List<Widget> _particles(Size size) {
    final r = Random(11);
    return List.generate(30, (i) {
      final left = r.nextDouble() * size.width;
      final baseTop = r.nextDouble() * size.height;
      final sz = 2.0 + r.nextDouble() * 3.5;
      final delay = r.nextDouble();
      return AnimatedBuilder(
        animation: _wave,
        builder: (_, __) {
final t = (_wave.value + delay) % 1.0;
return Positioned(
  left: left,
  top: baseTop - t * 80,
  child: Opacity(
    opacity: (1 - t) * 0.55,
    child: Container(
      width: sz,
      height: sz,
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

  Widget _logo() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (_, __) {
        final t =
  Curves.easeOutBack.transform(_intro.value.clamp(0.0, 1.0));
        return Transform.scale(
scale: 0.3 + t * 0.7,
child: AnimatedBuilder(
  animation: _pulse,
  builder: (_, __) {
    final glow = 0.3 + _pulse.value * 0.4;
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(46),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(glow),
            blurRadius: 44,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: JC.primaryDark.withOpacity(0.5),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Icon(
        Icons.wifi_rounded,
        size: 78,
        color: JC.primary,
      ),
    );
  },
),
        );
      },
    );
  }

  Widget _name() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (_, __) {
        final t = (_intro.value * 1.5).clamp(0.0, 1.0);
        return Opacity(
opacity: t,
child: Transform.translate(
  offset: Offset(0, (1 - t) * 30),
  child: Text(
    'JAJ Net',
    style: GoogleFonts.poppins(
      fontSize: 44,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      letterSpacing: 1.8,
    ),
  ),
),
        );
      },
    );
  }

  Widget _tagline() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (_, __) {
        final t = ((_intro.value - 0.2) * 1.5).clamp(0.0, 1.0);
        return Opacity(
opacity: t,
child: Transform.translate(
  offset: Offset(0, (1 - t) * 20),
  child: Text(
    'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
    style: GoogleFonts.hindSiliguri(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      color: Colors.white.withOpacity(0.92),
      letterSpacing: 0.5,
    ),
  ),
),
        );
      },
    );
  }

  Widget _loader() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (_, __) {
        final t = ((_intro.value - 0.4) * 1.5).clamp(0.0, 1.0);
        return Opacity(
opacity: t,
child: Container(
  width: 64,
  height: 4,
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.25),
    borderRadius: BorderRadius.circular(3),
  ),
  child: AnimatedBuilder(
    animation: _wave,
    builder: (_, __) => Align(
      alignment: Alignment(-1 + 2 * _wave.value, 0),
      child: Container(
        width: 24,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    ),
  ),
),
        );
      },
    );
  }
}
