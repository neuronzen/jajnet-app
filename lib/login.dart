import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late final AnimationController _aurora;
  late final AnimationController _pulse;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _aurora = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _aurora.dispose();
    _pulse.dispose();
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
            offset: Offset(0, (1 - eased) * 20),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerH = size.height * 0.40;

    return Scaffold(
      backgroundColor: JC.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            height: headerH + 40,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                decoration: const BoxDecoration(gradient: JC.heroGradient),
                child: Stack(
                  children: [
                    Positioned.fill(child: _auroraLayer()),
                    Positioned.fill(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: headerH * 0.18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _fade(_logoWithPulse(), 0.05),
                              const SizedBox(height: 20),
                              _fade(_brandName(), 0.20),
                              const SizedBox(height: 8),
                              _fade(
                                Text(
                                  'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 12.5,
                                    color: Colors.white.withOpacity(0.94),
                                    height: 1.5,
                                  ),
                                ),
                                0.30,
                              ),
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
                color: JC.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 32, 26, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fade(
                      Text(
                        'স্বাগতম 👋',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: JC.ink,
                          height: 1.4,
                        ),
                      ),
                      0.40,
                    ),
                    const SizedBox(height: 4),
                    _fade(
                      Text(
                        'আপনার JAJ Net অ্যাকাউন্টে লগইন করুন',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13.5,
                          color: JC.grey,
                          height: 1.5,
                        ),
                      ),
                      0.45,
                    ),
                    const SizedBox(height: 26),
                    _fade(
                      _field(
                        controller: _email,
                        label: 'ইমেইল',
                        icon: Icons.alternate_email_rounded,
                        keyboard: TextInputType.emailAddress,
                      ),
                      0.55,
                    ),
                    const SizedBox(height: 14),
                    _fade(
                      _field(
                        controller: _pass,
                        label: 'পাসওয়ার্ড',
                        icon: Icons.lock_outline_rounded,
                        obscure: _hide,
                        suffix: IconButton(
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: JC.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _hide = !_hide),
                        ),
                      ),
                      0.62,
                    ),
                    const SizedBox(height: 28),
                    _fade(_loginButton(), 0.70),
                    const SizedBox(height: 22),
                    _fade(_credentialsInfo(), 0.80),
                    const SizedBox(height: 18),
                    _fade(
                      Center(
                        child: Text(
                          'সংস্করণ ১.০.০',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 10.5,
                            color: JC.greyLight,
                            height: 1.5,
                          ),
                        ),
                      ),
                      0.90,
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

  Widget _auroraLayer() {
    return AnimatedBuilder(
      animation: _aurora,
      builder: (_, __) {
        final t = _aurora.value;
        final r = t * math.pi * 2;
        return Stack(
          children: [
            Positioned(
              left: -90 + 60 * math.sin(r),
              top: 20 + 40 * math.cos(r),
              child: _blob(240, Colors.white.withOpacity(0.22)),
            ),
            Positioned(
              right: -80 + 70 * math.cos(r + 1.5),
              top: 80 + 30 * math.sin(r + 1.5),
              child: _blob(200, const Color(0xFFFFD54F).withOpacity(0.20)),
            ),
            Positioned(
              left: 130 + 80 * math.sin(r + 3.0),
              top: -70 + 60 * math.cos(r + 3.0),
              child: _blob(220, const Color(0xFFFFE0B2).withOpacity(0.18)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color) {
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

  Widget _logoWithPulse() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final p = _pulse.value;
        return SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.80 + p * 0.20,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.40 * (1 - p)),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.20),
                ),
              ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
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

  Widget _brandName() {
    return Column(
      children: [
        Text(
          'JAJ Net',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            return Container(
              width: 36 + _pulse.value * 34,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      style: GoogleFonts.hindSiliguri(fontSize: 15, color: JC.ink),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: JC.primary, size: 20),
        suffixIcon: suffix,
        labelStyle: GoogleFonts.hindSiliguri(fontSize: 14, color: JC.grey),
        floatingLabelStyle: GoogleFonts.hindSiliguri(
          color: JC.primary,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: JC.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: JC.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _loginButton() {
    return GestureDetector(
      onTap: _loading ? null : _login,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: JC.heroGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: JC.primary.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
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
                        fontSize: 16,
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

  Widget _credentialsInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JC.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JC.creamDeep, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: JC.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.key_rounded,
                  color: JC.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'লগইন করার তথ্য পাননি?',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: JC.ink,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'আপনি যদি JAJ Net-এর গ্রাহক হন এবং এখনো লগইন তথ্য না পেয়ে থাকেন, অথবা নতুন সংযোগ নিতে চান — আমাদের সাপোর্ট টিমের সাথে যোগাযোগ করুন।',
            style: GoogleFonts.hindSiliguri(
              fontSize: 12.5,
              color: JC.grey,
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: JC.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: JC.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.call_rounded,
                    color: JC.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppInfo.helpline,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: JC.primary,
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

class SignupScreenNew extends StatefulWidget {
  const SignupScreenNew({super.key});
  @override
  State<SignupScreenNew> createState() => _SignupScreenNewState();
}

class _SignupScreenNewState extends State<SignupScreenNew> {
  @override
  void initState() {
    super.initState();
    _loadPkgs();
  }

  Future<void> _loadPkgs() async {
    final pkgs = await AuthService.fetchPackages();
    if (!mounted) return;
    setState(() {
      _packages = pkgs;
      if (_packages.isNotEmpty) {
        _pkg = (_packages.first['name'] ?? '').toString();
      }
      _loadingPkgs = false;
    });
  }

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _area = AppInfo.areas.first;
  String _pkg = '';
  List<Map<String, dynamic>> _packages = [];
  bool _loadingPkgs = true;
  bool _loading = false;
  bool _hide = true;

  Future<void> _signup() async {
    if (_name.text.isEmpty ||
        _email.text.isEmpty ||
        _pass.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final selectedPkg = _packages.firstWhere(
        (p) => (p['name'] ?? '').toString() == _pkg,
        orElse: () => _packages.isNotEmpty ? _packages.first : {},
      );
      await AuthService.signUp(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
        address: _area,
        packageName: (selectedPkg['name'] ?? '20 Mbps').toString(),
        packagePrice: (selectedPkg['price'] ?? 525) as int,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
content: Text('রেজিস্ট্রেশন ব্যর্থ: ${e.toString()}'),
behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JC.white,
      appBar: AppBar(
        title: Text(
'নতুন অ্যাকাউন্ট',
style: GoogleFonts.hindSiliguri(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: JC.ink,
),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
  horizontal: 24, vertical: 12),
        child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: JC.sunGradient,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.rocket_launch_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'কয়েক ধাপেই অ্যাকাউন্ট খুলুন',
            style: GoogleFonts.hindSiliguri(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 22),
  _sec('ব্যক্তিগত তথ্য'),
  const SizedBox(height: 12),
  _f(_name, 'পুরো নাম', Icons.person_outline_rounded),
  const SizedBox(height: 12),
  _f(_phone, 'মোবাইল নম্বর', Icons.phone_outlined,
      kb: TextInputType.phone),
  const SizedBox(height: 12),
  _f(_email, 'ইমেইল', Icons.alternate_email_rounded,
      kb: TextInputType.emailAddress),
  const SizedBox(height: 12),
  _passField(),
  const SizedBox(height: 26),
  _sec('সংযোগ তথ্য'),
  const SizedBox(height: 12),
  _dropdown(
    value: _area,
    label: 'এলাকা',
    icon: Icons.location_on_outlined,
    items: AppInfo.areas
        .map((a) => DropdownMenuItem<String>(
              value: a,
              child: Text(a,
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 14)),
            ))
        .toList(),
    onChanged: (v) => setState(() => _area = v!),
  ),
  const SizedBox(height: 12),
  _dropdown(
    value: _pkg,
    label: 'প্যাকেজ',
    icon: Icons.wifi_outlined,
    items: _packages.map((p) => DropdownMenuItem<String>(value: (p['name'] ?? '').toString(), child: Text('${p['name']} — ৳${p['price']}', style: GoogleFonts.hindSiliguri(fontSize: 14)))).toList(),
    onChanged: (v) => setState(() => _pkg = v!),
  ),
  const SizedBox(height: 32),
  GestureDetector(
    onTap: _loading ? null : _signup,
    child: Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: JC.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: JC.primary.withOpacity(0.4),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'রেজিস্ট্রেশন সম্পন্ন করুন',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    ),
  ),
  const SizedBox(height: 24),
],
        ),
      ),
    );
  }

  Widget _sec(String s) {
    return Text(
      s,
      style: GoogleFonts.hindSiliguri(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: JC.ink,
      ),
    );
  }

  Widget _passField() {
    return TextField(
      controller: _pass,
      obscureText: _hide,
      style: GoogleFonts.hindSiliguri(fontSize: 15, color: JC.ink),
      decoration: InputDecoration(
        labelText: 'পাসওয়ার্ড',
        prefixIcon: const Icon(Icons.lock_outline_rounded,
  color: JC.primary, size: 20),
        suffixIcon: IconButton(
icon: Icon(
  _hide
      ? Icons.visibility_outlined
      : Icons.visibility_off_outlined,
  color: JC.grey,
  size: 20,
),
onPressed: () => setState(() => _hide = !_hide),
        ),
        labelStyle: GoogleFonts.hindSiliguri(
  fontSize: 14, color: JC.grey),
        floatingLabelStyle: GoogleFonts.hindSiliguri(
color: JC.primary,
fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: JC.cream,
        border: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide:
    const BorderSide(color: JC.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _f(TextEditingController c, String label, IconData icon,
      {TextInputType? kb}) {
    return TextField(
      controller: c,
      keyboardType: kb,
      style: GoogleFonts.hindSiliguri(fontSize: 15, color: JC.ink),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: JC.primary, size: 20),
        labelStyle: GoogleFonts.hindSiliguri(
  fontSize: 14, color: JC.grey),
        floatingLabelStyle: GoogleFonts.hindSiliguri(
color: JC.primary,
fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: JC.cream,
        border: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide:
    const BorderSide(color: JC.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      style: GoogleFonts.hindSiliguri(fontSize: 14, color: JC.ink),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: JC.primary, size: 20),
        labelStyle: GoogleFonts.hindSiliguri(
  fontSize: 14, color: JC.grey),
        floatingLabelStyle: GoogleFonts.hindSiliguri(
color: JC.primary,
fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: JC.cream,
        border: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide:
    const BorderSide(color: JC.primary, width: 1.5),
        ),
      ),
    );
  }
}
