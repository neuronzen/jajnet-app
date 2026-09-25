import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'services.dart';
import 'theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _trx = TextEditingController();
  int _months = 1;
  int _packagePrice = 500;
            int _monthlyDiscount = 0;
  int _currentDue = 0;
  String _packageName = '20 Mbps';
  bool _loading = false;
  bool _fetching = true;

  static const List<int> _monthOptions = [1, 2, 3, 6, 12];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _trx.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final u = AuthService.currentUser;
    if (u == null) return;
    try {
      final doc = await FirebaseFirestore.instance
.collection('users')
.doc(u.uid)
.get();
      final d = doc.data() ?? {};
      if (!mounted) return;
      setState(() {
        _packagePrice = _toInt(d['packagePrice'], 500);
        _currentDue = _toInt(d['dueAmount'], 0);
        _monthlyDiscount = _toInt(d['monthlyDiscount'], 0);
        _packageName = (d['package'] ?? '20 Mbps').toString();
        _fetching = false;
      });
    } catch (e) {
      debugPrint('load user error: $e');
      if (mounted) setState(() => _fetching = false);
    }
  }

  int _toInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  int get _effectivePrice => (_packagePrice - _monthlyDiscount).clamp(0, 999999);
            int get _totalAmount => _months * _effectivePrice;

  Future<void> _copyNumber() async {
    await Clipboard.setData(
        const ClipboardData(text: AppInfo.bkashNumber));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
children: [
  const Icon(Icons.check_circle_rounded,
      color: Colors.white, size: 20),
  const SizedBox(width: 8),
  Expanded(
    child: Text(
      'নাম্বার কপি হয়েছে: ${AppInfo.bkashNumber}',
      style: GoogleFonts.hindSiliguri(height: 1.5),
    ),
  ),
],
        ),
        backgroundColor: JC.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submit() async {
    if (_trx.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
content: Text('TrxID দিন',
    style: GoogleFonts.hindSiliguri(height: 1.5)),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.submitPayment(
        trxId: _trx.text.trim(),
        amount: _totalAmount,
        method: 'bKash',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
content: Text(
  'পেমেন্ট জমা হয়েছে। যাচাই হলে অ্যাপে দেখতে পাবেন।',
  style: GoogleFonts.hindSiliguri(height: 1.5),
),
backgroundColor: JC.success,
behavior: SnackBarBehavior.floating,
        ),
      );
      _trx.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
content: Text('সমস্যা: $e',
    style: GoogleFonts.hindSiliguri(height: 1.5)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) {
      return const Scaffold(
        body:
  Center(child: CircularProgressIndicator(color: JC.primary)),
      );
    }
    return Scaffold(
      backgroundColor: JC.white,
      appBar: AppBar(
        title: Text(
'বিল পরিশোধ',
style: GoogleFonts.hindSiliguri(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: JC.ink,
  height: 1.5,
),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
  _bkashCard(),
  const SizedBox(height: 24),
  _sectionTitle('পেমেন্ট তথ্য'),
  const SizedBox(height: 10),
  _infoRow('মাসিক বিল', '৳$_packagePrice'),
                      if (_monthlyDiscount > 0)
                        _infoRow('ডিসকাউন্ট', '- ৳$_monthlyDiscount',
                            highlight: true, green: true),
  _infoRow('প্যাকেজ', _packageName),
  if (_currentDue > 0)
    _infoRow('বর্তমান বকেয়া', '৳$_currentDue',
        highlight: true),
  const SizedBox(height: 22),
  _sectionTitle('কত মাসের বিল দিচ্ছেন?'),
  const SizedBox(height: 10),
  _monthChips(),
  const SizedBox(height: 20),
  _amountCard(),
  const SizedBox(height: 20),
  _trxField(),
  const SizedBox(height: 20),
  _submitButton(),
  const SizedBox(height: 30),
],
        ),
      ),
    );
  }

  Widget _sectionTitle(String s) => Text(
        s,
        style: GoogleFonts.hindSiliguri(
fontSize: 15,
fontWeight: FontWeight.w700,
color: JC.ink,
height: 1.5,
        ),
      );

  Widget _bkashCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: JC.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
BoxShadow(
  color: JC.primary.withOpacity(0.3),
  blurRadius: 20,
  offset: const Offset(0, 10),
),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
Row(
  children: [
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'bKash',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.5,
        ),
      ),
    ),
    const SizedBox(width: 8),
    Text(
      'Send Money',
      style: GoogleFonts.hindSiliguri(
        fontSize: 12,
        color: Colors.white.withOpacity(0.9),
        height: 1.5,
      ),
    ),
  ],
),
const SizedBox(height: 12),
Text(
  AppInfo.bkashNumber,
  style: GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.4,
  ),
),
const SizedBox(height: 8),
Text(
  'উপরের নাম্বারে Send Money করুন, তারপর TrxID নিচে লিখে সাবমিট করুন',
  style: GoogleFonts.hindSiliguri(
    fontSize: 12.5,
    color: Colors.white.withOpacity(0.9),
    height: 1.6,
  ),
),
const SizedBox(height: 16),
GestureDetector(
  onTap: _copyNumber,
  child: Container(
    padding: const EdgeInsets.symmetric(
        vertical: 14, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.copy_rounded,
            color: JC.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          'নাম্বার কপি করুন',
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: JC.primary,
            height: 1.5,
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

  Widget _infoRow(String label, String value,
      {bool highlight = false, bool green = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
Text(
  label,
  style: GoogleFonts.hindSiliguri(
    fontSize: 14,
    color: JC.grey,
    height: 1.5,
  ),
),
const Spacer(),
Text(
  value,
  style: GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: green ? JC.success : (highlight ? JC.error : JC.ink),
    height: 1.5,
  ),
),
        ],
      ),
    );
  }

  Widget _monthChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _monthOptions.map((m) {
        final active = _months == m;
        final label = m == 12 ? '১ বছর' : '$m মাস';
        return GestureDetector(
onTap: () => setState(() => _months = m),
child: Container(
  padding: const EdgeInsets.symmetric(
      horizontal: 20, vertical: 12),
  decoration: BoxDecoration(
    color: active ? JC.primary : JC.cream,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: active ? JC.primary : JC.creamDeep,
      width: 1.5,
    ),
  ),
  child: Text(
    label,
    style: GoogleFonts.hindSiliguri(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: active ? Colors.white : JC.ink,
      height: 1.5,
    ),
  ),
),
        );
      }).toList(),
    );
  }

  Widget _amountCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JC.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JC.creamDeep, width: 1.5),
      ),
      child: Row(
        children: [
Container(
  width: 44,
  height: 44,
  decoration: BoxDecoration(
    color: JC.primary.withOpacity(0.12),
    borderRadius: BorderRadius.circular(12),
  ),
  child: const Icon(Icons.attach_money_rounded,
      color: JC.primary, size: 22),
),
const SizedBox(width: 14),
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'মোট পরিশোধ',
        style: GoogleFonts.hindSiliguri(
          fontSize: 12,
          color: JC.grey,
          height: 1.5,
        ),
      ),
      Text(
        '৳ ${NumberFormat('#,##0').format(_totalAmount)}',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: JC.primary,
          height: 1.5,
        ),
      ),
    ],
  ),
),
        ],
      ),
    );
  }

  Widget _trxField() {
    return TextField(
      controller: _trx,
      style: GoogleFonts.poppins(
fontSize: 14, color: JC.ink, height: 1.5),
      decoration: InputDecoration(
        labelText: 'TrxID',
        hintText: 'যেমন: 9AB12CD34E',
        prefixIcon: const Icon(
  Icons.confirmation_number_outlined,
  color: JC.primary,
  size: 20),
        labelStyle:
  GoogleFonts.hindSiliguri(fontSize: 14, color: JC.grey),
        hintStyle:
  GoogleFonts.hindSiliguri(fontSize: 13, color: JC.grey),
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
  vertical: 18, horizontal: 16),
      ),
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: _loading ? null : _submit,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
gradient: JC.heroGradient,
borderRadius: BorderRadius.circular(18),
boxShadow: [
  BoxShadow(
    color: JC.primary.withOpacity(0.35),
    blurRadius: 20,
    offset: const Offset(0, 10),
  ),
],
        ),
        child: Center(
child: _loading
    ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
            color: Colors.white, strokeWidth: 2.5),
      )
    : Text(
        'সাবমিট করুন',
        style: GoogleFonts.hindSiliguri(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.5,
        ),
      ),
        ),
      ),
    );
  }
}
