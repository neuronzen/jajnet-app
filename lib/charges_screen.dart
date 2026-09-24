import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'services.dart';
import 'theme.dart';

class ChargesScreen extends StatefulWidget {
  const ChargesScreen({super.key});
  @override
  State<ChargesScreen> createState() => _ChargesScreenState();
}

class _ChargesScreenState extends State<ChargesScreen> {
  List<Map<String, dynamic>> _charges = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  static const List<String> _bnMonths = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = AuthService.currentUser;
    if (u == null) return;
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('billingRecords')
            .where('userId', isEqualTo: u.uid)
            .get(),
        FirebaseFirestore.instance
            .collection('payments')
            .where('userId', isEqualTo: u.uid)
            .get(),
      ]);

      final chs = results[0].docs.map((d) {
        final m = d.data();
        return <String, dynamic>{
          'period': (m['period'] ?? '').toString(),
          'charge': (m['charge'] ?? 0) as int,
        };
      }).toList();
      chs.sort((a, b) =>
          (b['period'] ?? '').toString().compareTo((a['period'] ?? '').toString()));

      final pays = results[1].docs.map((d) {
        final m = d.data();
        return <String, dynamic>{
          'amount': (m['amount'] ?? 0) as int,
          'status': (m['status'] ?? 'pending').toString(),
          'trxId': (m['trxId'] ?? '').toString(),
          'method': (m['method'] ?? 'bKash').toString(),
          'createdAt': m['createdAt'],
          'rejectedReason': (m['rejectedReason'] ?? '').toString(),
        };
      }).toList();
      pays.sort((a, b) {
        final at = a['createdAt'] as Timestamp?;
        final bt = b['createdAt'] as Timestamp?;
        if (at == null || bt == null) return 0;
        return bt.compareTo(at);
      });

      if (!mounted) return;
      setState(() {
        _charges = chs;
        _payments = pays;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Charges load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtPeriod(String period) {
    try {
      final parts = period.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return '${_bnMonths[m - 1]} $y';
    } catch (_) {
      return period;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JC.white,
      appBar: AppBar(
        title: Text(
          'বিল রেকর্ড',
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: JC.ink,
            height: 1.5,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: JC.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: JC.primary,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_charges.isEmpty && _payments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 60,
                            color: JC.grey.withOpacity(0.4),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'এখনো কোনো বিল বা পেমেন্ট নেই',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              color: JC.grey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_charges.isNotEmpty) ...[
                    Text(
                      'মাসিক বিল চার্জ',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: JC.ink,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: JC.white,
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: JC.creamDeep, width: 1.5),
                      ),
                      child: Column(
                        children: _charges.asMap().entries.map((e) {
                          final c = e.value;
                          final isLast = e.key == _charges.length - 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : const Border(
                                      bottom: BorderSide(
                                          color: JC.creamDeep, width: 1),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: JC.cream,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: JC.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fmtPeriod(
                                        (c['period'] ?? '').toString()),
                                    style: GoogleFonts.hindSiliguri(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: JC.ink,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  '৳ ${c['charge']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: JC.error,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_payments.isNotEmpty) ...[
                    Text(
                      'পেমেন্ট হিস্ট্রি',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: JC.ink,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._payments.map((p) {
                      final s = (p['status'] ?? 'pending').toString();
                      final color = s == 'verified'
                          ? JC.success
                          : s == 'pending'
                              ? JC.warning
                              : JC.error;
                      final icon = s == 'verified'
                          ? Icons.check_circle_rounded
                          : s == 'pending'
                              ? Icons.schedule_rounded
                              : Icons.cancel_rounded;
                      final date = (p['createdAt'] is Timestamp)
                          ? DateFormat('dd MMM yyyy').format(
                              (p['createdAt'] as Timestamp).toDate())
                          : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: JC.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: JC.creamDeep, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(icon, color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '৳ ${p['amount']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: JC.ink,
                                          height: 1.5,
                                        ),
                                      ),
                                      if (date.isNotEmpty)
                                        Text(
                                          date,
                                          style:
                                              GoogleFonts.hindSiliguri(
                                            fontSize: 11.5,
                                            color: JC.grey,
                                            height: 1.5,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    s == 'verified'
                                        ? 'VERIFIED'
                                        : s == 'pending'
                                            ? 'PENDING'
                                            : 'REJECTED',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                      letterSpacing: 0.4,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (s == 'rejected' &&
                                (p['rejectedReason'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 52),
                                child: Text(
                                  'কারণ: ${p['rejectedReason']}',
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 12,
                                    color: JC.error,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
