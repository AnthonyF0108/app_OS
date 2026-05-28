import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ordem_servico.dart';
import '../services/pdf_service.dart';
import 'lancamento_financeiro_page.dart';

class HistoricoOSPage extends StatefulWidget {
  const HistoricoOSPage({super.key});

  @override
  State<HistoricoOSPage> createState() => _HistoricoOSPageState();
}

class _HistoricoOSPageState extends State<HistoricoOSPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _busca = "";

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

  static const _statusAberto = ['Orçamento', 'Aguardando Aprovação', 'Aprovado'];

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Orçamento':            return Colors.blue;
      case 'Aguardando Aprovação': return Colors.orange;
      case 'Aprovado':             return Colors.green;
      case 'Finalizado':           return Colors.grey;
      default:                     return Colors.blueAccent;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Orçamento':            return Icons.hourglass_empty;
      case 'Aguardando Aprovação': return Icons.request_quote;
      case 'Aprovado':             return Icons.play_circle_outline;
      case 'Finalizado':           return Icons.verified;
      default:                     return Icons.info_outline;
    }
  }

  void _confirmarExclusao(String idDoc, String cliente) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Ordem de Serviço?"),
        content: Text("Deseja apagar a OS de $cliente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('ordens').doc(idDoc).delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("OS excluída!"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmarRecebimento(QueryDocumentSnapshot osDoc) {
    final os = osDoc.data() as Map<String, dynamic>;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LancamentoFinanceiroPage(dadosOS: os, osId: osDoc.id),
    ));
  }

  void _abrirPDF(Map<String, dynamic> os) async {
    final clienteId = os['cliente_id'] as String?;
    if (clienteId == null) return;
    final clienteDoc = await FirebaseFirestore.instance
        .collection('clientes').doc(clienteId).get();
    if (!mounted) return;
    if (clienteDoc.exists) {
      final tel = clienteDoc.data()?['telefone'] ?? "";
      await PdfService.gerarEEnviarWhatsApp(os: os, telefoneCliente: tel);
    }
  }

  String _formatarData(dynamic ts) {
    if (ts == null) return '-';
    final d = (ts as Timestamp).toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de OS'),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: TextField(
                  onChanged: (val) => setState(() => _busca = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Buscar por cliente, OS ou equipamento...",
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    hintStyle: const TextStyle(color: Colors.white60),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.blueAccent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: "EM ABERTO"),
                  Tab(text: "FINALIZADAS"),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_money, size: 14, color: Colors.orangeAccent),
                        SizedBox(width: 2),
                        Text("A RECEBER", style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ordens')
            .orderBy('ultima_atualizacao', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar.'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todas = snapshot.data!.docs.where((doc) {
            final d           = doc.data() as Map<String, dynamic>;
            final cliente     = (d['cliente_nome'] ?? "").toLowerCase();
            final equipamento = (d['equipamento']  ?? "").toLowerCase();
            final numero      = (d['numero_os']    ?? "").toLowerCase();
            return cliente.contains(_busca) ||
                equipamento.contains(_busca) ||
                numero.contains(_busca);
          }).toList();

          final emAberto = todas.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _statusAberto.contains(d['status'] ?? 'Orçamento');
          }).toList();

          final finalizadas = todas.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return (d['status'] ?? '') == 'Finalizado';
          }).toList();

          final aReceber = finalizadas.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return d['recebido'] != true;
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _listaOS(emAberto),
              _listaOS(finalizadas),
              _listaOS(aReceber, destaqueAReceber: true),
            ],
          );
        },
      ),
    );
  }

  Widget _listaOS(List<QueryDocumentSnapshot> lista, {bool destaqueAReceber = false}) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              destaqueAReceber ? Icons.check_circle_outline : Icons.inbox,
              size: 56, color: Colors.white24,
            ),
            const SizedBox(height: 12),
            Text(
              destaqueAReceber ? 'Tudo recebido! 🎉' : 'Nenhuma OS encontrada.',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    double totalAReceber = 0;
    if (destaqueAReceber) {
      for (final doc in lista) {
        final d = doc.data() as Map<String, dynamic>;
        totalAReceber += ((d['valor_pecas']   as num?)?.toDouble() ?? 0) +
            ((d['valor_servico'] as num?)?.toDouble() ?? 0);
      }
    }

    return Column(
      children: [
        if (destaqueAReceber)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.orange.withValues(alpha: 0.12),
            child: Row(children: [
              const Icon(Icons.attach_money, color: Colors.orangeAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                '${lista.length} OS • Total: R\$ ${totalAReceber.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ]),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: lista.length,
            padding: const EdgeInsets.only(top: 4),
            itemBuilder: (context, index) {
              final osDoc        = lista[index];
              final os           = osDoc.data() as Map<String, dynamic>;
              final statusAtual  = os['status']   ?? 'Orçamento';
              final foiRecebido  = os['recebido'] == true;
              final isFinalizado = statusAtual    == 'Finalizado';
              final total        = ((os['valor_pecas']   as num?)?.toDouble() ?? 0) +
                  ((os['valor_servico'] as num?)?.toDouble() ?? 0);
              final numeroOS     = os['numero_os'] as String?;
              final cliente      = os['cliente_nome'] ?? 'Sem nome';
              final equipamento  = os['equipamento']  ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                shape: destaqueAReceber
                    ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.orangeAccent, width: 1),
                )
                    : null,
                child: ExpansionTile(
                  // Barra colorida no lado esquerdo
                  leading: Container(
                    width: 12, height: 40,
                    decoration: BoxDecoration(
                      color: destaqueAReceber
                          ? Colors.orangeAccent
                          : _getStatusColor(statusAtual),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Título em coluna para não brigar com o nome
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha 1: número + badge (pequenos, acima do nome)
                      Row(
                        children: [
                          if (numeroOS != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 6, bottom: 3),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.blueAccent.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                numeroOS,
                                style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (isFinalizado && !destaqueAReceber)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: foiRecebido
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: foiRecebido
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent),
                              ),
                              child: Text(
                                foiRecebido ? '✓ Recebido' : '⏳ A receber',
                                style: TextStyle(
                                    color: foiRecebido
                                        ? Colors.greenAccent
                                        : Colors.orangeAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      // Linha 2: nome do cliente — linha inteira livre
                      Text(
                        cliente,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Subtítulo: equipamento + status
                  subtitle: Text(
                    '$equipamento • $statusAtual',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    destaqueAReceber
                        ? Icons.attach_money
                        : _getStatusIcon(statusAtual),
                    color: destaqueAReceber
                        ? Colors.orangeAccent
                        : _getStatusColor(statusAtual),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Defeito: ${os['defeito'] ?? '-'}"),
                          const Divider(height: 20),

                          if ((os['pecas_detalhes'] as List?)?.isNotEmpty == true) ...[
                            const Text('Peças:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ...(os['pecas_detalhes'] as List).map((p) {
                              final qtd   = (p['qtd']   as num?)?.toInt()    ?? 1;
                              final preco = (p['preco'] as num?)?.toDouble() ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2),
                                child: Text(
                                  '${qtd > 1 ? "${qtd}x " : ""}${p['nome']} — R\$ ${(preco * qtd).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                          ],

                          if ((os['servicos_detalhes'] as List?)?.isNotEmpty == true) ...[
                            const Text('Serviços:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ...(os['servicos_detalhes'] as List).map((s) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 2),
                              child: Text(
                                '${s['nome']} — R\$ ${(s['preco'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                              ),
                            )),
                            const SizedBox(height: 6),
                          ],

                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                  tooltip: 'Enviar PDF',
                                  onPressed: () => _abrirPDF(os),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Editar OS',
                                  onPressed: () => Navigator.push(context,
                                      MaterialPageRoute(
                                        builder: (_) => OrdemServicoPage(osExistente: osDoc),
                                      )),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  tooltip: 'Excluir OS',
                                  onPressed: () => _confirmarExclusao(
                                      osDoc.id, os['cliente_nome'] ?? ''),
                                ),
                                if (isFinalizado && !foiRecebido)
                                  IconButton(
                                    icon: const Icon(Icons.attach_money,
                                        color: Colors.greenAccent),
                                    tooltip: 'Confirmar recebimento',
                                    onPressed: () => _confirmarRecebimento(osDoc),
                                  ),
                              ]),
                              Text(
                                "R\$ ${total.toStringAsFixed(2)}",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: destaqueAReceber
                                        ? Colors.orangeAccent
                                        : Colors.green[400]),
                              ),
                            ],
                          ),

                          if (foiRecebido && os['data_recebimento'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Recebido em: ${_formatarData(os['data_recebimento'])}',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}