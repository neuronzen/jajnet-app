import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'theme.dart';

class InvoiceService {
  static Future<Uint8List> generate({
    required String customerName,
    required String phone,
    required String address,
    required String package,
    required int months,
    required int monthlyPrice,
    required int total,
    required String trxId,
    required String status,
    required DateTime date,
    required String monthRange,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) {
return pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFF7A1A),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment:
            pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('JAJ Net',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.SizedBox(height: 4),
              pw.Text('তৈরি হোক নিরবিচ্ছিন্ন সম্পর্ক',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
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
                    letterSpacing: 2,
                  )),
              pw.SizedBox(height: 4),
              pw.Text(
                '#${trxId.isEmpty ? "N/A" : trxId.substring(0, trxId.length > 8 ? 8 : trxId.length).toUpperCase()}',
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    pw.SizedBox(height: 24),
    pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFF6EE),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('গ্রাহকের তথ্য',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF151A26),
              )),
          pw.SizedBox(height: 10),
          _row('নাম', customerName),
          _row('মোবাইল', phone),
          if (address.isNotEmpty) _row('ঠিকানা', address),
          _row('প্যাকেজ', package),
        ],
      ),
    ),
    pw.SizedBox(height: 20),
    pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
            color: PdfColor.fromInt(0xFFFFEBD8), width: 1.5),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('পেমেন্টের তথ্য',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF151A26),
              )),
          pw.SizedBox(height: 10),
          _row('তারিখ',
              DateFormat('dd MMMM yyyy').format(date)),
          _row('মাস', monthRange),
          _row('মাসিক বিল', '৳$monthlyPrice'),
          _row('সংখ্যা', '$months মাস'),
          pw.Divider(color: PdfColor.fromInt(0xFFFFEBD8)),
          _row('মোট পরিশোধ', '৳$total',
              bold: true, big: true),
          pw.SizedBox(height: 8),
          _row('TrxID', trxId.isEmpty ? 'N/A' : trxId),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text('স্ট্যাটাস: ',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: status == 'verified'
                      ? PdfColor.fromInt(0xFF10B981)
                      : PdfColor.fromInt(0xFFF59E0B),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  status == 'verified'
                      ? 'VERIFIED'
                      : 'PENDING',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    pw.Spacer(),
    pw.Divider(color: PdfColor.fromInt(0xFFFFEBD8)),
    pw.SizedBox(height: 8),
    pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('JAJ Net • Podoharbaid, Gazipur',
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.grey700)),
        pw.Text('01639482397',
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.grey700)),
      ],
    ),
    pw.SizedBox(height: 4),
    pw.Text(
      'এই ইনভয়েস কম্পিউটার-জেনারেটেড। স্বাক্ষরের প্রয়োজন নেই।',
      style: const pw.TextStyle(
          fontSize: 9, color: PdfColors.grey600),
    ),
  ],
);
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _row(String label, String value,
      {bool bold = false, bool big = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
pw.Text(label,
    style: pw.TextStyle(
      fontSize: big ? 12 : 11,
      color: PdfColors.grey700,
    )),
pw.Text(value,
    style: pw.TextStyle(
      fontSize: big ? 16 : 11,
      fontWeight: bold
          ? pw.FontWeight.bold
          : pw.FontWeight.normal,
      color: PdfColor.fromInt(0xFF151A26),
    )),
        ],
      ),
    );
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
      body: Center(
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
      'নিচের বাটনে ট্যাপ করে PDF ডাউনলোড বা শেয়ার করুন',
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
          _infoRow('TrxID',
              '${payment['trxId'] ?? "N/A"}'),
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
          final messenger =
              ScaffoldMessenger.of(context);
          try {
            final bytes = await InvoiceService.generate(
              customerName:
                  (user['name'] ?? '').toString(),
              phone: (user['phone'] ?? '').toString(),
              address:
                  (user['address'] ?? '').toString(),
              package:
                  (user['package'] ?? '').toString(),
              months: months,
              monthlyPrice: monthlyPrice,
              total: (payment['amount'] ?? 0) as int,
              trxId:
                  (payment['trxId'] ?? '').toString(),
              status:
                  (payment['status'] ?? 'pending')
                      .toString(),
              date: (payment['createdAt'] is Timestamp)
                  ? (payment['createdAt'] as Timestamp)
                      .toDate()
                  : DateTime.now(),
              monthRange: monthRange,
            );
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
            Text('PDF ডাউনলোড / শেয়ার করুন',
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
