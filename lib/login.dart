import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'screens.dart';
import 'services.dart';
import 'theme.dart';

// ============================================================
// LOGIN SCREEN — Premium ISP Atmosphere
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

  // Single subtle animation — atmosphere "breathing"
  late final AnimationController _atmosphere;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _atmosphere = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _atmosphere.dispose();
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
            offset: Offset(0, (1 - eased) * 16),
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
          // ============ HERO ============
          Positioned(
            top: 0, left: 0, right: 0,
            height: headerH + 40,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: Stack(
                children: [
                  // 1. Base gradient (deep → mid orange, no yellow)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFB84200),
                            Color(0xFFD95200),
                            Color(0xFFE96615),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // 2. Radial highlight (top-right, subtle)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFB880).withOpacity(0.16),
                            Colors.transparent,
                          ],
                          center: const Alignment(0.90, -0.90),
                          radius: 1.1,
                        ),
                      ),
                    ),
                  ),
                  // 3. Soft bottom vignette for depth
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF6B2400).withOpacity(0.12),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // 4. Signal atmosphere (subtle network theme)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _atmosphere,
                      builder: (_, __) => CustomPaint(
                        painter: _AtmospherePainter(
                          breath: _atmosphere.value,
                        ),
                      ),
                    ),
                  ),
                  // 5. Content
                  Positioned.fill(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: headerH * 0.16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _fade(_logoBlock(), 0.05),
                            const SizedBox(height: 24),
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

          // ============ BODY (unchanged) ============
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ LOGO — clean, integrated ============
  Widget _logoBlock() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          // Warm ambient shadow below
          BoxShadow(
            color: const Color(0xFF6B2400).withOpacity(0.28),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
          // Tight contact shadow
          BoxShadow(
            color: const Color(0xFF6B2400).withOpacity(0.14),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // White rounded square with very subtle warm tint at bottom
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFFFFCF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.wifi_rounded,
                size: 40,
                color: JC.primary,
              ),
            ),
          ),
          // Top-edge inner highlight (glass-like catch of light)
          Positioned(
            top: 0, left: 22, right: 22,
            child: Container(
              height: 1.4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ BRAND BLOCK — refined hierarchy ============
  Widget _brandBlock() {
    return Column(
      children: [
        Text(
          'JAJ Net',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2.0,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        // Thin refined divider
        Container(
          width: 30,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
          textAlign: TextAlign.center,
          style: GoogleFonts.hindSiliguri(
            fontSize: 12.5,
            color: Colors.white.withOpacity(0.88),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============ FIELDS (unchanged) ============
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
// HEADER CLIPPER (wave curve — retained)
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
// ATMOSPHERE PAINTER — subtle connectivity theme
// ============================================================
class _AtmospherePainter extends CustomPainter {
  final double breath; // 0.0 → 1.0

  _AtmospherePainter({required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    // Signal source — behind logo
    final center = Offset(size.width * 0.5, size.height * 0.42);

    // ---- Two extremely faint concentric rings ----
    // Inner ring
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.055 + breath * 0.020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, 105, innerPaint);

    // Outer ring — even fainter
    final outerPaint = Paint()
      ..color = Colors.white.withOpacity(0.032 + breath * 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(center, 165, outerPaint);

    // ---- One soft diagonal light streak (top-left direction) ----
    final trail = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.055 + breath * 0.015),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(size.width * 0.12, 0),
      Offset(size.width * 0.30, size.height * 0.85),
      trail,
    );
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return oldDelegate.breath != breath;
  }
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
