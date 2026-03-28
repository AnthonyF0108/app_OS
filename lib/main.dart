import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/pages/ordem_servico.dart';
import 'src/pages/home_page.dart';
import 'firebase_options.dart';

void main() async {
  // Garante a inicialização dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializa o Firebase antes de rodar o App
    await Firebase.initializeApp();
  } catch (e) {
    print("Erro crítico ao iniciar Firebase: $e");
  }

  runApp(const AppFluxoLivre());
}

class AppFluxoLivre extends StatelessWidget {
  const AppFluxoLivre({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fluxo Livre OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Definindo uma cor base escura para combinar com seu logo
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF000033),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Aqui você escolhe:
      // Se quiser ir direto para o formulário, use OrdemServicoPage()
      // Se quiser a tela inicial com o alien e botões, use HomePage()
      home: const HomePage(),
    );
  }
}