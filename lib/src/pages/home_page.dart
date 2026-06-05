import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import 'lista_clientes_page.dart';
import 'ordem_servico.dart';
import 'historico_os_page.dart';
import 'fluxo_caixa_page.dart';
import 'historico_veiculos_page.dart';
import 'motos_leilao_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Dados dos menus: (título, ícone, cor, destino)
  static final _menus = <_MenuItem>[
    _MenuItem('Clientes',         Icons.person_add_alt_1,       Colors.blueAccent,   (_) => const ListaClientesPage()),
    _MenuItem('Nova OS',          Icons.note_add,               Colors.greenAccent,  (_) => const OrdemServicoPage()),
    _MenuItem('Histórico OS',     Icons.analytics_outlined,     Colors.orangeAccent, (_) => const HistoricoOSPage()),
    _MenuItem('Fluxo de Caixa',   Icons.account_balance_wallet, Colors.purpleAccent, (_) => const FluxoCaixaPage()),
    _MenuItem('Veículos',         Icons.directions_car,         Colors.cyanAccent,   (_) => const HistoricoVeiculosPage()),
    _MenuItem('Leilão de Motos',  Icons.two_wheeler,            Colors.amberAccent,  (_) => const MotosLeilaoPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Colors.blueGrey.shade900],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    // childAspectRatio ajustado para evitar overflow em telas pequenas
                    childAspectRatio: 1.05,
                  ),
                  itemCount: _menus.length,
                  itemBuilder: (context, index) {
                    final item = _menus[index];
                    return _MenuCard(item: item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── DATA CLASS DO MENU ────────────────────────────────────────────────────────

class _MenuItem {
  final String titulo;
  final IconData icone;
  final Color cor;
  final Widget Function(BuildContext) builder;

  const _MenuItem(this.titulo, this.icone, this.cor, this.builder);
}

// ── CARD DO MENU ──────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final _MenuItem item;

  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: item.builder)),
      borderRadius: BorderRadius.circular(20),
      child: Card(
        color: Colors.white.withOpacity(0.08),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: item.cor.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.cor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icone, size: 36, color: item.cor),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item.titulo,
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