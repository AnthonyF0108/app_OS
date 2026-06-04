import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '../src/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CORREÇÃO: passar DefaultFirebaseOptions.currentPlatform evita
  // erro silencioso de "app already initialized" em hot-restart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const AppAFMotors());
}

class AppAFMotors extends StatelessWidget {
  const AppAFMotors({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AF Motors & Serviços',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF000033),
          brightness: Brightness.dark,
        ),
        // Garante que todos os AlertDialogs herdem o tema escuro
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1A1A2E),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          contentTextStyle: const TextStyle(color: Colors.white70),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}