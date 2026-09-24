import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';

class NoticeDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  const NoticeDetailScreen({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JC.white,
      appBar: AppBar(
        title: Text(
'নোটিশ',
style: GoogleFonts.hindSiliguri(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: JC.ink,
  height: 1.4,
),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
  Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      gradient: JC.heroGradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: JC.primary.withOpacity(0.35),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: const Icon(
      Icons.campaign_rounded,
      color: Colors.white,
      size: 32,
    ),
  ),
  const SizedBox(height: 24),
  Text(
    title,
    style: GoogleFonts.hindSiliguri(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: JC.ink,
      height: 1.5,
    ),
  ),
  const SizedBox(height: 12),
  Container(
    width: 44,
    height: 3,
    decoration: BoxDecoration(
      color: JC.primary,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
  const SizedBox(height: 22),
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: JC.cream,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      body.isEmpty ? 'বিস্তারিত তথ্য নেই' : body,
      style: GoogleFonts.hindSiliguri(
        fontSize: 15,
        color: JC.inkSoft,
        height: 1.9,
      ),
    ),
  ),
  const SizedBox(height: 30),
],
        ),
      ),
    );
  }
}
