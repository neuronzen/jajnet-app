import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens.dart';
import 'services.dart';
import 'theme.dart';

class LoginScreenNew extends StatefulWidget {
  const LoginScreenNew({super.key});
  @override
  State<LoginScreenNew> createState() => _LoginScreenNewState();
}

class _LoginScreenNewState extends State<LoginScreenNew> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;

  Future<void> _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthService.signIn(_email.text.trim(), _pass.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
content: Text(e.toString().replaceAll('firebase_auth', 'লগইন')),
behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: JC.white,
      body: Stack(
        children: [
Positioned(
  top: 0,
  left: 0,
  right: 0,
  height: size.height * 0.44,
  child: Container(
    decoration: const BoxDecoration(gradient: JC.heroGradient),
    child: CustomPaint(
      painter: _HeaderPainter(),
      size: Size(size.width, size.height * 0.44),
    ),
  ),
),
..._particles(size),
Positioned(
  top: size.height * 0.38,
  left: 0,
  right: 0,
  bottom: 0,
  child: Container(
    decoration: BoxDecoration(
      color: JC.white,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(42),
      ),
      boxShadow: [
        BoxShadow(
          color: JC.primary.withOpacity(0.18),
          blurRadius: 30,
          offset: const Offset(0, -12),
        ),
      ],
    ),
  ),
),
SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: size.height * 0.06),
        Center(child: _logo()),
        const SizedBox(height: 22),
        Center(
          child: Text(
            'JAJ Net',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
        ),
        SizedBox(height: size.height * 0.10),
        Text(
          'স্বাগতম 👋',
          style: GoogleFonts.hindSiliguri(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: JC.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'আপনার JAJ Net অ্যাকাউন্টে লগইন করুন',
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            color: JC.grey,
          ),
        ),
        const SizedBox(height: 28),
        _field(
          controller: _email,
          label: 'ইমেইল',
          icon: Icons.alternate_email_rounded,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 26),
        _primaryButton(loading: _loading, onTap: _login),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
                child: Container(
                    height: 1, color: JC.greyLight)),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12),
              child: Text(
                'অথবা',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  color: JC.grey,
                ),
              ),
            ),
            Expanded(
                child: Container(
                    height: 1, color: JC.greyLight)),
          ],
        ),
        const SizedBox(height: 20),
        _ghostButton(
          label: 'নতুন অ্যাকাউন্ট খুলুন',
          icon: Icons.person_add_alt_1_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SignupScreenNew(),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: Text(
            'সংস্করণ ১.০.০',
            style: GoogleFonts.hindSiliguri(
              fontSize: 11,
              color: JC.greyLight,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  ),
),
        ],
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
BoxShadow(
  color: JC.primaryDark.withOpacity(0.35),
  blurRadius: 26,
  offset: const Offset(0, 12),
),
        ],
      ),
      child: const Icon(Icons.wifi_rounded,
size: 46, color: JC.primary),
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
        labelStyle:
  GoogleFonts.hindSiliguri(fontSize: 14, color: JC.grey),
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
borderSide: const BorderSide(color: JC.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
  vertical: 20, horizontal: 16),
      ),
    );
  }

  Widget _primaryButton(
      {required bool loading, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: loading ? null : onTap,
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
child: loading
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
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded,
              color: Colors.white, size: 20),
        ],
      ),
        ),
      ),
    );
  }

  Widget _ghostButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
borderRadius: BorderRadius.circular(18),
border: Border.all(
    color: JC.primary.withOpacity(0.35), width: 1.5),
        ),
        child: Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
  Icon(icon, color: JC.primary, size: 20),
  const SizedBox(width: 10),
  Text(
    label,
    style: GoogleFonts.hindSiliguri(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: JC.primary,
    ),
  ),
],
        ),
      ),
    );
  }

  List<Widget> _particles(Size size) {
    return List.generate(18, (i) {
      final left = ((i * 53) % 100) / 100 * size.width;
      final top = ((i * 37) % 100) / 100 * size.height * 0.38;
      final sz = 2.0 + (i % 3);
      return Positioned(
        left: left,
        top: top,
        child: Container(
width: sz,
height: sz,
decoration: BoxDecoration(
  color: Colors.white.withOpacity(0.28),
  shape: BoxShape.circle,
),
        ),
      );
    });
  }
}

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
    if (_name.text.isEmpty ||
        _email.text.isEmpty ||
        _pass.text.isEmpty) return;
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
      color: JC.cream,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: JC.heroGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'কয়েক ধাপেই অ্যাকাউন্ট খুলুন',
            style: GoogleFonts.hindSiliguri(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: JC.ink,
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
  TextField(
    controller: _pass,
    obscureText: _hide,
    style: GoogleFonts.hindSiliguri(
        fontSize: 15, color: JC.ink),
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
        borderSide: const BorderSide(
            color: JC.primary, width: 1.5),
      ),
    ),
  ),
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
    items: AppInfo.packages
        .map((p) => DropdownMenuItem<String>(
              value: p['speed'].toString(),
              child: Text(
                '${p['speed']} — ৳${p['price']}',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 14),
              ),
            ))
        .toList(),
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

  Widget _f(TextEditingController c, String label, IconData icon,
      {TextInputType? kb}) {
    return TextField(
      controller: c,
      keyboardType: kb,
      style: GoogleFonts.hindSiliguri(fontSize: 15, color: JC.ink),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: JC.primary, size: 20),
        labelStyle:
  GoogleFonts.hindSiliguri(fontSize: 14, color: JC.grey),
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
borderSide: const BorderSide(color: JC.primary, width: 1.5),
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
        labelStyle:
  GoogleFonts.hindSiliguri(fontSize: 14, color: JC.grey),
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
borderSide: const BorderSide(color: JC.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _HeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.95, size.height * 0.25),
        40.0 + i * 42,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
