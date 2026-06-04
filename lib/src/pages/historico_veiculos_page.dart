import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../core/shared_widgets.dart';
import 'cadastro_veiculo_page.dart';

class HistoricoVeiculosPage extends StatefulWidget {
  const HistoricoVeiculosPage({super.key});

  @override
  State<HistoricoVeiculosPage> createState() => _HistoricoVeiculosPageState();
}

class _HistoricoVeiculosPageState extends State<HistoricoVeiculosPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Estoque':   return Colors.greenAccent;
      case 'Vendido':   return Colors.redAccent;
      case 'Reservado': return Colors.orangeAccent;
      default:          return Colors.blueAccent;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Estoque':   return Icons.directions_car;
      case 'Vendido':   return Icons.sell;
      case 'Reservado': return Icons.lock_clock;
      default:          return Icons.car_repair;
    }
  }

  // CORREÇÃO: verificação de mounted após await
  Future<void> _excluir(String id, String nome) async {
    final ok = await confirmarAcao(
      context,
      titulo: 'Excluir Veículo?',
      mensagem: 'Deseja excluir "$nome"?',
      confirmLabel: 'EXCLUIR',
    );
    if (!ok || !mounted) return;
    await FirebaseFirestore.instance
        .collection(AppCollections.veiculos)
        .doc(id)
        .delete();
  }

  Future<void> _alterarStatus(String id, String novoStatus) async {
    await FirebaseFirestore.instance
        .collection(AppCollections.veiculos)
        .doc(id)
        .update({'status': novoStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Veículos'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: AppOptions.statusVeiculo
              .map((s) => Tab(text: s.toUpperCase()))
              .toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.info,
        tooltip: 'Novo veículo',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CadastroVeiculoPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: AppOptions.statusVeiculo
            .map((s) => _listaVeiculos(s))
            .toList(),
      ),
    );
  }

  Widget _listaVeiculos(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppCollections.veiculos)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const ErrorState();
        if (!snapshot.hasData) return kLoadingCenter;

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return EmptyState(
            icon: _statusIcon(status),
            message: 'Nenhum veículo em $status',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc         = docs[index];
            final d           = doc.data() as Map<String, dynamic>;
            final compra      = (d['valor_compra'] as num?)?.toDouble() ?? 0;
            final venda       = (d['valor_venda']  as num?)?.toDouble() ?? 0;
            final lucro       = venda - compra;
            final statusAtual = d['status'] as String? ?? 'Estoque';

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _statusColor(statusAtual).withOpacity(0.4),
                ),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  leading: Container(
                    width: 12,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _statusColor(statusAtual),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  title: Text(
                    '${d['marca']} ${d['modelo']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${d['ano']} • ${d['placa'] ?? 'Sem placa'}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  trailing:
                  Icon(_statusIcon(statusAtual),
                      color: _statusColor(statusAtual)),
                  children: [
                    const Divider(color: Colors.white12),
                    _infoLinha('Valor Compra',
                        'R\$ ${compra.toStringAsFixed(2)}', Colors.redAccent),
                    _infoLinha('Valor Venda',
                        'R\$ ${venda.toStringAsFixed(2)}', Colors.greenAccent),
                    _infoLinha('Lucro',
                        'R\$ ${lucro.toStringAsFixed(2)}',
                        lucro >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent),
                    _infoLinha('Status', statusAtual,
                        _statusColor(statusAtual)),

                    if ((d['observacoes'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Observações',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(d['observacoes'],
                                style: const TextStyle(
                                    color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],

                    // ── AÇÕES ─────────────────────────────────────
                    const SizedBox(height: 10),
                    Row(children: [
                      // Alterar status rápido
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.swap_horiz,
                            color: Colors.blueAccent),
                        tooltip: 'Alterar status',
                        color: AppColors.surface,
                        onSelected: (v) => _alterarStatus(doc.id, v),
                        itemBuilder: (_) => AppOptions.statusVeiculo
                            .where((s) => s != statusAtual)
                            .map((s) => PopupMenuItem(
                          value: s,
                          child: Text(s,
                              style: TextStyle(
                                  color: _statusColor(s))),
                        ))
                            .toList(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        tooltip: 'Excluir',
                        onPressed: () => _excluir(
                            doc.id,
                            '${d['marca']} ${d['modelo']}'),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoLinha(String titulo, String valor, Color cor) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(valor,
              style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }
}