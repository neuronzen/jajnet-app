import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'theme.dart';

class InvoiceService {
  static Future<Uint8List> generate({
    required String invoiceNo,
    required String customerId,
    required String customerName,
    required String phone,
    required String address,
    required String package,
    required int monthlyPrice,
    required int total,
    required int paid,
    required int previousDue,
    required int remainingDue,
    required String billingPeriod,
    required String connectionStatus,
    required String method,
    required String trxId,
    required String status,
    required DateTime invoiceDate,
    required DateTime paymentDate,
  }) async {
    final doc = pw.Document();

    // Load fonts
    final bengaliRegular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf'));
    final bengaliBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf'));
    final latinRegular = pw.Font.helvetica();
    final latinBold = pw.Font.helveticaBold();

    final theme = pw.ThemeData.withFont(
      base: latinRegular,
      bold: latinBold,
      fontFallback: [bengaliRegular, bengaliBold],
    );

    final bnTheme = pw.ThemeData.withFont(
      base: bengaliRegular,
      bold: bengaliBold,
      fontFallback: [latinRegular, latinBold],
    );

    String fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ============ HEADER ============
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFF7A1A),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('JAJ Net',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 26,
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.SizedBox(height: 4),
                        pw.Text('তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              font: bengaliRegular,
                            )),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 3,
                            )),
                        pw.SizedBox(height: 4),
                        pw.Text(invoiceNo,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              font: latinBold,
                            )),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ============ CUSTOMER ============
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFFFF6EE),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('গ্রাহকের তথ্য',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          font: bengaliBold,
                          color: PdfColor.fromInt(0xFF151A26),
                        )),
                    pw.SizedBox(height: 10),
                    _row('Customer ID', customerId, theme, latinBold),
                    _rowBn('নাম', customerName, bengaliRegular, bengaliBold),
                    _row('Mobile', phone, theme, latinRegular),
                    if (address.isNotEmpty)
                      _rowBn('ঠিকানা', address, bengaliRegular, bengaliRegular),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ============ SERVICE ============
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFFFEBD8), width: 1.2),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('সার্ভিসের তথ্য',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          font: bengaliBold,
                          color: PdfColor.fromInt(0xFF151A26),
                        )),
                    pw.SizedBox(height: 10),
                    _row('Internet Package', '$package — ৳$monthlyPrice/month', theme, latinRegular),
                    _row('Billing Period', billingPeriod, theme, latinRegular),
                    _row('Connection Status', connectionStatus, theme, latinRegular),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ============ BILLING SUMMARY ============
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFFFEBD8), width: 1.2),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('বিলের হিসাব',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          font: bengaliBold,
                          color: PdfColor.fromInt(0xFF151A26),
                        )),
                    pw.SizedBox(height: 10),
                    _row('Monthly Charge', '৳$monthlyPrice', theme, latinRegular),
                    _row('Previous Due', '৳$previousDue', theme, latinRegular),
                    _row('Discount', '৳0', theme, latinRegular),
                    pw.Divider(color: PdfColor.fromInt(0xFFFFEBD8), thickness: 1),
                    _row('Total Due', '৳$total', theme, latinBold),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ============ PAYMENT ============
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF0FDF4),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(
                    color: PdfColor.fromInt(0xFF10B981),
                    width: 1.2,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('পেমেন্টের তথ্য',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              font: bengaliBold,
                              color: PdfColor.fromInt(0xFF151A26),
                            )),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFF10B981),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Text('PAID ✓',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              )),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    _row('Paid', '৳$paid', theme, latinBold),
                    _row('Payment Date', fmtDate(paymentDate), theme, latinRegular),
                    _row('Method', method, theme, latinRegular),
                    _row('Transaction ID', trxId, theme, latinRegular),
                    _row('Verification', status.toUpperCase(), theme, latinRegular),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ============ REMAINING ============
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: remainingDue > 0
                      ? PdfColor.fromInt(0xFFFFF1F2)
                      : PdfColor.fromInt(0xFFFFF6EE),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(
                    color: remainingDue > 0
                        ? PdfColor.fromInt(0xFFFF4757)
                        : PdfColor.fromInt(0xFFFF6B00),
                    width: 1.2,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Remaining Due',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          font: latinBold,
                          color: PdfColor.fromInt(0xFF151A26),
                        )),
                    pw.Text('৳$remainingDue',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          font: latinBold,
                          color: remainingDue > 0
                              ? PdfColor.fromInt(0xFFFF4757)
                              : PdfColor.fromInt(0xFF10B981),
                        )),
                  ],
                ),
              ),

              pw.Spacer(),

              // ============ FOOTER ============
              pw.Divider(color: PdfColor.fromInt(0xFFFFEBD8), thickness: 1),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('JAJ Net • Podoharbaid, Gazipur',
                      style: pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey700)),
                  pw.Text('Support: 01639482397',
                      style: pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'This is a computer-generated invoice and does not require a signature.',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<void> saveAndShare(Uint8List bytes,
      {String filename = 'JAJNet_Invoice.pdf'}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'JAJ Net Invoice',
    );
  }

  // English labels (value can be Bengali)
  static pw.Widget _row(String label, String value, pw.ThemeData theme,
      pw.Font valueFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                font: valueFont,
                color: PdfColor.fromInt(0xFF151A26),
              )),
        ],
      ),
    );
  }

  // Bengali label
  static pw.Widget _rowBn(
      String label, String value, pw.Font labelFont, pw.Font valueFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                fontSize: 10,
                font: labelFont,
                color: PdfColors.grey700,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                font: valueFont,
                color: PdfColor.fromInt(0xFF151A26),
              )),
        ],
      ),
    );
  }
}

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

  String _buildInvoiceNo(Map<String, dynamic> p) {
    final createdAt = p['createdAt'] as Timestamp?;
    final dt = createdAt?.toDate() ?? DateTime.now();
    final ymd =
        '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
    final trx = (p['trxId'] ?? '').toString();
    final short = trx.length >= 4
        ? trx.substring(0, 4).toUpperCase()
        : trx.padRight(4, '0').toUpperCase();
    return 'JAJ-$ymd-$short';
  }

  String _buildBillingPeriod(Map<String, dynamic> p) {
    final createdAt = p['createdAt'] as Timestamp?;
    if (createdAt == null) return monthRange;
    final start = createdAt.toDate();
    final end = DateTime(start.year, start.month + 1, start.day)
        .subtract(const Duration(days: 1));
    final fmt = DateFormat('dd MMM');
    return '${fmt.format(start)} – ${fmt.format(end)} ${start.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JC.white,
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
      ),
      body: FutureBuilder<Uint8List>(
        future: () async {
          final invoiceDate = (payment['createdAt'] as Timestamp?)?.toDate() ??
              DateTime.now();
          final paymentDate = (payment['verifiedAt'] as Timestamp?)?.toDate() ??
              invoiceDate;
          final paid = (payment['amount'] ?? 0) as int;
          final previousDue = (payment['dueBefore'] ?? 0) as int;
          final total = previousDue + monthlyPrice * months;
          final remaining = total - paid;

          return InvoiceService.generate(
            invoiceNo: _buildInvoiceNo(payment),
            customerId: (user['customerId'] ?? 'N/A').toString(),
            customerName: (user['name'] ?? '').toString(),
            phone: (user['phone'] ?? '').toString(),
            address: (user['address'] ?? '').toString(),
            package: (user['package'] ?? '').toString(),
            monthlyPrice: monthlyPrice,
            total: total,
            paid: paid,
            previousDue: previousDue,
            remainingDue: remaining < 0 ? 0 : remaining,
            billingPeriod: _buildBillingPeriod(payment),
            connectionStatus:
                ((user['status'] ?? 'active').toString()[0].toUpperCase()) +
                    (user['status'] ?? 'active').toString().substring(1),
            method: (payment['method'] ?? 'bKash').toString(),
            trxId: (payment['trxId'] ?? '').toString(),
            status: (payment['status'] ?? 'pending').toString(),
            invoiceDate: invoiceDate,
            paymentDate: paymentDate,
          );
        }(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: JC.primary));
          }
          if (snap.hasError) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ERROR:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.red)),
                  const SizedBox(height: 8),
                  SelectableText('${snap.error}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 20),
                  const Text('STACK TRACE:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.red)),
                  const SizedBox(height: 8),
                  SelectableText('${snap.stackTrace}',
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
            );
          }
          final bytes = snap.data!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: JC.heroGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: JC.primary.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 28),
                  Text('ইনভয়েস তৈরি হয়েছে',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: JC.ink,
                          height: 1.5)),
                  const SizedBox(height: 8),
                  Text(
                    'নিচের বাটনে ট্যাপ করে PDF শেয়ার বা সেভ করুন',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 14, color: JC.grey, height: 1.7),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: JC.cream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _infoRow('পরিমাণ', '৳${payment['amount'] ?? 0}'),
                        _infoRow('TrxID', '${payment['trxId'] ?? "N/A"}'),
                        _infoRow(
                            'স্ট্যাটাস',
                            ((payment['status'] ?? "pending")
                                .toString()
                                .toUpperCase())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await InvoiceService.saveAndShare(
                            bytes,
                            filename:
                                'JAJNet_${payment['trxId'] ?? "Invoice"}.pdf',
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('সমস্যা: $e',
                                  style: GoogleFonts.hindSiliguri(
                                      height: 1.5)),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text('PDF শেয়ার / সেভ করুন',
                              style: GoogleFonts.hindSiliguri(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 13, color: JC.grey, height: 1.5)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: JC.ink,
                  height: 1.5)),
        ],
      ),
    );
  }
}
