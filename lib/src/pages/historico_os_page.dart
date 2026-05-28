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

class _HistoricoOSPageState extends State<HistoricoOSPage> {
  String _busca = "";

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
        content: Text("Tem certeza que deseja apagar a OS de $cliente?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('ordens')
                  .doc(idDoc)
                  .delete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("OS excluída com sucesso!"),
                      backgroundColor: Colors.red),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LancamentoFinanceiroPage(dadosOS: os, osId: osDoc.id),
      ),
    );
  }

  void _abrirPDF(Map<String, dynamic> os) async {
    final clienteId = os['cliente_id'] as String?;
    if (clienteId == null) return;

    final clienteDoc = await FirebaseFirestore.instance
        .collection('clientes')
        .doc(clienteId)
        .get();

    if (!mounted) return;

    if (clienteDoc.exists) {
      final tel = clienteDoc.data()?['telefone'] ?? "";
      await PdfService.gerarEEnviarWhatsApp(os: os, telefoneCliente: tel);
    }
  }

  String _formatarData(dynamic ts) {
    if (ts == null) return '-';
    final data = (ts as Timestamp).toDate();
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de OS'),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (val) => setState(() => _busca = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Buscar por cliente ou equipamento...",
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
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ordens')
            .orderBy('ultima_atualizacao', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final listaFiltrada = snapshot.data!.docs.where((doc) {
            final dados = doc.data() as Map<String, dynamic>;
            final cliente     = (dados['cliente_nome'] ?? "").toLowerCase();
            final equipamento = (dados['equipamento']  ?? "").toLowerCase();
            return cliente.contains(_busca) || equipamento.contains(_busca);
          }).toList();

          if (listaFiltrada.isEmpty) {
            return const Center(
              child: Text('Nenhuma OS encontrada.',
                  style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.builder(
            itemCount: listaFiltrada.length,
            itemBuilder: (context, index) {
              final osDoc      = listaFiltrada[index];
              final os         = osDoc.data() as Map<String, dynamic>;
              final statusAtual  = os['status'] ?? 'Orçamento';
              final foiRecebido  = os['recebido'] == true;
              final isFinalizado = statusAtual == 'Finalizado';
              final total = ((os['valor_pecas']   as num?)?.toDouble() ?? 0) +
                  ((os['valor_servico'] as num?)?.toDouble() ?? 0);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile(
                  leading: Container(
                    width: 12,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(statusAtual),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  title: Row(children: [
                    Expanded(
                      child: Text(os['cliente_nome'] ?? 'Sem nome',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    // Badge de pagamento (só em Finalizado)
                    if (isFinalizado)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: foiRecebido
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: foiRecebido
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                        child: Text(
                          foiRecebido ? '✓ Recebido' : '⏳ A receber',
                          style: TextStyle(
                            color: foiRecebido
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ]),
                  subtitle:
                  Text("${os['equipamento'] ?? ''} • $statusAtual"),
                  trailing: Icon(_getStatusIcon(statusAtual),
                      color: _getStatusColor(statusAtual)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Defeito: ${os['defeito'] ?? '-'}"),
                          const Divider(height: 20),

                          // Peças
                          if ((os['pecas_detalhes'] as List?)?.isNotEmpty ==
                              true) ...[
                            const Text('Peças:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            ...(os['pecas_detalhes'] as List).map((p) {
                              final qtd   = (p['qtd']   as num?)?.toInt()    ?? 1;
                              final preco = (p['preco'] as num?)?.toDouble() ?? 0;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8, top: 2),
                                child: Text(
                                  '${qtd > 1 ? "${qtd}x " : ""}${p['nome']} — R\$ ${(preco * qtd).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70),
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                          ],

                          // Serviços
                          if ((os['servicos_detalhes'] as List?)?.isNotEmpty ==
                              true) ...[
                            const Text('Serviços:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            ...(os['servicos_detalhes'] as List).map((s) =>
                                Padding(
                                  padding:
                                  const EdgeInsets.only(left: 8, top: 2),
                                  child: Text(
                                    '${s['nome']} — R\$ ${(s['preco'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70),
                                  ),
                                )),
                            const SizedBox(height: 6),
                          ],

                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Botões de ação
                              Row(children: [
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf,
                                      color: Colors.red),
                                  tooltip: 'Enviar PDF',
                                  onPressed: () => _abrirPDF(os),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  tooltip: 'Editar OS',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrdemServicoPage(
                                          osExistente: osDoc),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.grey),
                                  tooltip: 'Excluir OS',
                                  onPressed: () => _confirmarExclusao(
                                      osDoc.id, os['cliente_nome'] ?? ''),
                                ),
                                // Confirmar recebimento (só OS finalizada e não recebida)
                                if (isFinalizado && !foiRecebido)
                                  IconButton(
                                    icon: const Icon(Icons.attach_money,
                                        color: Colors.greenAccent),
                                    tooltip: 'Confirmar recebimento',
                                    onPressed: () =>
                                        _confirmarRecebimento(osDoc),
                                  ),
                              ]),
                              // Total
                              Text(
                                "Total: R\$ ${total.toStringAsFixed(2)}",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[400]),
                              ),
                            ],
                          ),

                          // Data de recebimento
                          if (foiRecebido && os['data_recebimento'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Recebido em: ${_formatarData(os['data_recebimento'])}',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}