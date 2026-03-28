import 'package:flutter/material.dart';
import 'lista_clientes_page.dart';
import 'ordem_servico.dart';
import 'historico_os_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FLUXO LIVRE - GESTÃO'),
        centerTitle: true,
        backgroundColor: const Color(0xFF000033), // Azul escuro do seu logo
        foregroundColor: Colors.white,
        elevation: 10,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF000033), Colors.blueGrey.shade900],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _menuCard(
                context,
                "Cadastrar Cliente",
                Icons.person_add_alt_1,
                Colors.blueAccent,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ListaClientesPage()),
                ),
              ),
              _menuCard(
                context,
                "Nova OS",
                Icons.note_add,
                Colors.greenAccent,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdemServicoPage()),
                ),
              ),
              _menuCard(
                context,
                "Histórico / Listar",
                Icons.analytics_outlined,
                Colors.orangeAccent,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoricoOSPage())),
              ),
              _menuCard(
                context,
                "Configurações",
                Icons.settings_suggest,
                Colors.blueGrey,
                    () => print("Configurações clicado"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, String titulo, IconData icone, Color cor, VoidCallback acao) {
    return InkWell(
      onTap: acao,
      borderRadius: BorderRadius.circular(20),
      child: Card(
        color: Colors.white.withOpacity(0.1), // Estilo levemente transparente (Glassmorphism)
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cor.withOpacity(0.5), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 40, color: cor),
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}