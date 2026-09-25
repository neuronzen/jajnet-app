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
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;
  bool _showCreds = false;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
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
    final start = delay / 1.3;
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
    final headerH = size.height * 0.36;

    return Scaffold(
      backgroundColor: JC.white,
      body: Stack(
        children: [
          // ===== HEADER =====
          Positioned(
            top: 0, left: 0, right: 0,
            height: headerH + 40,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
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
                    // Concentric rings (top-right)
                    Positioned(
                      top: -75, right: -55,
                      child: Container(
                        width: 210, height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.13),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -50, right: -30,
                      child: Container(
                        width: 150, height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Diagonal accent (bottom-left)
                    Positioned(
                      bottom: 70, left: -60,
                      child: Transform.rotate(
                        angle: -0.38,
                        child: Container(
                          width: 230, height: 1.2,
                          color: Colors.white.withOpacity(0.15),
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
                              _fade(_logoCard(), 0.0),
                              const SizedBox(height: 18),
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

          // ===== BODY (white card overlapping header) =====
          Positioned(
            top: headerH,
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: JC.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
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
                              color: JC.ink,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'আপনার JAJ Net অ্যাকাউন্টে লগইন করুন',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 13.5,
                              color: JC.grey,
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
                      0.48,
                    ),
                    const SizedBox(height: 24),
                    _fade(_loginButton(), 0.56),
                    const SizedBox(height: 20),
                    _fade(_credentialsCard(), 0.66),
                    const SizedBox(height: 24),
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

  Widget _logoCard() {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.wifi_rounded,
          size: 36,
          color: JC.primary,
        ),
      ),
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
        const SizedBox(height: 6),
        Container(
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
          textAlign: TextAlign.center,
          style: GoogleFonts.hindSiliguri(
            fontSize: 12.5,
            color: Colors.white.withOpacity(0.92),
            height: 1.5,
          ),
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
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Icon(icon, color: JC.primary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
        suffixIcon: suffix,
        labelStyle: GoogleFonts.hindSiliguri(
          fontSize: 14,
          color: JC.grey,
        ),
        floatingLabelStyle: GoogleFonts.hindSiliguri(
          color: JC.primary,
          fontWeight: FontWeight.w500,
        ),
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: JC.greyLight, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: JC.greyLight, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: JC.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _loginButton() {
    return GestureDetector(
      onTap: _loading ? null : _login,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: JC.heroGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: JC.primary.withOpacity(0.28),
              blurRadius: 20,
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
        border: Border.all(color: JC.greyLight, width: 1.4),
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
                  const Icon(
                    Icons.vpn_key_rounded,
                    color: JC.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'লগইন তথ্য পাননি?',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: JC.ink,
                        height: 1.5,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showCreds ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: JC.grey,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 1, color: JC.greyLight),
          const SizedBox(height: 14),
          Text(
            'আপনি JAJ Net-এর গ্রাহক হলে সাপোর্ট থেকে লগইন তথ্য নিতে পারেন। নতুন সংযোগের জন্যও যোগাযোগ করুন।',
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
              height: 48,
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
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppInfo.helpline,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
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
