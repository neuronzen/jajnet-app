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
content: Text(
    e.toString().replaceAll('firebase_auth', 'লগইন')),
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
      body: Container(
        decoration: const BoxDecoration(gradient: JC.heroGradient),
        child: SafeArea(
bottom: false,
child: Column(
  children: [
    SizedBox(
      height: 40,
      width: double.infinity,
    ),
    _headerBrand(),
    const SizedBox(height: 28),
    Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: JC.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(38),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Text(
                'স্বাগতম 👋',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: JC.ink,
                  height: 1.2,
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
                  onPressed: () =>
                      setState(() => _hide = !_hide),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'পাসওয়ার্ড ভুলে গেছেন?',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 13,
                      color: JC.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _primaryButton(
                loading: _loading,
                onTap: _login,
              ),
              const SizedBox(height: 22),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: JC.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: JC.creamDeep, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: JC.primary, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'নতুন সংযোগ বা পাসওয়ার্ডের জন্য সাপোর্টে যোগাযোগ করুন',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 12.5, color: JC.ink, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'সংস্করণ ১.০.০',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    color: JC.greyLight,
                  ),
                ),
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
    );
  }

  Widget _headerBrand() {
    return Column(
      children: [
        Container(
width: 78,
height: 78,
decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.18),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ],
),
child: const Icon(Icons.wifi_rounded,
    size: 42, color: JC.primary),
        ),
        const SizedBox(height: 14),
        Text(
'JAJ Net',
style: GoogleFonts.poppins(
  fontSize: 26,
  fontWeight: FontWeight.w700,
  color: Colors.white,
  letterSpacing: 1.4,
),
        ),
        const SizedBox(height: 4),
        Text(
'তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
style: GoogleFonts.hindSiliguri(
  fontSize: 13,
  color: Colors.white.withOpacity(0.94),
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
        prefixIcon: Icon(icon, color: JC.primary, size: 20),
        suffixIcon: suffix,
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
        contentPadding: const EdgeInsets.symmetric(
  vertical: 20, horizontal: 16),
      ),
    );
  }

  Widget _primaryButton({
    required bool loading,
    required VoidCallback onTap,
  }) {
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

  Widget _divider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: JC.greyLight)),
        Padding(
padding: const EdgeInsets.symmetric(horizontal: 12),
child: Text(
  'অথবা',
  style: GoogleFonts.hindSiliguri(
      fontSize: 12, color: JC.grey),
),
        ),
        Expanded(child: Container(height: 1, color: JC.greyLight)),
      ],
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
    color: JC.primary.withOpacity(0.4), width: 1.5),
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
