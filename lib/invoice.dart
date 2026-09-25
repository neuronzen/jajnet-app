import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
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
    final ymd =
        '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
    final trx = (widget.payment['trxId'] ?? '').toString();
    final short = trx.length >= 4
        ? trx.substring(0, 4).toUpperCase()
        : trx.padRight(4, '0').toUpperCase();
    return 'JAJ-$ymd-$short';
  }

  String get _billingMonth {
    final createdAt = widget.payment['createdAt'] as Timestamp?;
    if (createdAt == null) return widget.monthRange;
    return DateFormat('MMM yyyy').format(createdAt.toDate());
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
    final invoiceDate = (widget.payment['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.now();
    final paymentDate = (widget.payment['verifiedAt'] as Timestamp?)?.toDate() ??
        invoiceDate;
    final paid = (widget.payment['amount'] ?? 0) as int;
    final previousDue = (widget.payment['dueBefore'] ?? 0) as int;
    final subtotal = previousDue + widget.monthlyPrice * widget.months;
    final total = subtotal - paid;
    final remaining = total < 0 ? 0 : total;
    final isPaid = remaining == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: JC.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('ইনভয়েস',
            style: GoogleFonts.hindSiliguri(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: JC.ink,
                height: 1.5)),
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
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ============ HEADER ============
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF8A3D), Color(0xFFE55A00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.wifi_rounded,
                                      color: Color(0xFFFF6B00), size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('JAJ Net',
                                          style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.4,
                                              height: 1.2)),
                                      Text('Internet Service Provider',
                                          style: GoogleFonts.hindSiliguri(
                                              fontSize: 10,
                                              color: Colors.white
                                                  .withOpacity(0.85),
                                              height: 1.4)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('INVOICE',
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 2.5,
                                            height: 1.2)),
                                    Text(_invoiceNo,
                                        style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            height: 1.4)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 11, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text('Podoharbaid, Gazipur',
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.4)),
                                const SizedBox(width: 12),
                                const Icon(Icons.phone,
                                    size: 11, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text('01639482397',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.white.withOpacity(0.9),
                                        height: 1.4)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ============ BILL TO / INVOICE INFO ============
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bill To
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionLabel('BILL TO'),
                                  const SizedBox(height: 6),
                                  Text(
                                    (widget.user['name'] ?? '').toString(),
                                    style: GoogleFonts.hindSiliguri(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: JC.ink,
                                        height: 1.4),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('ID: ',
                                          style: GoogleFonts.hindSiliguri(
                                              fontSize: 11,
                                              color: JC.grey,
                                              height: 1.4)),
                                      Text(
                                        (widget.user['customerId'] ?? 'N/A')
                                            .toString(),
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: JC.primary,
                                            height: 1.4),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (widget.user['phone'] ?? '').toString(),
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: JC.inkSoft,
                                        height: 1.5),
                                  ),
                                  if ((widget.user['address'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Text(
                                      (widget.user['address'] ?? '').toString(),
                                      style: GoogleFonts.hindSiliguri(
                                          fontSize: 11,
                                          color: JC.grey,
                                          height: 1.4),
                                    ),
                                ],
                              ),
                            ),
                            // Invoice Info
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _sectionLabel('INVOICE INFO'),
                                  const SizedBox(height: 6),
                                  _miniRow('Billing Month', _billingMonth),
                                  _miniRow('Issue Date', _fmtDate(invoiceDate)),
                                  _miniRow('Period', _billingPeriod),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      Container(
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          height: 1,
                          color: const Color(0xFFF0F0F0)),

                      // ============ ITEMS TABLE ============
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('DESCRIPTION',
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: JC.grey,
                                          letterSpacing: 0.6,
                                          height: 1.4)),
                                ),
                                Text('AMOUNT',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: JC.grey,
                                        letterSpacing: 0.6,
                                        height: 1.4)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _itemLine(
                                'Internet Package — ${widget.user['package'] ?? ''}',
                                '৳${widget.monthlyPrice * widget.months}'),
                            _itemLine('Previous Due', '৳$previousDue'),
                            _itemLine('Discount', '৳0'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      Container(
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          height: 1,
                          color: const Color(0xFFF0F0F0)),

                      // ============ TOTALS ============
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                        child: Column(
                          children: [
                            _totalLine('Subtotal', '৳$subtotal'),
                            _totalLine('Discount', '৳0'),
                            _totalLine('Paid', '৳$paid'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ============ TOTAL BOX (FOCAL POINT) ============
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPaid
                                  ? [
                                      const Color(0xFF059669),
                                      const Color(0xFF10B981),
                                    ]
                                  : [
                                      const Color(0xFFDC2626),
                                      const Color(0xFFEF4444),
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (isPaid
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444))
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPaid ? 'TOTAL PAID' : 'TOTAL DUE',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withOpacity(0.85),
                                        letterSpacing: 1.5,
                                        height: 1.4),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '৳${isPaid ? paid : remaining}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.2),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.22),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPaid
                                      ? Icons.check_rounded
                                      : Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ============ PAYMENT STATUS ============
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Expanded(
                              child: _paymentDetail(
                                'Payment Method',
                                (widget.payment['method'] ?? 'bKash')
                                    .toString(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _paymentDetail(
                                'TrxID',
                                (widget.payment['trxId'] ?? 'N/A').toString(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _paymentDetail(
                                'Status',
                                (widget.payment['status'] ?? 'pending')
                                    .toString()
                                    .toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ============ FOOTER ============
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF8F2),
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Support: 01639482397  •  WhatsApp: 01639482397',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: JC.graphite,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ধন্যবাদ JAJ Net বেছে নেওয়ার জন্য',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: JC.primary,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'This is a computer-generated invoice and does not require a signature.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 8.5, color: JC.grey, height: 1.4),
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
                      icon: const Icon(Icons.download_rounded,
                          color: JC.primary, size: 18),
                      label: Text('সেভ',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: JC.primary,
                              height: 1.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: JC.primary, width: 1.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.share_rounded,
                              color: Colors.white, size: 18),
                      label: Text(_saving ? 'অপেক্ষা করুন...' : 'শেয়ার করুন',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JC.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
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

  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: JC.primary,
            letterSpacing: 1.2,
            height: 1.4));
  }

  Widget _miniRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$label: ',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 10.5, color: JC.grey, height: 1.4)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: JC.ink,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _itemLine(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.hindSiliguri(
                    fontSize: 12, color: JC.ink, height: 1.4)),
          ),
          Text(amount,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: JC.ink,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _totalLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$label ',
              style: GoogleFonts.hindSiliguri(
                  fontSize: 11.5, color: JC.grey, height: 1.4)),
          const SizedBox(width: 8),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: JC.ink,
                  height: 1.4)),
        ],
      ),
    );
  }

  Widget _paymentDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 9, color: JC.grey, height: 1.4)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: JC.ink,
                  height: 1.4)),
        ],
      ),
    );
  }

  Future<Uint8List> _captureImage() async {
    final boundary = _boundaryKey.currentContext!.findRenderObject()
        as RenderRepaintBoundary;
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
              success ? 'গ্যালারিতে সেভ হয়েছে (Pictures folder)' : 'সেভ করা যায়নি',
              style: GoogleFonts.hindSiliguri(height: 1.5)),
          backgroundColor: success ? JC.success : JC.error,
          behavior: SnackBarBehavior.floating,
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
