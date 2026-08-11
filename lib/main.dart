import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // FIXED: Removed DefaultFirebaseOptions. Use simple init for manual setup.
  await Firebase.initializeApp();
  runApp(const AgroConnectApp());
}

class AgroConnectApp extends StatelessWidget {
  const AgroConnectApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LandingPage(),
    );
  }
}
