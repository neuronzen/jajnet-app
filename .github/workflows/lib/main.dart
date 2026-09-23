import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const JajNetApp());
}

class JajNetApp extends StatelessWidget {
  const JajNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = buildJajTheme();
    return MaterialApp(
      title: 'JAJ Net',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.hindSiliguriTextTheme(base.textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}
