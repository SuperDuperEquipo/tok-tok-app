import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:toktok/config/theme/app_theme.dart';
import 'package:toktok/firebase_options.dart';
import 'package:toktok/presentation/screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tok Tok',
      debugShowCheckedModeBanner: false,
      theme: AppTheme().getTheme(),
      home: const AuthGate(),
    );
  }
}