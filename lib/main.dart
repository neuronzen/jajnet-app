import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding.dart';
import 'screens.dart';
import 'services.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const JajNetApp());
}

class JajNetApp extends StatelessWidget {
  const JajNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JAJ Net',
      debugShowCheckedModeBanner: false,
      theme: buildJajTheme(),
      home: const RootRouter(),
    );
  }
}

class RootRouter extends StatefulWidget {
  const RootRouter({super.key});
  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    final loggedIn = AuthService.currentUser != null;

    if (!mounted) return;

    Widget next;
    if (loggedIn) {
      next = const MainShell();
    } else if (seen) {
      next = const LoginScreen();
    } else {
      next = const OnboardingScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _SplashScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JC.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              tween: Tween(begin: 0.6, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (_, scale, __) => Transform.scale(
                scale: scale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: JC.primaryGradient,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: JC.primary.withOpacity(0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const _FadeInText(
              text: 'JAJ Net',
              delay: 400,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: JC.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            _FadeInText(
              text: 'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
              delay: 700,
              style: TextStyle(
                fontSize: 14,
                color: JC.grey,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 56),
            const _FadeInLoader(),
          ],
        ),
      ),
    );
  }
}

class _FadeInText extends StatefulWidget {
  final String text;
  final int delay;
  final TextStyle style;
  const _FadeInText({
    required this.text,
    required this.delay,
    required this.style,
  });
  @override
  State<_FadeInText> createState() => _FadeInTextState();
}

class _FadeInTextState extends State<_FadeInText> {
  double _opacity = 0;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 600),
      child: Text(widget.text, style: widget.style),
    );
  }
}

class _FadeInLoader extends StatefulWidget {
  const _FadeInLoader();
  @override
  State<_FadeInLoader> createState() => _FadeInLoaderState();
}

class _FadeInLoaderState extends State<_FadeInLoader> {
  double _opacity = 0;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 600),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: JC.primary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
