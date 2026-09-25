import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'invoice.dart';
import 'charges_screen.dart';
import 'notice_detail.dart';
import 'payment_screen.dart';
import 'screens.dart';
import 'services.dart';
import 'speed_test.dart';
import 'theme.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});
  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _notices = [];
            int _currentMonthCharge = 0;
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
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(u.uid)
            .get(),
        FirebaseFirestore.instance
            .collection('payments')
            .where('userId', isEqualTo: u.uid)
            .get(),
        FirebaseFirestore.instance
            .collection('notices')
            .limit(5)
            .get(),
        FirebaseFirestore.instance
            .collection('billingRecords')
            .where('userId', isEqualTo: u.uid)
            .where('period', isEqualTo: period)
            .get(),
      ]);
      final userDoc = results[0] as DocumentSnapshot;
      final paySnap = results[1] as QuerySnapshot;
      final noticeSnap = results[2] as QuerySnapshot;

      final pays = paySnap.docs.map((d) {
        final m = d.data() as Map<String, dynamic>;
        return <String, dynamic>{'id': d.id, ...m};
      }).toList();
      pays.sort((a, b) {
        final at = a['createdAt'] as Timestamp?;
        final bt = b['createdAt'] as Timestamp?;
        if (at == null || bt == null) return 0;
        return bt.compareTo(at);
      });

      final nots = noticeSnap.docs.map((d) {
        final m = d.data() as Map<String, dynamic>;
        return <String, dynamic>{'id': d.id, ...m};
      }).toList();

      int currentMonthCharge = 0;
      final billingSnap = results[3] as QuerySnapshot;
      if (billingSnap.docs.isNotEmpty) {
        final bm = billingSnap.docs.first.data() as Map<String, dynamic>;
        currentMonthCharge = (bm['charge'] ?? 0) as int;
      }

      if (!mounted) return;
      setState(() {
        _user = userDoc.data() as Map<String, dynamic>?;
        _payments = pays;
        _notices = nots.take(3).toList();
        _currentMonthCharge = currentMonthCharge;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async => await _load();

  DateTime get _nextBillingDate {
    final createdAt = _user?['createdAt'] as Timestamp?;
    if (createdAt == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month + 1, 1);
    }
    final start = createdAt.toDate();
    // Try last verified payment
    Timestamp? lastPay;
    for (final p in _payments) {
      if (p['status'] == 'verified' && p['verifiedAt'] is Timestamp) {
        lastPay = p['verifiedAt'] as Timestamp;
        break;
      }
    }
    final base = lastPay?.toDate() ?? start;
    return DateTime(base.year, base.month + 1, base.day);
  }

  int get _daysToNextBilling {
    return _nextBillingDate.difference(DateTime.now()).inDays;
  }

  String get _nextBillingLabel {
    final d = _nextBillingDate;
    return '${d.day} ${_bnMonths[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
? const Center(
    child: CircularProgressIndicator(color: JC.primary))
: RefreshIndicator(
    onRefresh: _refresh,
    color: JC.primary,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        _header(),
        const SizedBox(height: 20),
        _balanceCard(),
        const SizedBox(height: 24),
        _sectionTitle('দ্রুত কাজ'),
        const SizedBox(height: 12),
        _quickActions(context),
        if (_payments.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle('সাম্প্রতিক পেমেন্ট'),
          const SizedBox(height: 12),
          _paymentsCard(context),
        ],
        if (_notices.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle('নোটিশ বোর্ড'),
          const SizedBox(height: 12),
          _noticesCard(context),
        ],
        const SizedBox(height: 20),
      ],
    ),
  ),
    );
  }

  Widget _header() {
    final name = (_user?['name'] ?? 'গ্রাহক').toString();
    return Row(
      children: [
        Expanded(
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('স্বাগতম, $name 👋',
        style: GoogleFonts.hindSiliguri(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: JC.ink,
            height: 1.5)),
    const SizedBox(height: 2),
    Text('আপনার JAJ Net অ্যাকাউন্ট',
        style: GoogleFonts.hindSiliguri(
            fontSize: 13,
            color: JC.grey,
            height: 1.5)),
  ],
),
        ),
        Container(
width: 46,
height: 46,
decoration: BoxDecoration(
  gradient: JC.heroGradient,
  borderRadius: BorderRadius.circular(14),
  boxShadow: [
    BoxShadow(
      color: JC.primary.withOpacity(0.3),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ],
),
child: const Icon(Icons.wifi_rounded,
    color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _balanceCard() {
    final due = (_user?['dueAmount'] ?? 0) as num;
    final pkg = (_user?['package'] ?? '20 Mbps').toString();
    final status = (_user?['status'] ?? 'active').toString();
    final isPaid = due <= 0;
    final days = _daysToNextBilling;
    final dueSoon = days <= 5 && !isPaid;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: JC.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
BoxShadow(
  color: JC.primary.withOpacity(0.35),
  blurRadius: 26,
  offset: const Offset(0, 12),
),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
// Connection + Package row
Row(
  children: [
    _statusChip(status),
    const Spacer(),
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.speed_rounded,
              color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            pkg,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    ),
  ],
),
const SizedBox(height: 18),
Text('মোট বকেয়া',
    style: GoogleFonts.hindSiliguri(
        color: Colors.white.withOpacity(0.85),
        fontSize: 13,
        height: 1.5)),
const SizedBox(height: 4),
Text(
  '৳ ${NumberFormat('#,##0').format(due)}',
  style: GoogleFonts.poppins(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.3),
),
if ((_user?['monthlyDiscount'] ?? 0) is num && (_user?['monthlyDiscount'] ?? 0) > 0)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '🎁 ৳${_user?['monthlyDiscount']} ছাড়',
            style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4),
          ),
        ),
      ],
    ),
  ),
if (!isPaid && _currentMonthCharge > 0)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      'এই মাস ৳$_currentMonthCharge' +
          (due > _currentMonthCharge
              ? '  •  আগের ৳${NumberFormat('#,##0').format(due - _currentMonthCharge)}'
              : ''),
      style: GoogleFonts.hindSiliguri(
          fontSize: 12.5,
          color: Colors.white.withOpacity(0.95),
          fontWeight: FontWeight.w500,
          height: 1.5),
    ),
  ),

const SizedBox(height: 16),
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.18),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      Icon(
        dueSoon
            ? Icons.warning_amber_rounded
            : Icons.calendar_month_rounded,
        color: Colors.white,
        size: 18,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('পরবর্তী বিল',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5)),
            Text(
              _nextBillingLabel,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.5),
            ),
          ],
        ),
      ),
      if (!isPaid)
        Text(
          '$days দিন',
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.5),
        ),
    ],
  ),
),
const SizedBox(height: 16),
GestureDetector(
  onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const PaymentScreen())),
  child: Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('এখনই পরিশোধ করুন',
            style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: JC.primary,
                height: 1.5)),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_forward_rounded,
            color: JC.primary, size: 18),
      ],
    ),
  ),
),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final isActive = status.toLowerCase() == 'active';
    final color = isActive ? const Color(0xFF10B981) : JC.warning;
    return Container(
      padding:
const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
Container(
  width: 8,
  height: 8,
  decoration: BoxDecoration(
    color: color,
    shape: BoxShape.circle,
  ),
),
const SizedBox(width: 6),
Text(
  isActive ? 'সংযোগ: সক্রিয়' : 'সংযোগ: ${status.toUpperCase()}',
  style: GoogleFonts.hindSiliguri(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: JC.ink,
      height: 1.5),
),
        ],
      ),
    );
  }

  Widget _sectionTitle(String s) => Text(s,
      style: GoogleFonts.hindSiliguri(
fontSize: 16,
fontWeight: FontWeight.w700,
color: JC.ink,
height: 1.5));

  Widget _quickActions(BuildContext context) {
    final items = [
      _QA('বিল দিন', Icons.payments_rounded,
page: const PaymentScreen()),
      _QA('প্যাকেজ', Icons.wifi_rounded,
page: const PackagesScreen()),
      _QA('বিল রেকর্ড', Icons.receipt_long_rounded,
          page: const ChargesScreen()),
      _QA('স্পিড টেস্ট', Icons.speed_rounded,
onTap: () => _showSpeedTest(context)),
    ];
    return Row(
      children: items
.map((it) => Expanded(
      child: GestureDetector(
        onTap: () {
          if (it.page != null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => it.page!));
          } else if (it.onTap != null) {
            it.onTap!();
          }
        },
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: JC.cream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: JC.creamDeep, width: 1.5),
              ),
              child: Icon(it.icon,
                  color: JC.primary, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              it.label,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 11.5,
                  color: JC.ink,
                  fontWeight: FontWeight.w500,
                  height: 1.5),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ))
.toList(),
    );
  }

  void _showSpeedTest(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: JC.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
  BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SpeedTestSheet(),
    );
  }

  void _showInvoiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: JC.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
  BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, controller) => Column(
children: [
  Container(
    margin: const EdgeInsets.only(top: 10),
    width: 40,
    height: 4,
    decoration: BoxDecoration(
        color: JC.greyLight,
        borderRadius: BorderRadius.circular(2)),
  ),
  Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: JC.cream,
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.receipt_long_rounded,
              color: JC.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Text('ইনভয়েস হিস্ট্রি',
            style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: JC.ink,
                height: 1.5)),
      ],
    ),
  ),
  Expanded(
    child: _payments.isEmpty
        ? Center(
            child: Text('এখনো কোনো পেমেন্ট নেই',
                style: GoogleFonts.hindSiliguri(
                    color: JC.grey, height: 1.5)),
          )
        : ListView.separated(
            controller: controller,
            padding: const EdgeInsets.all(16),
            itemCount: _payments.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = _payments[i];
              final s = (p['status'] ?? 'pending')
                  .toString();
              final color = s == 'verified'
                  ? JC.success
                  : s == 'pending'
                      ? JC.warning
                      : JC.error;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoicePreviewScreen(
                      payment: p,
                      user: _user ?? {},
                      months: 1,
                      monthlyPrice: (_user?[
                                  'packagePrice'] ??
                              525) as int,
                      monthRange: (p['createdAt']
                              is Timestamp)
                          ? DateFormat('dd MMMM yyyy').format(
                              (p['createdAt'] as Timestamp)
                                  .toDate())
                          : 'N/A',
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: JC.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: JC.creamDeep, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                            s == 'verified'
                                ? Icons.check_circle_rounded
                                : s == 'pending'
                                    ? Icons.schedule_rounded
                                    : Icons.cancel_rounded,
                            color: color,
                            size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                                '৳ ${p['amount'] ?? 0}',
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: JC.ink,
                                    height: 1.5)),
                            Text(
                                'TrxID: ${p['trxId'] ?? ''}',
                                style: GoogleFonts
                                    .hindSiliguri(
                                        fontSize: 11.5,
                                        color: JC.grey,
                                        height: 1.5)),
                            if (s == 'rejected' && (p['rejectedReason'] ?? '').toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                    'কারণ: ${p['rejectedReason']}',
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 11,
                                        color: JC.error,
                                        height: 1.4)),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                          Icons.chevron_right_rounded,
                          color: JC.grey,
                          size: 22),
                    ],
                  ),
                ),
              );
            },
          ),
  ),
],
        ),
      ),
    );
  }

  Widget _paymentsCard(BuildContext context) {
    final items = _payments.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: JC.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JC.creamDeep, width: 1.5),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
final p = e.value;
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
final isLast = e.key == items.length - 1;
return GestureDetector(
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => InvoicePreviewScreen(
        payment: p,
        user: _user ?? {},
        months: 1,
        monthlyPrice:
            (_user?['packagePrice'] ?? 525) as int,
        monthRange: (p['createdAt'] is Timestamp)
            ? DateFormat('dd MMMM yyyy').format(
                (p['createdAt'] as Timestamp).toDate())
            : 'N/A',
      ),
    ),
  ),
  child: Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(
              bottom: BorderSide(
                  color: JC.creamDeep, width: 1)),
    ),
    child: Row(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('৳ ${p['amount'] ?? 0}',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: JC.ink,
                      height: 1.5)),
              Text('TrxID: ${p['trxId'] ?? ''}',
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 11.5,
                      color: JC.grey,
                      height: 1.5)),
if (s == 'rejected' && (p['rejectedReason'] ?? '').toString().isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Text(
      'কারণ: ${p['rejectedReason']}',
      style: GoogleFonts.hindSiliguri(
        fontSize: 11,
        color: JC.error,
        height: 1.4),
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
                height: 1.5),
          ),
        ),
      ],
    ),
  ),
);
        }).toList(),
      ),
    );
  }

  Widget _noticesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JC.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: JC.creamDeep, width: 1.5),
      ),
      child: Column(
        children: _notices.asMap().entries.map((e) {
final n = e.value;
final isLast = e.key == _notices.length - 1;
return InkWell(
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NoticeDetailScreen(
        title: (n['title'] ?? '').toString(),
        body: (n['body'] ?? '').toString(),
      ),
    ),
  ),
  borderRadius: BorderRadius.circular(18),
  child: Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      border: isLast
          ? null
          : const Border(
              bottom: BorderSide(
                  color: JC.creamDeep, width: 1)),
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
          child: const Icon(Icons.campaign_rounded,
              color: JC.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((n['title'] ?? '').toString(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: JC.ink,
                      height: 1.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text((n['body'] ?? '').toString(),
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      color: JC.grey,
                      height: 1.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded,
            color: JC.grey, size: 22),
      ],
    ),
  ),
);
        }).toList(),
      ),
    );
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Widget? page;
  final VoidCallback? onTap;
  const _QA(this.label, this.icon, {this.page, this.onTap});
}
