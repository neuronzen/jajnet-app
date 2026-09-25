new_invoice = '''import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'theme.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final Map<String, dynamic> payment;
  final Map<String, dynamic> user;
  final int months;
  final int monthlyPrice;
  final String monthRange;

  const InvoicePreviewScreen({
    super.key,
    required this.payment,
    required this.user,
    required this.months,
    required this.monthlyPrice,
    required this.monthRange,
  });

  String _invoiceNo() {
    final createdAt = payment['createdAt'] as Timestamp?;
    final dt = createdAt?.toDate() ?? DateTime.now();
    final ymd =
        '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
    final trx = (payment['trxId'] ?? '').toString();
    final short = trx.length >= 4
        ? trx.substring(0, 4).toUpperCase()
        : trx.padRight(4, '0').toUpperCase();
    return 'JAJ-\$ymd-\$short';
  }

  String _billingPeriod() {
    final createdAt = payment['createdAt'] as Timestamp?;
    if (createdAt == null) return monthRange;
    final start = createdAt.toDate();
    final end = DateTime(start.year, start.month + 1, start.day)
        .subtract(const Duration(days: 1));
    final fmt = DateFormat('dd MMM');
    return '\${fmt.format(start)} – \${fmt.format(end)} \${start.year}';
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final invoiceDate =
        (payment['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final paymentDate =
        (payment['verifiedAt'] as Timestamp?)?.toDate() ?? invoiceDate;
    final paid = (payment['amount'] ?? 0) as int;
    final previousDue = (payment['dueBefore'] ?? 0) as int;
    final total = previousDue + monthlyPrice * months;
    final remaining = total - paid;

    return Scaffold(
      backgroundColor: JC.greyBg,
      appBar: AppBar(
        title: Text(
          'ইনভয়েস',
          style: GoogleFonts.hindSiliguri(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: JC.ink,
            height: 1.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _shareAsText(
              invoiceNo: _invoiceNo(),
              paid: paid,
              total: total,
              remaining: remaining < 0 ? 0 : remaining,
            ),
            icon: const Icon(Icons.share_rounded, color: JC.primary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: JC.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: JC.ink.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // HEADER
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: JC.heroGradient,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('JAJ Net',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.4,
                                  )),
                              const SizedBox(height: 2),
                              Text('তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.92),
                                    height: 1.5,
                                  )),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('INVOICE',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  height: 1.4,
                                )),
                            const SizedBox(height: 2),
                            Text(_invoiceNo(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.5,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('গ্রাহকের তথ্য'),
                        const SizedBox(height: 10),
                        _row('Customer ID',
                            (user['customerId'] ?? 'N/A').toString()),
                        _row('নাম', (user['name'] ?? '').toString()),
                        _row('মোবাইল', (user['phone'] ?? '').toString()),
                        if ((user['address'] ?? '').toString().isNotEmpty)
                          _row('ঠিকানা', (user['address'] ?? '').toString()),

                        const SizedBox(height: 18),
                        _sectionTitle('সার্ভিসের তথ্য'),
                        const SizedBox(height: 10),
                        _row('Internet Package',
                            '${user['package'] ?? ''} — ৳$monthlyPrice/month'),
                        _row('Billing Period', _billingPeriod()),
                        _row('Connection Status',
                            (user['status'] ?? 'active').toString()[0].toUpperCase() +
                                (user['status'] ?? 'active').toString().substring(1)),

                        const SizedBox(height: 18),
                        _sectionTitle('বিলের হিসাব'),
                        const SizedBox(height: 10),
                        _row('Monthly Charge', '৳$monthlyPrice'),
                        _row('Previous Due', '৳$previousDue'),
                        _row('Discount', '৳0'),
                        const Divider(height: 20, color: JC.creamDeep),
                        _row('Total Due', '৳$total', bold: true),

                        const SizedBox(height: 18),
                        _sectionTitleGreen('পেমেন্টের তথ্য', 'PAID ✓'),
                        const SizedBox(height: 10),
                        _row('Paid', '৳$paid', bold: true),
                        _row('Payment Date', _fmtDate(paymentDate)),
                        _row('Method', (payment['method'] ?? 'bKash').toString()),
                        _row('Transaction ID',
                            (payment['trxId'] ?? 'N/A').toString()),
                        _row('Verification',
                            (payment['status'] ?? 'pending').toString().toUpperCase()),

                        const SizedBox(height: 18),
                        _remainingBox(remaining < 0 ? 0 : remaining),
                      ],
                    ),
                  ),

                  // FOOTER
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: JC.cream,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('JAJ Net • Podoharbaid, Gazipur',
                                style: GoogleFonts.hindSiliguri(
                                    fontSize: 10,
                                    color: JC.grey,
                                    height: 1.5)),
                            Text('01639482397',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: JC.grey,
                                    height: 1.5)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This is a computer-generated invoice and does not require a signature.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 9, color: JC.grey, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final text = _buildShareText(
                        invoiceNo: _invoiceNo(),
                        paid: paid,
                        total: total,
                        remaining: remaining < 0 ? 0 : remaining,
                      );
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('বিস্তারিত কপি হয়েছে',
                              style: GoogleFonts.hindSiliguri(height: 1.5)),
                          backgroundColor: JC.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: JC.primary),
                    label: Text('কপি',
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: JC.primary,
                            height: 1.5)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: JC.primary.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareAsText(
                      invoiceNo: _invoiceNo(),
                      paid: paid,
                      total: total,
                      remaining: remaining < 0 ? 0 : remaining,
                    ),
                    icon: const Icon(Icons.share_rounded,
                        color: Colors.white, size: 18),
                    label: Text('শেয়ার করুন',
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.5)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String s) {
    return Text(s,
        style: GoogleFonts.hindSiliguri(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: JC.ink,
          height: 1.5,
        ));
  }

  Widget _sectionTitleGreen(String s, String badge) {
    return Row(
      children: [
        Text(s,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: JC.ink,
              height: 1.5,
            )),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: JC.success,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(badge,
              style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.5)),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.hindSiliguri(
                fontSize: 12.5,
                color: JC.grey,
                height: 1.5,
              )),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12.5,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: JC.ink,
                  height: 1.5,
                )),
          ),
        ],
      ),
    );
  }

  Widget _remainingBox(int remaining) {
    final isDue = remaining > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDue ? JC.error.withOpacity(0.08) : JC.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDue ? JC.error : JC.success,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Text('Remaining Due',
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: JC.ink,
                height: 1.5,
              )),
          const Spacer(),
          Text('৳$remaining',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDue ? JC.error : JC.success,
                height: 1.4,
              )),
        ],
      ),
    );
  }

  String _buildShareText({
    required String invoiceNo,
    required int paid,
    required int total,
    required int remaining,
  }) {
    final buf = StringBuffer();
    buf.writeln('*JAJ Net — Invoice*');
    buf.writeln('তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক');
    buf.writeln('');
    buf.writeln('Invoice No: \$invoiceNo');
    buf.writeln('Customer ID: \${user['customerId'] ?? 'N/A'}');
    buf.writeln('নাম: \${user['name'] ?? ''}');
    buf.writeln('মোবাইল: \${user['phone'] ?? ''}');
    if ((user['address'] ?? '').toString().isNotEmpty) {
      buf.writeln('ঠিকানা: \${user['address']}');
    }
    buf.writeln('');
    buf.writeln('প্যাকেজ: \${user['package'] ?? ''}');
    buf.writeln('Billing Period: \${_billingPeriod()}');
    buf.writeln('');
    buf.writeln('Total Due: ৳\$total');
    buf.writeln('Paid: ৳\$paid');
    buf.writeln('Remaining: ৳\$remaining');
    buf.writeln('');
    buf.writeln('Payment: \${payment['method'] ?? 'bKash'}');
    buf.writeln('TrxID: \${payment['trxId'] ?? 'N/A'}');
    buf.writeln('Status: \${(payment['status'] ?? 'pending').toString().toUpperCase()}');
    buf.writeln('');
    buf.writeln('JAJ Net • Podoharbaid, Gazipur');
    buf.writeln('Support: 01639482397');
    return buf.toString();
  }

  void _shareAsText({
    required String invoiceNo,
    required int paid,
    required int total,
    required int remaining,
  }) {
    final text = _buildShareText(
      invoiceNo: invoiceNo,
      paid: paid,
      total: total,
      remaining: remaining,
    );
    Share.share(text, subject: 'JAJ Net Invoice');
  }
}
'''

with open('lib/invoice.dart', 'w') as f:
    f.write(new_invoice)
print("✓ invoice.dart converted to native Flutter widget")
print("DONE")
