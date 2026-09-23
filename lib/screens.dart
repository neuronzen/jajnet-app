import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services.dart';
import 'theme.dart';

// ==================== SPLASH ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final u = AuthService.currentUser;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => u == null ? const LoginScreen() : const MainShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: JajColors.primary,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: JajColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.wifi_rounded,
                  size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('JAJ Net',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(AppInfo.tagline,
                style: const TextStyle(
                    fontSize: 14, color: JajColors.textLight)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: JajColors.primary),
          ],
        ),
      ),
    );
  }
}

// ==================== LOGIN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await AuthService.signIn(_email.text.trim(), _pass.text);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('লগইন ব্যর্থ: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: JajColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.wifi_rounded,
                    size: 44, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('JAJ Net',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(AppInfo.tagline,
                  style:
                      TextStyle(fontSize: 14, color: JajColors.textLight)),
              const SizedBox(height: 40),
              const Text('লগইন করুন',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'ইমেইল',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pass,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: 'পাসওয়ার্ড',
                  prefixIcon: const Icon(Icons.lock_outline),
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
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('লগইন'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text('নতুন গ্রাহক? রেজিস্ট্রেশন করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SIGNUP ====================
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _area = AppInfo.areas.first;
  String _pkg = AppInfo.packages.first['speed'];
  bool _loading = false;

  Future<void> _signup() async {
    if (_name.text.isEmpty || _phone.text.isEmpty || _email.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final pkg = AppInfo.packages
          .firstWhere((p) => p['speed'] == _pkg);
      await AuthService.signUp(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
        address: _area,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MainShell()));
      // ignore: unused_local_variable
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
              decoration: const InputDecoration(
                labelText: 'পুরো নাম',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'ইমেইল',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'পাসওয়ার্ড',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _area,
              decoration: const InputDecoration(
                labelText: 'এলাকা',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              items: AppInfo.areas
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _area = v!),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _pkg,
              decoration: const InputDecoration(
                labelText: 'প্যাকেজ',
                prefixIcon: Icon(Icons.wifi_outlined),
              ),
              items: AppInfo.packages
                  .map((p) => DropdownMenuItem<String>(
                        value: p['speed'].toString(),
                        child: Text(
                            '${p['speed']} — ৳${p['price']}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _pkg = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('রেজিস্ট্রেশন'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== MAIN SHELL ====================
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _i = 0;
  final _pages = const [
    HomeTab(),
    BillsTab(),
    SupportTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        backgroundColor: Colors.white,
        indicatorColor: JajColors.accentLight,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: JajColors.primary),
              label: 'হোম'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon:
                  Icon(Icons.receipt_long, color: JajColors.primary),
              label: 'বিল'),
          NavigationDestination(
              icon: Icon(Icons.support_agent_outlined),
              selectedIcon:
                  Icon(Icons.support_agent, color: JajColors.primary),
              label: 'সাপোর্ট'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: JajColors.primary),
              label: 'প্রোফাইল'),
        ],
      ),
    );
  }
}

// ==================== HOME ====================
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: JajColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.wifi_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('JAJ Net',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService.getUserData(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data ?? {};
          final name = d['name'] ?? 'গ্রাহক';
          final pkg = d['package'] ?? '20 Mbps';
          final due = d['dueAmount'] ?? 0;
          final status = d['status'] ?? 'active';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Greeting
              Text('স্বাগতম, $name 👋',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(AppInfo.tagline,
                  style: const TextStyle(
                      fontSize: 13, color: JajColors.textLight)),
              const SizedBox(height: 20),
              // Balance card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [JajColors.primary, JajColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: JajColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('বর্তমান বকেয়া',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('৳ $due',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status.toString().toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                        const Spacer(),
                        const Icon(Icons.speed,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(pkg,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Quick actions
              Row(
                children: [
                  _quick(context, Icons.payment, 'বিল দিন',
                      const PaymentScreen()),
                  _quick(context, Icons.wifi, 'প্যাকেজ',
                      const PackagesScreen()),
                  _quick(context, Icons.call, 'কল', null,
                      url: 'tel:${AppInfo.helpline}'),
                  _quick(context, Icons.chat, 'WhatsApp', null,
                      url:
                          'https://wa.me/${AppInfo.whatsapp}'),
                ],
              ),
              const SizedBox(height: 24),
              const Text('নোটিশ বোর্ড',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: AuthService.notices(),
                builder: (context, s) {
                  if (!s.hasData || s.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: JajColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('এখনো কোনো নোটিশ নেই',
                          style: TextStyle(color: JajColors.textLight)),
                    );
                  }
                  return Column(
                    children: s.data!.docs.map((doc) {
                      final m = doc.data() as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: JajColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.campaign_outlined,
                                color: JajColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(m['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quick(BuildContext context, IconData icon, String label,
      Widget? page, {String? url}) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (page != null) {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => page));
          } else if (url != null) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) launchUrl(uri);
          }
        },
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: JajColors.accentLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: JajColors.primary, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ==================== PACKAGES ====================
class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('প্যাকেজ সমূহ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...AppInfo.packages.map((p) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: JajColors.accentLight, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: JajColors.accentLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.speed,
                        color: JajColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(p['speed'],
                          style: const TextStyle(
                              color: JajColors.textLight, fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  Text('৳${p['price']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: JajColors.primary)),
                ],
              ),
            );
          }),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: JajColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.stars, color: JajColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'কাস্টম প্যাকেজ চাইলে আমাদের হেল্পলাইনে কল করুন',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PAYMENT ====================
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _trx = TextEditingController();
  final _amount = TextEditingController(text: '500');
  bool _loading = false;

  Future<void> _submit() async {
    if (_trx.text.isEmpty || _amount.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthService.submitPayment(
        trxId: _trx.text.trim(),
        amount: int.tryParse(_amount.text) ?? 0,
        method: 'bKash',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'পেমেন্ট জমা হয়েছে। অ্যাডমিন যাচাই করলে অ্যাপে দেখতে পাবেন।'),
          backgroundColor: JajColors.success,
        ),
      );
      _trx.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('সমস্যা: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('বিল পরিশোধ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [JajColors.primary, JajColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('bKash (Send Money)',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  const Text(AppInfo.bkashNumber,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                    'উপরের নাম্বারে Send Money করুন, তারপর TrxID নিচে লিখে সাবমিট করুন।',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                          'tel:${AppInfo.bkashNumber}');
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                    icon: const Icon(Icons.copy,
                        color: Colors.white, size: 18),
                    label: const Text('নাম্বার কপি / কল',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('পেমেন্ট তথ্য',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _trx,
              decoration: const InputDecoration(
                labelText: 'TrxID (যেমন: 9AB12CD34E)',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'পরিমাণ (টাকা)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('সাবমিট করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== BILLS ====================
class BillsTab extends StatelessWidget {
  const BillsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('বিল ও পেমেন্ট')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PaymentScreen())),
                icon: const Icon(Icons.add),
                label: const Text('নতুন পেমেন্ট'),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AuthService.myPayments(),
              builder: (context, s) {
                if (s.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!s.hasData || s.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('এখনো কোনো পেমেন্ট নেই',
                        style: TextStyle(color: JajColors.textLight)),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: s.data!.docs.map((doc) {
                    final m = doc.data() as Map<String, dynamic>;
                    final status = m['status'] ?? 'pending';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: JajColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: JajColors.accentLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_long,
                                color: JajColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('৳ ${m['amount']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text('TrxID: ${m['trxId']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: JajColors.textLight)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: status == 'verified'
                                  ? JajColors.success.withOpacity(0.15)
                                  : JajColors.warning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status == 'verified' ? 'Verified' : 'Pending',
                              style: TextStyle(
                                fontSize: 11,
                                color: status == 'verified'
                                    ? JajColors.success
                                    : JajColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SUPPORT ====================
class SupportTab extends StatelessWidget {
  const SupportTab({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সাপোর্ট')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(context, Icons.call, 'হেল্পলাইনে কল',
              AppInfo.helpline, () => _launch('tel:${AppInfo.helpline}')),
          _card(context, Icons.chat, 'WhatsApp মেসেজ', 'সরাসরি চ্যাট করুন',
              () => _launch('https://wa.me/${AppInfo.whatsapp}')),
          _card(context, Icons.location_on, 'আমাদের এলাকা',
              AppInfo.areas.join(', '), null),
          _card(context, Icons.map, 'Google Map',
              'সার্চ করুন: ${AppInfo.mapSearch}',
              () => _launch(
                  'https://www.google.com/maps/search/${Uri.encodeComponent(AppInfo.mapSearch)}')),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title,
      String sub, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JajColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: JajColors.accentLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: JajColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12, color: JajColors.textLight)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: JajColors.textLight),
          ],
        ),
      ),
    );
  }
}

// ==================== PROFILE ====================
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('প্রোফাইল')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService.getUserData(),
        builder: (context, snap) {
          final d = snap.data ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: JajColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: JajColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['name'] ?? 'গ্রাহক',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(d['phone'] ?? '',
                              style: const TextStyle(
                                  color: JajColors.textLight,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _row(Icons.wifi, 'প্যাকেজ', d['package'] ?? '-'),
              _row(Icons.attach_money, 'মাসিক বিল',
                  '৳ ${d['packagePrice'] ?? '-'}'),
              _row(Icons.location_on, 'এলাকা', d['address'] ?? '-'),
              _row(Icons.email, 'ইমেইল', d['email'] ?? '-'),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.signOut();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout, color: JajColors.error),
                  label: const Text('লগআউট',
                      style: TextStyle(color: JajColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: JajColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const Text('JAJ Net',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: JajColors.textLight)),
                    const SizedBox(height: 4),
                    Text(AppInfo.tagline,
                        style: const TextStyle(
                            fontSize: 12, color: JajColors.textLight)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: JajColors.accentLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: JajColors.primary, size: 22),
          const SizedBox(width: 14),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: JajColors.textLight, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
