import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'splash.dart';
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
    return MaterialApp(
      title: 'JAJ Net',
      debugShowCheckedModeBanner: false,
      theme: buildJajTheme(),
      home: const SplashScreenNew(),
    );
  }
}
