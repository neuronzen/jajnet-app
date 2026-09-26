import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'theme.dart';

class SpeedTestSheet extends StatefulWidget {
  const SpeedTestSheet({super.key});
  @override
  State<SpeedTestSheet> createState() => _SpeedTestSheetState();
}

class _SpeedTestSheetState extends State<SpeedTestSheet> {
  bool _running = false;
  double _mbps = 0;
  double _progress = 0;
  String _status = 'শুরু করুন';
  bool _done = false;
  String _detail = '';

  static const int _bytesPerRun = 10000000; // 10 MB
  static const int _warmupBytes = 1500000;  // 1.5 MB

  Future<double> _download(int bytes, {required bool reportProgress}) async {
    final uri = Uri.parse(
        'https://speed.cloudflare.com/__down?bytes=$bytes');
    final client = http.Client();
    final sw = Stopwatch()..start();
    int received = 0;
    try {
      final req = http.Request('GET', uri);
      req.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate';
      req.headers['Pragma'] = 'no-cache';
      final res = await client.send(req);
      await for (final chunk in res.stream) {
        received += chunk.length;
        if (reportProgress && mounted) {
          setState(() {
            _progress = (received / bytes).clamp(0.0, 1.0);
            final sec = sw.elapsedMilliseconds / 1000.0;
            if (sec > 0.25) {
              _mbps = (received * 8) / (sec * 1000000);
            }
          });
        }
      }
      sw.stop();
      final sec = sw.elapsedMilliseconds / 1000.0;
      if (sec <= 0) return 0;
      return (received * 8) / (sec * 1000000);
    } catch (e) {
      return 0;
    } finally {
      client.close();
    }
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _mbps = 0;
      _progress = 0;
      _done = false;
      _detail = '';
      _status = 'ওয়ার্ম-আপ...';
    });

    // Warm-up (discard result)
    await _download(_warmupBytes, reportProgress: false);

    final results = <double>[];

    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      setState(() {
        _status = 'রান ${i + 1} / 3 চলছে...';
        _progress = 0;
      });
      final r = await _download(_bytesPerRun, reportProgress: true);
      if (r > 0) results.add(r);
      // Small pause between runs
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (!mounted) return;

    if (results.isEmpty) {
      setState(() {
        _status = 'টেস্ট ব্যর্থ — ইন্টারনেট চেক করুন';
        _done = true;
        _running = false;
      });
      return;
    }

    // Trim outliers: use median of 3 for stability
    results.sort();
    final avg = results.reduce((a, b) => a + b) / results.length;
    final median = results.length >= 3
        ? results[1]
        : avg;

    setState(() {
      _mbps = median;
      _status = 'সম্পন্ন';
      _done = true;
      _running = false;
      _progress = 1;
      _detail = 'মাঝারি মান (মিডিয়ান) — ৩ রানের '
          '${results.map((e) => e.toStringAsFixed(1)).join(" / ")} Mbps';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: JC.greyLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: JC.heroGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.speed_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'স্পিড টেস্ট',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: JC.ink,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _running || _done ? _progress : 0,
                    strokeWidth: 10,
                    backgroundColor: JC.cream,
                    valueColor:
                        const AlwaysStoppedAnimation(JC.primary),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _done
                          ? _mbps.toStringAsFixed(1)
                          : (_running
                              ? (_mbps > 0
                                  ? _mbps.toStringAsFixed(1)
                                  : '...')
                              : '0'),
                      style: GoogleFonts.poppins(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: JC.primary,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Mbps',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: JC.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: _done && _mbps > 0 ? JC.success : JC.grey,
              height: 1.6,
            ),
          ),
          if (_detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _detail,
              textAlign: TextAlign.center,
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: JC.grey,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _running ? null : _run,
              child: _running
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text('চলছে...',
                            style: GoogleFonts.hindSiliguri(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.5)),
                      ],
                    )
                  : Text(_done ? 'আবার টেস্ট করুন' : 'টেস্ট শুরু করুন',
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '৩টি ধারাবাহিক রান নিয়ে মাঝারি (median) মান দেখানো হয় — '
            'ফলে সাময়িক ওঠানামা এড়ানো যায়',
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
              fontSize: 11,
              color: JC.grey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
