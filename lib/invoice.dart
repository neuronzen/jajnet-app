import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
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
    final paymentDate = (widget.payment['verifiedAt'] as Timestamp?)?.toDate() ??
        (widget.payment['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final paid = (widget.payment['amount'] ?? 0) as int;
    final previousDue = (widget.payment['dueBefore'] ?? 0) as int;
    final total = previousDue + widget.monthlyPrice * widget.months;
    final remaining = (total - paid) < 0 ? 0 : (total - paid);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: JC.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('ইনভয়েস',
            style: GoogleFonts.hindSiliguri(
                fontSize: 17, fontWeight: FontWeight.w700, color: JC.ink, height: 1.5)),
        iconTheme: const IconThemeData(color: JC.ink),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============ HEADER ============
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF8A3D), Color(0xFFE55A00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.wifi_rounded,
                                      color: Color(0xFFFF6B00), size: 22),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('JAJ Net',
                                        style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.4,
                                            height: 1.2)),
                                    const SizedBox(height: 1),
                                    Text('তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
                                        style: GoogleFonts.hindSiliguri(
                                            fontSize: 10,
                                            color: Colors.white.withOpacity(0.92),
                                            height: 1.4)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('INVOICE',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white.withOpacity(0.75),
                                            letterSpacing: 3,
                                            height: 1.4)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.22),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(_invoiceNo,
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              height: 1.4)),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('PAID',
                                        style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white.withOpacity(0.75),
                                            letterSpacing: 2,
                                            height: 1.4)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text('৳$paid',
                                            style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                height: 1.2)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _section(
                              icon: Icons.person_rounded,
                              title: 'গ্রাহকের তথ্য',
                              rows: [
                                ('Customer ID', (widget.user['customerId'] ?? 'N/A').toString()),
                                ('নাম', (widget.user['name'] ?? '').toString()),
                                ('মোবাইল', (widget.user['phone'] ?? '').toString()),
                                if ((widget.user['address'] ?? '').toString().isNotEmpty)
                                  ('ঠিকানা', (widget.user['address'] ?? '').toString()),
                              ],
                            ),

                            const SizedBox(height: 14),

                            _section(
                              icon: Icons.wifi_rounded,
                              title: 'সার্ভিস',
                              rows: [
                                ('প্যাকেজ', '${widget.user['package'] ?? ''}'),
                                ('মাসিক বিল', '৳${widget.monthlyPrice}'),
                                ('বিলিং পিরিয়ড', _billingPeriod),
                              ],
                            ),

                            const SizedBox(height: 14),

                            _section(
                              icon: Icons.receipt_long_rounded,
                              title: 'বিলের হিসাব',
                              rows: [
                                ('মাসিক চার্জ', '৳${widget.monthlyPrice}'),
                                ('আগের বাকি', '৳$previousDue'),
                                ('ডিসকাউন্ট', '৳0'),
                              ],
                              footer: _bigRow('সর্বমোট', '৳$total'),
                            ),

                            const SizedBox(height: 14),

                            _section(
                              icon: Icons.payments_rounded,
                              title: 'পেমেন্ট',
                              badge: 'VERIFIED',
                              rows: [
                                ('পরিশোধিত', '৳$paid'),
                                ('তারিখ', _fmtDate(paymentDate)),
                                ('মেথড', (widget.payment['method'] ?? 'bKash').toString()),
                                ('TrxID', (widget.payment['trxId'] ?? 'N/A').toString()),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: remaining > 0
                                      ? [const Color(0xFFFEE2E2), const Color(0xFFFECACA)]
                                      : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    remaining > 0
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_rounded,
                                    color: remaining > 0
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF059669),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text('বাকি আছে',
                                      style: GoogleFonts.hindSiliguri(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: remaining > 0
                                              ? const Color(0xFF991B1B)
                                              : const Color(0xFF065F46),
                                          height: 1.5)),
                                  const Spacer(),
                                  Text('৳$remaining',
                                      style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: remaining > 0
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFF059669),
                                          height: 1.3)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ============ FOOTER ============
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF8F2),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 12, color: Color(0xFF8A92A0)),
                                    const SizedBox(width: 4),
                                    Text('Podoharbaid, Gazipur',
                                        style: GoogleFonts.hindSiliguri(
                                            fontSize: 10, color: JC.grey, height: 1.4)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.phone,
                                        size: 12, color: Color(0xFF8A92A0)),
                                    const SizedBox(width: 4),
                                    Text('01639482397',
                                        style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: JC.grey,
                                            height: 1.4)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This is a computer-generated invoice and does not require a signature.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 9, color: JC.grey, height: 1.4),
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
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _saveToGallery,
                      icon: const Icon(Icons.download_rounded, color: JC.primary, size: 18),
                      label: Text('সেভ',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 14, fontWeight: FontWeight.w700, color: JC.primary, height: 1.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: JC.primary, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _shareImage,
                      icon: _saving
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      label: Text(_saving ? 'অপেক্ষা করুন...' : 'শেয়ার করুন',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, height: 1.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JC.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Widget _section({
    required IconData icon,
    required String title,
    required List<(String, String)> rows,
    Widget? footer,
    String? badge,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFEBD8), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: JC.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: JC.primary),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.hindSiliguri(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: JC.ink,
                      letterSpacing: 0.2,
                      height: 1.4)),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(badge,
                      style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          height: 1.3)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map((r) => _row(r.$1, r.$2)),
          if (footer != null) ...[
            const SizedBox(height: 6),
            Container(height: 1, color: const Color(0xFFFFEBD8)),
            const SizedBox(height: 8),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 11.5, color: JC.grey, height: 1.4)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: JC.ink,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _bigRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: JC.ink,
                height: 1.5)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: JC.primary,
                height: 1.3)),
      ],
    );
  }

  Future<Uint8List> _captureImage() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _saveToGallery() async {
    setState(() => _saving = true);
    try {
      final bytes = await _captureImage();
      final fileName = 'JAJNet_${_invoiceNo.replaceAll('-', '_')}';

      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: fileName,
      );

      if (!mounted) return;
      final success = result != null && result['isSuccess'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'ইনভয়েস গ্যালারিতে সেভ হয়েছে'
                : 'সেভ করা যায়নি',
            style: GoogleFonts.hindSiliguri(height: 1.5),
          ),
          backgroundColor: success ? JC.success : JC.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('সেভ করা যায়নি: $e',
              style: GoogleFonts.hindSiliguri(height: 1.5)),
          backgroundColor: JC.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _saving = true);
    try {
      final bytes = await _captureImage();
      final dir = await getTemporaryDirectory();
      final fileName = 'JAJNet_${_invoiceNo.replaceAll('-', '_')}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'JAJ Net Invoice — $_invoiceNo',
        text: 'JAJ Net ইনভয়েস — $_invoiceNo',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('শেয়ার করা যায়নি: $e',
              style: GoogleFonts.hindSiliguri(height: 1.5)),
          backgroundColor: JC.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
