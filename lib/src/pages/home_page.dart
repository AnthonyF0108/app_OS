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
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        elevation: 0, // Removi a elevação para combinar com o gradiente
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ListaClientesPage())),
              ),
              _menuCard(
                context,
                "Nova OS",
                Icons.note_add,
                Colors.greenAccent,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrdemServicoPage())),
              ),
              _menuCard(
                context,
                "Histórico / Listar",
                Icons.analytics_outlined,
                Colors.orangeAccent,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoricoOSPage())),
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
        color: Colors.white.withOpacity(0.08), // Efeito Glassmorphism
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cor.withOpacity(0.4), width: 1.5), // Borda sutil com a cor do ícone
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 38, color: cor),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}