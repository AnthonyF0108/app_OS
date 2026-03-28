import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/pdf_service.dart';
import 'ordem_servico.dart';

class HistoricoOSPage extends StatefulWidget {
  const HistoricoOSPage({super.key});

  @override
  State<HistoricoOSPage> createState() => _HistoricoOSPageState();
}

class _HistoricoOSPageState extends State<HistoricoOSPage> {
  String _busca = "";

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Em Aberto': return Colors.blue;
      case 'Em Orçamento': return Colors.orange;
      case 'Aprovado': return Colors.green;
      case 'Finalizado': return Colors.grey;
      default: return Colors.blueAccent;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Em Aberto': return Icons.hourglass_empty;
      case 'Em Orçamento': return Icons.request_quote;
      case 'Aprovado': return Icons.play_circle_outline;
      case 'Finalizado': return Icons.verified;
      default: return Icons.info_outline;
    }
  }

  // FUNÇÃO PARA EXCLUIR COM CONFIRMAÇÃO
  void _confirmarExclusao(BuildContext context, String idDoc, String cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Ordem de Serviço?"),
        content: Text("Tem certeza que deseja apagar a OS de $cliente? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('ordens').doc(idDoc).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("OS excluída com sucesso!"), backgroundColor: Colors.red),
              );
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
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
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar.'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final listaFiltrada = snapshot.data!.docs.where((doc) {
            var dados = doc.data() as Map<String, dynamic>;
            String cliente = (dados['cliente_nome'] ?? "").toLowerCase();
            String equipamento = (dados['equipamento'] ?? "").toLowerCase();
            return cliente.contains(_busca) || equipamento.contains(_busca);
          }).toList();

          return ListView.builder(
            itemCount: listaFiltrada.length,
            itemBuilder: (context, index) {
              var osDoc = listaFiltrada[index];
              var os = osDoc.data() as Map<String, dynamic>;
              String statusAtual = os['status'] ?? 'Em Aberto';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile(
                  leading: Container(
                    width: 12, height: 40,
                    decoration: BoxDecoration(color: _getStatusColor(statusAtual), borderRadius: BorderRadius.circular(10)),
                  ),
                  title: Text(os['cliente_nome'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${os['equipamento']} • $statusAtual"),
                  trailing: Icon(_getStatusIcon(statusAtual), color: _getStatusColor(statusAtual)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Defeito: ${os['defeito']}"),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                    onPressed: () async {
                                      String? clienteId = os['cliente_id'];
                                      if (clienteId == null) return;
                                      var clienteDoc = await FirebaseFirestore.instance.collection('clientes').doc(clienteId).get();
                                      if (clienteDoc.exists) {
                                        String tel = clienteDoc.data()?['telefone'] ?? "";
                                        await PdfService.gerarEEnviarWhatsApp(os: os, telefoneCliente: tel);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrdemServicoPage(osExistente: osDoc))),
                                  ),
                                  // BOTÃO DE EXCLUIR
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                    onPressed: () => _confirmarExclusao(context, osDoc.id, os['cliente_nome']),
                                  ),
                                ],
                              ),
                              Text(
                                "Total: R\$ ${( (os['valor_pecas'] ?? 0) + (os['valor_servico'] ?? 0) ).toStringAsFixed(2)}",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800]),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
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