import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens.dart';
import 'services.dart';
import 'theme.dart';

class LoginScreenNew extends StatefulWidget {
  const LoginScreenNew({super.key});
  @override
  State<LoginScreenNew> createState() => _LoginScreenNewState();
}

class _LoginScreenNewState extends State<LoginScreenNew>
    with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  bool _showCreds = false;
  bool _emailFocus = false;
  bool _passFocus = false;

  late final AnimationController _entrance;
  late final AnimationController _aurora;
  late final AnimationController _wave;
  late final AnimationController _bob;

  StreamSubscription? _accelSub;

  // Filtered gravity vector (heavy low-pass)
  double _gx = 0;
  double _gy = 9.8;

  // Water surface angle (radians) — spring-damper output
  double _surfaceAngle = 0;
  double _surfaceVel = 0;

  // Wave energy (0 calm, 1+ sloshing)
  double _waveEnergy = 0;
  double _wavePhase = 0;

  // Physics ticker
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _aurora = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _ticker = createTicker(_onPhysicsTick)..start();
    _startSensors();
  }

  void _onPhysicsTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    double dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.15) {
      _repaint.value++;
      return;
    }

    // Target surface angle from gravity vector.
    // Real water surface is perpendicular to gravity.
    final safeGy = _gy.abs() < 0.5 ? (_gy >= 0 ? 0.5 : -0.5) : _gy;
    final targetAngle = math.atan2(-_gx, safeGy);

    // Spring-damper — inertia, overshoot, oscillation
    const kSpring = 30.0;
    const cDamp = 2.2;
    final aAccel =
        (targetAngle - _surfaceAngle) * kSpring - _surfaceVel * cDamp;
    _surfaceVel += aAccel * dt;
    _surfaceAngle += _surfaceVel * dt;

    // Wave energy decays (ripples die out like real water)
    _waveEnergy *= math.pow(0.92, dt * 60).toDouble();
    if (_waveEnergy < 0.004) _waveEnergy = 0;

    _wavePhase += dt * 5.0;
    _repaint.value++;
  }

  void _startSensors() {
    try {
      _accelSub = accelerometerEventStream().listen(
        (event) {
          // Heavy low-pass — keep slow tilt, discard shake noise
          _gx = _gx * 0.90 + event.x * 0.10;
          _gy = _gy * 0.90 + event.y * 0.10;

          // Shake detection from raw magnitude deviation
          final mag = math.sqrt(event.x * event.x +
              event.y * event.y + event.z * event.z);
          final deviation = (mag - 9.8).abs();
          if (deviation > 0.5) {
            _waveEnergy =
                math.min(_waveEnergy + deviation * 0.018, 2.5);
          }
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker.dispose();
    _accelSub?.cancel();
    _entrance.dispose();
    _aurora.dispose();
    _wave.dispose();
    _bob.dispose();
    _repaint.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      _snack('ইমেইল ও পাসওয়ার্ড দিন', isError: false);
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.signIn(_email.text.trim(), _pass.text);
      if (!mounted) return;
      final data = await AuthService.getUserData();
      final status = (data?['status'] ?? 'active').toString().toLowerCase();
      if (status == 'suspended' || status == 'deleted') {
        await AuthService.signOut();
        if (!mounted) return;
        _snack(
          'আপনার সংযোগ বন্ধ রয়েছে। সাপোর্টে যোগাযোগ করুন: ${AppInfo.helpline}',
          isError: true,
          durationSec: 6,
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      String msg = 'লগইন করা যায়নি';
      final s = e.toString();
      if (s.contains('user-not-found')) {
        msg = 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই';
      } else if (s.contains('wrong-password') ||
          s.contains('invalid-credential')) {
        msg = 'ইমেইল বা পাসওয়ার্ড ভুল';
      } else if (s.contains('invalid-email')) {
        msg = 'ইমেইল সঠিক নয়';
      } else if (s.contains('network')) {
        msg = 'ইন্টারনেট সংযোগ নেই';
      } else if (s.contains('too-many-requests')) {
        msg = 'অনেকবার চেষ্টা করা হয়েছে, পরে চেষ্টা করুন';
      }
      _snack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = true, int durationSec = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.hindSiliguri(height: 1.5)),
        backgroundColor: isError ? JC.error : JC.warning,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: durationSec),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _fade(Widget child, double delay) {
    final start = delay / 1.5;
    return AnimatedBuilder(
      animation: _entrance,
      builder: (_, __) {
        final t = ((_entrance.value - start) / (1 - start)).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 14),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerH = size.height * 0.38;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            height: headerH + 40,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFC94400),
                      Color(0xFFE55A00),
                      Color(0xFFFF6B00),
                      Color(0xFFFF8A3D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Aurora blobs
                    Positioned.fill(child: _auroraLayer()),
                    // Diagonal gold lines
                    Positioned.fill(child: _diagonalGoldLines()),
                    // Water waves layer
                    Positioned.fill(child: _waterLayer()),
                    // Top right corner accent
                    Positioned(
                      top: -80, right: -60,
                      child: Container(
                        width: 220, height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.13),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    // Center content
                    Positioned.fill(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: headerH * 0.14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _fade(_floatingLogo(), 0.0),
                              const SizedBox(height: 20),
                              _fade(_brandBlock(), 0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: headerH,
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFC),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(34),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.06),
                    blurRadius: 26,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fade(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'স্বাগতম 👋',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'আপনার JAJ Net অ্যাকাউন্টে লগইন করুন',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 13.5,
                              color: const Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      0.30,
                    ),
                    const SizedBox(height: 26),
                    _fade(
                      _field(
                        controller: _email,
                        label: 'ইমেইল',
                        icon: Icons.alternate_email_rounded,
                        keyboard: TextInputType.emailAddress,
                        focused: _emailFocus,
                        onFocusChange: (v) => setState(() => _emailFocus = v),
                      ),
                      0.40,
                    ),
                    const SizedBox(height: 14),
                    _fade(
                      _field(
                        controller: _pass,
                        label: 'পাসওয়ার্ড',
                        icon: Icons.lock_outline_rounded,
                        obscure: _hide,
                        focused: _passFocus,
                        onFocusChange: (v) => setState(() => _passFocus = v),
                        suffix: IconButton(
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      0.48,
                    ),
                    const SizedBox(height: 24),
                    _fade(_loginButton(), 0.56),
                    const SizedBox(height: 20),
                    _fade(_credentialsCard(), 0.66),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ LIQUID LAYER (real water physics) ============
  Widget _waterLayer() {
    return AnimatedBuilder(
      animation: _repaint,
      builder: (_, __) {
        return CustomPaint(
          painter: _LiquidPainter(
            surfaceAngle: _surfaceAngle,
            waveEnergy: _waveEnergy,
            wavePhase: _wavePhase,
          ),
        );
      },
    );
  }

  // ============ FLOATING LOGO with tilt + glow ============
  double _amplifyTilt(double v) {
    final a = v.abs();
    if (a < 0.03) return 0;
    return v.sign * math.pow(a, 0.55).toDouble();
  }

  Widget _floatingLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _repaint]),
      builder: (_, __) {
        final t = _bob.value * math.pi * 2;
        final bobAmp = 5.0 + _waveEnergy.clamp(0.0, 1.0) * 8.0;
        final bob = math.sin(t) * bobAmp;
        final tiltDx = _gx * 4.0;
        final tiltDy = -(_gy - 9.8) * 2.0;
        final rot = _surfaceAngle * 0.85;

        return Transform.translate(
          offset: Offset(tiltDx, bob + tiltDy),
          child: Transform.rotate(
            angle: rot,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 175, height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.white.withOpacity(0.42),
                      Colors.white.withOpacity(0.0),
                    ]),
                  ),
                ),
                Container(
                  width: 108, height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                      width: 1.2),
                  ),
                  child: Center(
                    child: Container(
                      width: 84, height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.28),
                          blurRadius: 22,
                          offset: const Offset(0, 10))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            'assets/logo/jajnet-logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.wifi_rounded,
                              size: 40, color: JC.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== AURORA LAYER =====
  Widget _auroraLayer() {
    return AnimatedBuilder(
      animation: _aurora,
      builder: (_, __) {
        final t = _aurora.value;
        final r = t * math.pi * 2;
        return Stack(
          children: [
            Positioned(
              left: -70 + 50 * math.sin(r),
              top: -40 + 40 * math.cos(r),
              child: _blob(260, const Color(0xFFFFB547).withOpacity(0.22)),
            ),
            Positioned(
              right: -80 + 60 * math.cos(r + 1.6),
              bottom: -60 + 30 * math.sin(r + 1.6),
              child: _blob(240, Colors.white.withOpacity(0.10)),
            ),
            Positioned(
              right: 30 + 40 * math.sin(r + 3.2),
              top: 10 + 30 * math.cos(r + 3.2),
              child: _blob(200, const Color(0xFFFFD54F).withOpacity(0.14)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }

  // ===== GOLD DIAGONAL LINES =====
  Widget _diagonalGoldLines() {
    return AnimatedBuilder(
      animation: _aurora,
      builder: (_, __) {
        final t = _aurora.value;
        return Stack(
          children: List.generate(3, (i) {
            final xOffset = (t - 0.5) * 20 + (i * 14);
            return Positioned(
              bottom: 100 - i * 18,
              left: -80 + xOffset,
              child: Transform.rotate(
                angle: -0.35,
                child: Container(
                  width: 240,
                  height: 1.1,
                  color: const Color(0xFFFFB547).withOpacity(0.20),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _brandBlock() {
    return Column(
      children: [
        Text(
          'JAJ Net',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.6,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB547),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
          textAlign: TextAlign.center,
          style: GoogleFonts.hindSiliguri(
            fontSize: 12.5,
            color: Colors.white.withOpacity(0.95),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ===== FIELD =====
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
    bool focused = false,
    ValueChanged<bool>? onFocusChange,
    Widget? suffix,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: JC.primary.withOpacity(0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.035),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: focused
                      ? JC.primary.withOpacity(0.14)
                      : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  color: focused ? JC.primary : const Color(0xFF64748B),
                  size: 18,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0, minHeight: 0,
            ),
            suffixIcon: suffix,
            labelStyle: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            floatingLabelStyle: GoogleFonts.hindSiliguri(
              color: JC.primary,
              fontWeight: FontWeight.w500,
              backgroundColor: const Color(0xFFFBFBFC),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E5EB),
                width: 1.4,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E5EB),
                width: 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: JC.primary,
                width: 1.8,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18, horizontal: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ===== LOGIN BUTTON =====
  Widget _loginButton() {
    return GestureDetector(
      onTap: _loading ? null : _login,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: JC.heroGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: JC.primary.withOpacity(0.32),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'লগইন করুন',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ===== CREDENTIALS CARD =====
  Widget _credentialsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E5EB), width: 1.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showCreds = !_showCreds),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: JC.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: JC.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'সাপোর্ট দরকার?',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                        height: 1.5,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showCreds ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            alignment: Alignment.topCenter,
            curve: Curves.easeOut,
            child: _showCreds ? _credsBody() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _credsBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 1, color: const Color(0xFFE2E5EB)),
          const SizedBox(height: 14),
          Text(
            'আপনি JAJ Net-এর গ্রাহক হলে সাপোর্ট থেকে লগইন তথ্য নিতে পারেন। নতুন সংযোগের জন্যও যোগাযোগ করুন।',
            style: GoogleFonts.hindSiliguri(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
              height: 1.7,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('tel:${AppInfo.helpline}');
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                gradient: JC.heroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.call_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppInfo.helpline,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== WAVE CLIPPER =====
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 10,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ===== LIQUID PAINTER — real water =====
class _LiquidPainter extends CustomPainter {
  final double surfaceAngle;
  final double waveEnergy;
  final double wavePhase;

  _LiquidPainter({
    required this.surfaceAngle,
    required this.waveEnergy,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseY = size.height * 0.80;
    final slope = math.tan(surfaceAngle.clamp(-1.2, 1.2));
    final centerX = size.width / 2;
    final amp = waveEnergy.clamp(0.0, 1.5);

    double surfaceY(double x) {
      final dx = x - centerX;
      final line = baseY + dx * slope;
      final w1 = math.sin(x * 0.007 + wavePhase * 1.1) * 11.0 * amp;
      final w2 = math.sin(x * 0.018 - wavePhase * 1.7) * 5.5 * amp;
      final w3 = math.sin(x * 0.040 + wavePhase * 0.9) * 2.6 * amp;
      final w4 = math.sin(x * 0.085 - wavePhase * 2.3) * 1.2 * amp;
      final edgeDist = math.min(x, size.width - x);
      final meniscus = edgeDist < 45
          ? -math.pow((45 - edgeDist) / 45, 2).toDouble() * 12
          : 0.0;
      return line + w1 + w2 + w3 + w4 + meniscus;
    }

    // WATER BODY
    final waterPath = Path();
    waterPath.moveTo(0, surfaceY(0));
    for (double x = 0; x <= size.width; x += 3) {
      waterPath.lineTo(x, surfaceY(x));
    }
    waterPath.lineTo(size.width, size.height);
    waterPath.lineTo(0, size.height);
    waterPath.close();

    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFA8D4E6).withOpacity(0.60),
        const Color(0xFF6BA3BE).withOpacity(0.55),
        const Color(0xFF3D6F87).withOpacity(0.72),
      ],
      stops: const [0.0, 0.40, 1.0],
    ).createShader(Rect.fromLTWH(0, baseY - 60, size.width, size.height));
    canvas.drawPath(waterPath, Paint()..shader = shader);

    // DEEP GLOW
    final deep = Path();
    deep.moveTo(0, surfaceY(0) + 10);
    for (double x = 0; x <= size.width; x += 3) {
      deep.lineTo(x, surfaceY(x) + 10);
    }
    deep.lineTo(size.width, size.height);
    deep.lineTo(0, size.height);
    deep.close();
    canvas.drawPath(deep, Paint()
      ..color = const Color(0xFF7ED3F0).withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    // CAUSTICS
    final causticIntensity = 0.10 + amp * 0.14;
    for (int i = 0; i < 7; i++) {
      final bx = (i / 6) * size.width +
          math.sin(wavePhase * 0.5 + i * 1.7) * 60;
      final by = baseY + 30 + i * 20 +
          math.cos(wavePhase * 0.35 + i) * 14;
      final r = 30.0 + (i % 4) * 22;
      canvas.drawCircle(Offset(bx, by), r, Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withOpacity(causticIntensity),
          Colors.white.withOpacity(0.0),
        ]).createShader(Rect.fromCircle(center: Offset(bx, by), radius: r)));
    }

    // BUBBLES
    for (int i = 0; i < 6; i++) {
      final bx = ((i * 97 + 37) % size.width.toInt()).toDouble();
      final cycle = (wavePhase * 0.15 + i * 0.17) % 1.0;
      final by = baseY + 40 + (1 - cycle) * (size.height - baseY - 40);
      final br = 1.5 + (i % 3) * 0.8;
      final bo = 0.14 + (1 - cycle) * 0.22;
      canvas.drawCircle(Offset(bx, by), br, Paint()
        ..color = Colors.white.withOpacity(bo)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8);
    }

    // SURFACE
    final sPath = Path();
    for (double x = 0; x <= size.width; x += 3) {
      final y = surfaceY(x);
      if (x == 0) { sPath.moveTo(x, y); } else { sPath.lineTo(x, y); }
    }
    canvas.drawPath(sPath, Paint()
      ..color = const Color(0xFFB8E4F5).withOpacity(0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawPath(sPath, Paint()
      ..color = Colors.white.withOpacity(0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(sPath, Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1);

    // SPECULAR
    for (int i = 0; i < 3; i++) {
      final sx = size.width * (0.22 + i * 0.28) +
          math.sin(wavePhase * 1.3 + i * 2) * 45;
      final sy = surfaceY(sx) - 2;
      canvas.drawCircle(Offset(sx, sy), 6.0, Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withOpacity(0.80),
          Colors.white.withOpacity(0.0),
        ]).createShader(Rect.fromCircle(center: Offset(sx, sy), radius: 6)));
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) =>
      old.surfaceAngle != surfaceAngle ||
      old.waveEnergy != waveEnergy ||
      old.wavePhase != wavePhase;
}

// ===== SIGNUP (unchanged) =====
class SignupScreenNew extends StatefulWidget {
  const SignupScreenNew({super.key});
  @override
  State<SignupScreenNew> createState() => _SignupScreenNewState();
}

class _SignupScreenNewState extends State<SignupScreenNew> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _area = AppInfo.areas.first;
  String _pkg = AppInfo.packages.first['speed'];
  bool _loading = false;
  bool _hide = true;

  Future<void> _signup() async {
    if (_name.text.isEmpty || _email.text.isEmpty || _pass.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthService.signUp(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
        address: _area,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('রেজিস্ট্রেশন ব্যর্থ: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নতুন রেজিস্ট্রেশন')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'পুরো নাম'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'মোবাইল নম্বর'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'ইমেইল'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _pass,
              obscureText: _hide,
              decoration: InputDecoration(
                labelText: 'পাসওয়ার্ড',
                suffixIcon: IconButton(
                  icon: Icon(_hide
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('রেজিস্ট্রেশন'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
