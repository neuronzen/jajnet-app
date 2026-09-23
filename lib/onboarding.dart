import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens.dart';
import 'theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    _Slide(
      icon: Icons.wifi_rounded,
      title: 'দ্রুতগতির ইন্টারনেট',
      subtitle:
          'আপনার প্রয়োজন অনুযায়ী প্যাকেজ বেছে নিন। ২০ থেকে ১০০ Mbps পর্যন্ত।',
      color: JC.primary,
    ),
    _Slide(
      icon: Icons.payments_rounded,
      title: 'সহজ বিল পরিশোধ',
      subtitle: 'bKash দিয়ে ঘরে বসেই বিল পরিশোধ করুন, কোনো ঝামেলা ছাড়াই।',
      color: Color(0xFF10B981),
    ),
    _Slide(
      icon: Icons.support_agent_rounded,
      title: 'সার্বক্ষণিক সাপোর্ট',
      subtitle: 'সমস্যা হলে অ্যাপ থেকেই কল করুন বা WhatsApp করুন সাথে সাথে।',
      color: Color(0xFF3B82F6),
    ),
    _Slide(
      icon: Icons.notifications_active_rounded,
      title: 'সব খবর হাতের মুঠোয়',
      subtitle: 'নোটিশ, অফার আর আপনার অ্যাকাউন্টের সব তথ্য এক অ্যাপে।',
      color: JC.primary,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JC.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'এড়িয়ে যান',
                  style: GoogleFonts.hindSiliguri(
                    color: JC.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _buildSlide(_slides[i]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _page == i ? 28 : 8,
                  decoration: BoxDecoration(
                    color: _page == i ? JC.primary : JC.greyLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Next button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _page == _slides.length - 1 ? 'শুরু করুন' : 'পরবর্তী',
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_Slide s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  s.color.withOpacity(0.15),
                  s.color.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: JC.white,
                  boxShadow: [
                    BoxShadow(
                      color: s.color.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(s.icon, size: 56, color: s.color),
              ),
            ),
          ),
          const SizedBox(height: 56),
          Text(
            s.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: JC.charcoal,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
              fontSize: 15,
              color: JC.grey,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _Slide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
