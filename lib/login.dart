import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens.dart';
import 'services.dart';
import 'theme.dart';

// ============================================================
// NEW LOGIN SCREEN — "Mesh Aurora Premium"
// ============================================================
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

  late final AnimationController _mesh;
  late final AnimationController _ring;
  late final AnimationController _logoPulse;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _mesh = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
    _logoPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _mesh.dispose();
    _ring.dispose();
    _logoPulse.dispose();
    _entrance.dispose();
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
    final start = delay / 1.4;
    return AnimatedBuilder(
      animation: _entrance,
      builder: (_, __) {
        final t = ((_entrance.value - start) / (1 - start)).clamp(0.0, 1.0);
        final eased = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 18),
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
          // ==================== HEADER ====================
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
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Animated mesh gradient blobs
                    Positioned.fill(child: _meshLayer()),
                    // Rotating concentric ring
                    Positioned.fill(child: _rotatingRing()),
                    // Diagonal gold lines
                    Positioned.fill(child: _diagonalLines()),
                    // Center content
                    Positioned.fill(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: headerH * 0.16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _fade(_logoWithPulse(), 0.05),
                              const SizedBox(height: 22),
                              _fade(_brandBlock(), 0.20),
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

          // ==================== BODY ====================
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
                      _liftField(
                        controller: _email,
                        label: 'ইমেইল',
                        icon: Icons.alternate_email_rounded,
                        keyboard: TextInputType.emailAddress,
                      ),
                      0.40,
                    ),
                    const SizedBox(height: 14),
                    _fade(
                      _liftField(
                        controller: _pass,
                        label: 'পাসওয়ার্ড',
                        icon: Icons.lock_outline_rounded,
                        obscure: _hide,
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
                    const SizedBox(height: 26),
                    _fade(
                      Center(
                        child: Text(
                          'সংস্করণ ১.০.০',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 10.5,
                            color: const Color(0xFFB0B7C3),
                            height: 1.5,
                          ),
                        ),
                      ),
                      0.76,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ MESH GRADIENT ============
  Widget _meshLayer() {
    return AnimatedBuilder(
      animation: _mesh,
      builder: (_, __) {
        final t = _mesh.value;
        final r = t * math.pi * 2;
        return Stack(
          children: [
            // Gold blob
            Positioned(
              left: -60 + 40 * math.sin(r),
              top: -40 + 30 * math.cos(r),
              child: _radialBlob(
                260,
                const Color(0xFFFFB547).withOpacity(0.28),
              ),
            ),
            // Deep navy hint
            Positioned(
              right: -80 + 50 * math.cos(r + 2),
              bottom: -60 + 40 * math.sin(r + 2),
              child: _radialBlob(
                240,
                const Color(0xFF0F172A).withOpacity(0.28),
              ),
            ),
            // Light orange
            Positioned(
              right: 40 + 40 * math.sin(r + 1),
              top: 20 + 30 * math.cos(r + 1),
              child: _radialBlob(
                220,
                const Color(0xFFFF9F5A).withOpacity(0.32),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _radialBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }

  // ============ ROTATING RING ============
  Widget _rotatingRing() {
    return AnimatedBuilder(
      animation: _ring,
      builder: (_, __) {
        return Stack(
          children: [
            // Static outer ring
            Positioned(
              top: -90, right: -60,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            // Rotating inner ring (partial arc — dashed look)
            Positioned(
              top: -60, right: -35,
              child: Transform.rotate(
                angle: _ring.value * 2 * math.pi,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFB547).withOpacity(0.55),
                      width: 1.6,
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

  // ============ DIAGONAL LINES ============
  Widget _diagonalLines() {
    return AnimatedBuilder(
      animation: _mesh,
      builder: (_, __) {
        final t = _mesh.value;
        return Stack(
          children: List.generate(3, (i) {
            final xOffset = (t - 0.5) * 30 + (i * 12);
            return Positioned(
              bottom: 90 - i * 14,
              left: -80 + xOffset,
              child: Transform.rotate(
                angle: -0.35,
                child: Container(
                  width: 260,
                  height: 1.2,
                  color: const Color(0xFFFFB547).withOpacity(0.22),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ============ LOGO WITH PULSE ============
  Widget _logoWithPulse() {
    return AnimatedBuilder(
      animation: _logoPulse,
      builder: (_, __) {
        final p = _logoPulse.value;
        return SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding ring
              Transform.scale(
                scale: 0.85 + p * 0.18,
                child: Container(
                  width: 132, height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.45 * (1 - p)),
                      width: 1.8,
                    ),
                  ),
                ),
              ),
              // Frosted glass outer
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.20),
                    width: 1,
                  ),
                ),
              ),
              // Solid logo box
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.28),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wifi_rounded,
                  size: 38,
                  color: JC.primary,
                ),
              ),
            ],
          ),
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
          width: 42,
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

  // ============ CARD LIFT FIELD ============
  Widget _liftField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
  }) {
    return StatefulBuilder(
      builder: (context, setLocal) {
        bool focused = false;
        return Focus(
          onFocusChange: (v) => setLocal(() => focused = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
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
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: focused
                          ? JC.primary.withOpacity(0.14)
                          : const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      icon,
                      color: focused
                          ? JC.primary
                          : const Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
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
                  vertical: 18,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
                    color: Colors.white,
                    strokeWidth: 2.5,
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
                horizontal: 16,
                vertical: 14,
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
                      Icons.vpn_key_rounded,
                      color: JC.primary,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'লগইন তথ্য পাননি?',
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

// ============================================================
// WAVE CLIPPER
// ============================================================
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

// ============================================================
// SIGNUP SCREEN (unchanged)
// ============================================================
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
      final pkg = AppInfo.packages.firstWhere((p) => p['speed'] == _pkg);
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
      final _ = pkg;
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
