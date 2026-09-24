import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
      body: FutureBuilder<Uint8List>(
        future: InvoiceService.generate(
customerName: (user['name'] ?? '').toString(),
phone: (user['phone'] ?? '').toString(),
address: (user['address'] ?? '').toString(),
package: (user['package'] ?? '').toString(),
months: months,
monthlyPrice: monthlyPrice,
total: (payment['amount'] ?? 0) as int,
trxId: (payment['trxId'] ?? '').toString(),
status: (payment['status'] ?? 'pending').toString(),
date: (payment['createdAt'] is Timestamp)
    ? (payment['createdAt'] as Timestamp).toDate()
    : DateTime.now(),
monthRange: monthRange,
        ),
        builder: (context, snap) {
if (snap.connectionState != ConnectionState.done) {
  return const Center(
      child: CircularProgressIndicator(color: JC.primary));
}
if (snap.hasError) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('ইনভয়েস তৈরি করা যায়নি: ${snap.error}',
          textAlign: TextAlign.center,
          style: GoogleFonts.hindSiliguri(height: 1.5)),
    ),
  );
}
final bytes = snap.data!;
return PdfPreview(
  build: (_) => bytes,
  allowSharing: true,
  allowPrinting: true,
  canChangePageFormat: false,
  canChangeOrientation: false,
  canDebug: false,
  pdfFileName: 'JAJNet_Invoice.pdf',
);
        },
      ),
    );
  }
}
