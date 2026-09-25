import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'theme.dart';

class InvoicePreviewScreen extends StatefulWidget {
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

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final _boundaryKey = GlobalKey();
  bool _saving = false;

  String get _invoiceNo {
    final createdAt = widget.payment['createdAt'] as Timestamp?;
    final dt = createdAt?.toDate() ?? DateTime.now();
    final ymd = '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
    final trx = (widget.payment['trxId'] ?? '').toString();
    final short = trx.length >= 4
        ? trx.substring(0, 4).toUpperCase()
        : trx.padRight(4, '0').toUpperCase();
    return 'JAJ-$ymd-$short';
  }

  String get _billingPeriod {
    final createdAt = widget.payment['createdAt'] as Timestamp?;
    if (createdAt == null) return widget.monthRange;
    final start = createdAt.toDate();
    final end = DateTime(start.year, start.month + 1, start.day)
        .subtract(const Duration(days: 1));
    final fmt = DateFormat('dd MMM');
    return '${fmt.format(start)} – ${fmt.format(end)} ${start.year}';
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    final invoiceDate = (widget.payment['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final paymentDate = (widget.payment['verifiedAt'] as Timestamp?)?.toDate() ?? invoiceDate;
    final paid = (widget.payment['amount'] ?? 0) as int;
    final previousDue = (widget.payment['dueBefore'] ?? 0) as int;
    final total = previousDue + widget.monthlyPrice * widget.months;
    final remaining = (total - paid) < 0 ? 0 : (total - paid);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: JC.white,
        elevation: 0,
        title: Text('ইনভয়েস',
            style: GoogleFonts.hindSiliguri(
                fontSize: 18, fontWeight: FontWeight.w700, color: JC.ink, height: 1.5)),
        iconTheme: const IconThemeData(color: JC.ink),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============ HEADER ============
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A3D), Color(0xFFE55A00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('JAJ Net',
                                    style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        height: 1.3)),
                                const SizedBox(height: 2),
                                Text('তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.92),
                                        height: 1.5)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('INVOICE',
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 3,
                                        height: 1.3)),
                                const SizedBox(height: 4),
                                Text(_invoiceNo,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.5)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ============ CUSTOMER ============
                      _sectionHeading('গ্রাহকের তথ্য'),
                      const SizedBox(height: 10),
                      _infoRow('Customer ID', (widget.user['customerId'] ?? 'N/A').toString()),
                      _infoRow('নাম', (widget.user['name'] ?? '').toString()),
                      _infoRow('মোবাইল', (widget.user['phone'] ?? '').toString()),
                      if ((widget.user['address'] ?? '').toString().isNotEmpty)
                        _infoRow('ঠিকানা', (widget.user['address'] ?? '').toString()),

                      const SizedBox(height: 20),

                      // ============ SERVICE ============
                      _sectionHeading('সার্ভিসের তথ্য'),
                      const SizedBox(height: 10),
                      _infoRow('Internet Package',
                          '${widget.user['package'] ?? ''} — ৳${widget.monthlyPrice}/month'),
                      _infoRow('Billing Period', _billingPeriod),
                      _infoRow(
                          'Connection Status',
                          (widget.user['status'] ?? 'active').toString()[0].toUpperCase() +
                              (widget.user['status'] ?? 'active').toString().substring(1)),

                      const SizedBox(height: 20),

                      // ============ BILLING ============
                      _sectionHeading('বিলের হিসাব'),
                      const SizedBox(height: 10),
                      _infoRow('Monthly Charge', '৳${widget.monthlyPrice}'),
                      _infoRow('Previous Due', '৳$previousDue'),
                      _infoRow('Discount', '৳0'),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 1,
                        color: const Color(0xFFEEEEEE),
                      ),
                      _infoRow('Total Due', '৳$total', bold: true, large: true),

                      const SizedBox(height: 20),

                      // ============ PAYMENT ============
                      Row(
                        children: [
                          _sectionHeading('পেমেন্টের তথ্য'),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('PAID ✓',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.6,
                                    height: 1.3)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _infoRow('Paid', '৳$paid', bold: true),
                      _infoRow('Payment Date', _fmtDate(paymentDate)),
                      _infoRow('Method', (widget.payment['method'] ?? 'bKash').toString()),
                      _infoRow('Transaction ID', (widget.payment['trxId'] ?? 'N/A').toString()),
                      _infoRow('Verification',
                          (widget.payment['status'] ?? 'pending').toString().toUpperCase()),

                      const SizedBox(height: 18),

                      // ============ REMAINING ============
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: remaining > 0
                              ? const Color(0xFFFFF1F2)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: remaining > 0
                                ? const Color(0xFFFF4757)
                                : const Color(0xFF10B981),
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text('Remaining Due',
                                style: GoogleFonts.hindSiliguri(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: JC.ink,
                                    height: 1.5)),
                            const Spacer(),
                            Text('৳$remaining',
                                style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: remaining > 0
                                        ? const Color(0xFFFF4757)
                                        : const Color(0xFF10B981),
                                    height: 1.3)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ============ FOOTER ============
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('JAJ Net • Podoharbaid, Gazipur',
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 10, color: JC.grey, height: 1.5)),
                                Text('01639482397',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
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
              ),
            ),
          ),

          // ============ ACTION BUTTONS ============
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _captureAndShare(share: false),
                      icon: const Icon(Icons.download_rounded, color: JC.primary, size: 18),
                      label: Text('সেভ',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: JC.primary,
                              height: 1.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: JC.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _captureAndShare(share: true),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.share_rounded,
                              color: Colors.white, size: 18),
                      label: Text(_saving ? 'অপেক্ষা করুন...' : 'ইমেজ শেয়ার করুন',
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
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndShare({required bool share}) async {
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final fileName = 'JAJNet_Invoice_${_invoiceNo.replaceAll('-', '_')}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (share) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/png')],
          subject: 'JAJ Net Invoice — $_invoiceNo',
          text: 'JAJ Net ইনভয়েস — $_invoiceNo',
        );
      } else {
        if (!mounted) return;
        Clipboard.setData(ClipboardData(text: file.path));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ইনভয়েস সেভ হয়েছে: $fileName',
                style: GoogleFonts.hindSiliguri(height: 1.5)),
            backgroundColor: JC.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('সমস্যা: $e', style: GoogleFonts.hindSiliguri(height: 1.5)),
          backgroundColor: JC.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionHeading(String text) {
    return Text(text,
        style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: JC.ink,
            letterSpacing: 0.2,
            height: 1.5));
  }

  Widget _infoRow(String label, String value, {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 12.5, color: JC.grey, height: 1.5)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.hindSiliguri(
                    fontSize: large ? 15 : 12.5,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: JC.ink,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}
