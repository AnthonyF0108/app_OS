import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cliente_search_delegate.dart';

class OrdemServicoPage extends StatefulWidget {
  final QueryDocumentSnapshot? osExistente;
  const OrdemServicoPage({super.key, this.osExistente});

  @override
  State<OrdemServicoPage> createState() => _OrdemServicoPageState();
}

class _OrdemServicoPageState extends State<OrdemServicoPage> {
  final _formKey = GlobalKey<FormState>();

  // Dados do Cliente
  String nomeClienteExibicao = "Nenhum cliente selecionado";
  String? idClienteFirebase;

  // LISTA DE PEÇAS E SERVIÇOS (Digitados diretamente na hora)
  List<Map<String, dynamic>> pecasSelecionadas = [];
  List<Map<String, dynamic>> servicosSelecionados = [];

  String formaPagamento = 'Dinheiro';
  String status = 'Orçamento';

  // Controllers
  final equipamentoController = TextEditingController();
  final defeitoController = TextEditingController();
  final pecasController = TextEditingController(text: '0.00');
  final servicoController = TextEditingController(text: '0.00');

  @override
  void initState() {
    super.initState();
    if (widget.osExistente != null) {
      final dados = widget.osExistente!.data() as Map<String, dynamic>;
      nomeClienteExibicao = dados['cliente_nome'] ?? 'Sem Nome';
      idClienteFirebase = dados['cliente_id'];
      equipamentoController.text = dados['equipamento'] ?? '';
      defeitoController.text = dados['defeito'] ?? '';
      pecasController.text = (dados['valor_pecas'] ?? 0.0).toStringAsFixed(2);
      servicoController.text = (dados['valor_servico'] ?? 0.0).toStringAsFixed(2);
      status = dados['status'] ?? 'Orçamento';
      formaPagamento = dados['forma_pagamento'] ?? 'Dinheiro';

      if (dados['pecas_detalhes'] != null) {
        pecasSelecionadas = List<Map<String, dynamic>>.from(dados['pecas_detalhes']);
      }
      if (dados['servicos_detalhes'] != null) {
        servicosSelecionados = List<Map<String, dynamic>>.from(dados['servicos_detalhes']);
      }
      if (dados['produtos_detalhes'] != null && pecasSelecionadas.isEmpty) {
        pecasSelecionadas = List<Map<String, dynamic>>.from(dados['produtos_detalhes']);
      }
    }
  }

  void _recalcularTotais() {
    double totalPecas = pecasSelecionadas.fold(0, (sum, item) {
      double preco = (item['preco'] as num?)?.toDouble() ?? 0.0;
      int qtd = (item['qtd'] as num?)?.toInt() ?? 1;
      return sum + (preco * qtd);
    });

    double totalServicos = servicosSelecionados.fold(0, (sum, item) {
      double preco = (item['preco'] as num?)?.toDouble() ?? 0.0;
      return sum + preco; // Se quiser adicionar Qtd para serviços no futuro, a lógica seria aqui
    });

    setState(() {
      pecasController.text = totalPecas.toStringAsFixed(2);
      servicoController.text = totalServicos.toStringAsFixed(2);
    });
  }

  void pesquisarCliente() async {
    if (widget.osExistente != null) return;
    final DocumentSnapshot? resultado = await showSearch<DocumentSnapshot?>(
        context: context, delegate: ClienteSearchDelegate());
    if (resultado != null) {
      setState(() {
        idClienteFirebase = resultado.id;
        nomeClienteExibicao = resultado['nome'] ?? 'Sem Nome';
      });
    }
  }

// ADICIONAR PEÇA MANUALMENTE (Corrigido o overflow com SingleChildScrollView)
  void _adicionarPecaManual() {
    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    final qtdCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adicionar Peça"),
        content: SingleChildScrollView( // <--- Adicionado aqui
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: "Nome da peça", prefixIcon: Icon(Icons.build)),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: precoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Preço unitário (R\$)", prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qtdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantidade", prefixIcon: Icon(Icons.numbers)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (nomeCtrl.text.isEmpty) return;
              setState(() {
                pecasSelecionadas.add({
                  'nome': nomeCtrl.text.trim(),
                  'preco': double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                  'qtd': int.tryParse(qtdCtrl.text) ?? 1,
                });
                _recalcularTotais();
              });
              Navigator.pop(context);
            },
            child: const Text("ADICIONAR"),
          ),
        ],
      ),
    );
  }

// ADICIONAR SERVIÇO MANUALMENTE (Corrigido o overflow com SingleChildScrollView)
  void _adicionarServicoManual() {
    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adicionar Serviço"),
        content: SingleChildScrollView( // <--- Adicionado aqui
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: "Nome do serviço", prefixIcon: Icon(Icons.miscellaneous_services)),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: precoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Preço do serviço (R\$)", prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Descrição / Obs (Opcional)", prefixIcon: Icon(Icons.description)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (nomeCtrl.text.isEmpty) return;
              setState(() {
                servicosSelecionados.add({
                  'nome': nomeCtrl.text.trim(),
                  'preco': double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                  'descricao': descCtrl.text.trim(),
                });
                _recalcularTotais();
              });
              Navigator.pop(context);
            },
            child: const Text("ADICIONAR"),
          ),
        ],
      ),
    );
  }

  void salvarOS() async {
    if (idClienteFirebase == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um cliente!')));
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
        'forma_pagamento': formaPagamento,
        'pecas_detalhes': pecasSelecionadas,
        'servicos_detalhes': servicosSelecionados,
        'produtos_detalhes': [
          ...pecasSelecionadas.map((p) => {
            'nome': '${p['qtd'] != null && p['qtd'] > 1 ? "${p['qtd']}x " : ""}${p['nome']}',
            'preco': ((p['preco'] as num?)?.toDouble() ?? 0.0) * ((p['qtd'] as num?)?.toInt() ?? 1),
          }),
          ...servicosSelecionados.map((s) => {
            'nome': '[Serviço] ${s['nome']}',
            'preco': s['preco'],
          }),
        ],
        'ultima_atualizacao': FieldValue.serverTimestamp(),
      };

      try {
        if (widget.osExistente != null) {
          await FirebaseFirestore.instance
              .collection('ordens')
              .doc(widget.osExistente!.id)
              .update(dadosParaSalvar);
        } else {
          dadosParaSalvar['data_abertura'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('ordens').add(dadosParaSalvar);
        }

        Navigator.pop(context);
      } catch (e) {
        debugPrint("Erro ao salvar: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalGeral = (double.tryParse(pecasController.text) ?? 0) +
        (double.tryParse(servicoController.text) ?? 0);

    return Scaffold(
      appBar: AppBar(title: Text(widget.osExistente != null ? 'Editar OS' : 'Nova OS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── CLIENTE ──────────────────────────────────────────
              _sessaoTitulo("Cliente"),
              _buildSelector(nomeClienteExibicao, Icons.person, pesquisarCliente),

              const SizedBox(height: 20),

              // ── EQUIPAMENTO ──────────────────────────────────────
              _sessaoTitulo("Equipamento"),
              _buildField(equipamentoController, 'Aparelho / Modelo', Icons.smartphone),
              _buildField(defeitoController, 'Defeito / Relato', Icons.error_outline),

              const SizedBox(height: 20),

              // ── PEÇAS ─────────────────────────────────────────────
              _sessaoTitulo("Peças Utilizadas"),
              if (pecasSelecionadas.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text("Nenhuma peça adicionada.", style: TextStyle(color: Colors.white54, fontSize: 13)),
                )
              else
                ...pecasSelecionadas.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  double subtotal = ((p['preco'] as num?)?.toDouble() ?? 0) *
                      ((p['qtd'] as num?)?.toInt() ?? 1);
                  return Card(
                    color: Colors.white.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: const Icon(Icons.build_circle, color: Colors.orangeAccent),
                      title: Text(
                        p['qtd'] != null && p['qtd'] > 1
                            ? "${p['qtd']}x ${p['nome']}"
                            : p['nome'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "R\$ ${subtotal.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() {
                          pecasSelecionadas.removeAt(i);
                          _recalcularTotais();
                        }),
                      ),
                    ),
                  );
                }),
              _buildSelector("+ Adicionar Peça", Icons.add_box, _adicionarPecaManual,
                  color: Colors.orangeAccent),

              const SizedBox(height: 20),

              // ── SERVIÇOS ──────────────────────────────────────────
              _sessaoTitulo("Serviços"),
              if (servicosSelecionados.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text("Nenhum serviço adicionado.", style: TextStyle(color: Colors.white54, fontSize: 13)),
                )
              else
                ...servicosSelecionados.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Card(
                    color: Colors.white.withOpacity(0.05),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: const Icon(Icons.miscellaneous_services, color: Colors.blueAccent),
                      title: Text(s['nome'], style: const TextStyle(color: Colors.white)),
                      subtitle: s['descricao'] != null && s['descricao'].toString().isNotEmpty
                          ? Text(s['descricao'], style: const TextStyle(color: Colors.white54, fontSize: 12))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "R\$ ${(s['preco'] as num).toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.greenAccent),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => setState(() {
                              servicosSelecionados.removeAt(i);
                              _recalcularTotais();
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              // MODIFICADO: Agora chama a função de inserção direta e manual
              _buildSelector("+ Adicionar Serviço", Icons.miscellaneous_services, _adicionarServicoManual,
                  color: Colors.blueAccent),

              const SizedBox(height: 20),

              // ── FINANCEIRO ────────────────────────────────────────
              _sessaoTitulo("Resumo Financeiro"),
              _buildReadOnlyRow("Total Peças", pecasController.text, Colors.orangeAccent),
              _buildReadOnlyRow("Total Serviços", servicoController.text, Colors.blueAccent),
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL GERAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      "R\$ ${totalGeral.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ],
                ),
              ),

              DropdownButtonFormField<String>(
                value: formaPagamento,
                decoration: const InputDecoration(labelText: 'Pagamento', icon: Icon(Icons.credit_card)),
                items: ['Dinheiro', 'PIX', 'Cartão Débito', 'Cartão Crédito']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => formaPagamento = v!),
              ),

              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status', icon: Icon(Icons.sync)),
                items: ['Orçamento', 'Aguardando Aprovação', 'Aprovado', 'Finalizado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => status = v!),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: salvarOS,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.green),
                child: const Text("SALVAR ORDEM DE SERVIÇO",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text("R\$ $valor", style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _sessaoTitulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(texto,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
  );

  Widget _buildSelector(String texto, IconData icon, VoidCallback onTap,
      {Color color = Colors.white70}) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(texto, style: TextStyle(color: color)))
          ]),
        ),
      );

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {bool readOnly = false,
        TextInputType keyboard = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          readOnly: readOnly,
          keyboardType: keyboard,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: const OutlineInputBorder()),
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
        ),
      );
}