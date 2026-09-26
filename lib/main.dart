import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'splash.dart';
import 'theme.dart';
import 'notification_service.dart';

final GlobalKey<NavigatorState> jajNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const JajNetApp());
}

class JajNetApp extends StatelessWidget {
  const JajNetApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JAJ Net',
      debugShowCheckedModeBanner: false,
      navigatorKey: jajNavigatorKey,
      theme: buildJajTheme(),
      home: const SplashScreenNew(),
    );
  }
}
