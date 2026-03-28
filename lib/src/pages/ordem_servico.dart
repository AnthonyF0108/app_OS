import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cliente_search_delegate.dart';

class OrdemServicoPage extends StatefulWidget {
  // Parâmetro opcional: se receber um documento, entra em modo de EDIÇÃO
  final QueryDocumentSnapshot? osExistente;

  const OrdemServicoPage({super.key, this.osExistente});

  @override
  State<OrdemServicoPage> createState() => _OrdemServicoPageState();
}

class _OrdemServicoPageState extends State<OrdemServicoPage> {
  final _formKey = GlobalKey<FormState>();

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Em Aberto': return Colors.blue;
      case 'Em Orçamento': return Colors.orange;
      case 'Aprovado': return Colors.green;
      case 'Finalizado': return Colors.grey;
      default: return Colors.white;
    }
  }

  // Dados do Cliente
  String nomeClienteExibicao = "Nenhum cliente selecionado";
  String? idClienteFirebase;

  // Controllers
  final equipamentoController = TextEditingController();
  final defeitoController = TextEditingController();
  final pecasController = TextEditingController();
  final servicoController = TextEditingController();
  String status = 'Em Aberto';

  @override
  void initState() {
    super.initState();
    // Se o widget recebeu uma OS existente, preenchemos os campos automaticamente
    if (widget.osExistente != null) {
      final dados = widget.osExistente!.data() as Map<String, dynamic>;
      nomeClienteExibicao = dados['cliente_nome'] ?? 'Sem Nome';
      idClienteFirebase = dados['cliente_id'];
      equipamentoController.text = dados['equipamento'] ?? '';
      defeitoController.text = dados['defeito'] ?? '';
      pecasController.text = (dados['valor_pecas'] ?? 0.0).toString();
      servicoController.text = (dados['valor_servico'] ?? 0.0).toString();
      status = dados['status'] ?? 'Em Aberto';
    }
  }

  void pesquisarCliente() async {
    // Bloqueia a troca de cliente se estiver editando (opcional, para evitar erros de vínculo)
    if (widget.osExistente != null) return;

    final DocumentSnapshot? resultado = await showSearch<DocumentSnapshot?>(
      context: context,
      delegate: ClienteSearchDelegate(),
    );

    if (resultado != null) {
      setState(() {
        idClienteFirebase = resultado.id;
        final dadosCliente = resultado.data() as Map<String, dynamic>?;
        if (dadosCliente != null) {
          nomeClienteExibicao = dadosCliente['nome'] ?? 'Sem Nome';
        }
      });
    }
  }

  void salvarOS() async {
    if (idClienteFirebase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um cliente.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final dadosParaSalvar = {
        'cliente_id': idClienteFirebase,
        'cliente_nome': nomeClienteExibicao,
        'equipamento': equipamentoController.text,
        'defeito': defeitoController.text,
        'valor_pecas': double.tryParse(pecasController.text) ?? 0.0,
        'valor_servico': double.tryParse(servicoController.text) ?? 0.0,
        'status': status,
        'ultima_atualizacao': FieldValue.serverTimestamp(),
      };

      try {
        if (widget.osExistente != null) {
          // ATUALIZAR OS EXISTENTE
          await FirebaseFirestore.instance
              .collection('ordens')
              .doc(widget.osExistente!.id)
              .update(dadosParaSalvar);
        } else {
          // CRIAR NOVA OS
          dadosParaSalvar['data_abertura'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('ordens').add(dadosParaSalvar);
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.osExistente != null ? 'OS Atualizada!' : 'OS Salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool modoEdicao = widget.osExistente != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(modoEdicao ? 'Editar Ordem de Serviço' : 'Nova Ordem de Serviço'),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Dados do Cliente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Painel de exibição do Cliente
              InkWell(
                onTap: pesquisarCliente,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: modoEdicao ? Colors.grey : Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: modoEdicao ? Colors.grey : Colors.blueAccent),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          nomeClienteExibicao,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: idClienteFirebase != null ? FontWeight.bold : FontWeight.normal,
                            color: idClienteFirebase != null ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                      if (!modoEdicao) const Icon(Icons.search, color: Colors.blueAccent),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
              const Text("Informações Técnicas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildField(equipamentoController, 'Equipamento', Icons.build_circle),
              _buildField(defeitoController, 'Defeito Relatado', Icons.warning_amber),

              const SizedBox(height: 20),
              const Text("Valores e Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildField(pecasController, 'Valor Peças (0.00)', Icons.handyman, keyboard: TextInputType.number),
              _buildField(servicoController, 'Valor Serviço (0.00)', Icons.payments, keyboard: TextInputType.number),

              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                    labelText: 'Status da OS',
                    icon: Icon(Icons.info_outline)
                ),
                // Lista atualizada com as 4 opções
                items: ['Em Aberto', 'Em Orçamento', 'Aprovado', 'Finalizado']
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: TextStyle(color: _getStatusColor(s))),
                ))
                    .toList(),
                onChanged: (novo) => setState(() => status = novo!),
              ),

              const SizedBox(height: 35),
              ElevatedButton(
                onPressed: salvarOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: modoEdicao ? Colors.orange[800] : Colors.greenAccent[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  modoEdicao ? 'ATUALIZAR ORDEM DE SERVIÇO' : 'SALVAR ORDEM DE SERVIÇO',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          icon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboard,
        validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
      ),
    );
  }
}