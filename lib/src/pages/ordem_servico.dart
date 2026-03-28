import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cliente_search_delegate.dart';
import 'produto_search_delegate.dart';

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

  // LISTA DE PRODUTOS SELECIONADOS (Carrinho)
  List<Map<String, dynamic>> produtosSelecionados = [];
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

      // Carrega a lista de produtos se ela já existir na OS
      if (dados['produtos_detalhes'] != null) {
        produtosSelecionados = List<Map<String, dynamic>>.from(dados['produtos_detalhes']);
      }
    }
  }

  void _atualizarSomaPecas() {
    double total = produtosSelecionados.fold(0, (sum, item) => sum + (item['preco'] ?? 0.0));
    setState(() {
      pecasController.text = total.toStringAsFixed(2);
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

  void adicionarProduto() async {
    final DocumentSnapshot? prodt = await showSearch<DocumentSnapshot?>(
        context: context, delegate: ProdutoSearchDelegate());

    if (prodt != null) {
      setState(() {
        produtosSelecionados.add({
          'id': prodt.id,
          'nome': prodt['nome'],
          'preco': double.tryParse(prodt['preco'].toString()) ?? 0.0,
        });
        _atualizarSomaPecas();
      });
    }
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
        'produtos_detalhes': produtosSelecionados, // Salva a lista de peças
        'ultima_atualizacao': FieldValue.serverTimestamp(),
      };

      try {
        if (widget.osExistente != null) {
          await FirebaseFirestore.instance.collection('ordens').doc(widget.osExistente!.id).update(dadosParaSalvar);
        } else {
          dadosParaSalvar['data_abertura'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('ordens').add(dadosParaSalvar);
        }

        // LÓGICA DE BAIXA DE ESTOQUE MÚLTIPLA
        if (status == 'Finalizado' && produtosSelecionados.isNotEmpty) {
          for (var item in produtosSelecionados) {
            final docRef = FirebaseFirestore.instance.collection('produtos').doc(item['id']);
            await FirebaseFirestore.instance.runTransaction((tx) async {
              DocumentSnapshot snap = await tx.get(docRef);
              if (snap.exists) {
                int qtdAtual = snap['quantidade'] ?? 0;
                if (qtdAtual > 0) tx.update(docRef, {'quantidade': qtdAtual - 1});
              }
            });
          }
        }

        Navigator.pop(context);
      } catch (e) {
        print("Erro ao salvar: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.osExistente != null ? 'Editar OS' : 'Nova OS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sessaoTitulo("Cliente"),
              _buildSelector(nomeClienteExibicao, Icons.person, pesquisarCliente),

              const SizedBox(height: 20),
              _sessaoTitulo("Equipamento"),
              _buildField(equipamentoController, 'Aparelho / Modelo', Icons.smartphone),
              _buildField(defeitoController, 'Defeito / Relato', Icons.error_outline),

              const SizedBox(height: 20),
              _sessaoTitulo("Peças e Peças Selecionadas"),
              // LISTA DE PEÇAS NO ESTILO CHIP/CARD
              Wrap(
                spacing: 8,
                children: produtosSelecionados.map((p) => Chip(
                  label: Text(p['nome'], style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => setState(() {
                    produtosSelecionados.remove(p);
                    _atualizarSomaPecas();
                  }),
                )).toList(),
              ),
              const SizedBox(height: 10),
              _buildSelector("Adicionar Peça do Estoque", Icons.add_shopping_cart, adicionarProduto, color: Colors.orangeAccent),

              const SizedBox(height: 20),
              _sessaoTitulo("Financeiro"),
              _buildField(pecasController, 'Total em Peças', Icons.handyman, readOnly: true),
              _buildField(servicoController, 'Valor da Mão de Obra', Icons.payments, keyboard: TextInputType.number),

              DropdownButtonFormField<String>(
                value: formaPagamento,
                decoration: const InputDecoration(labelText: 'Pagamento', icon: Icon(Icons.credit_card)),
                items: ['Dinheiro', 'PIX', 'Cartão Débito', 'Cartão Crédito'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => formaPagamento = v!),
              ),

              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status', icon: Icon(Icons.sync)),
                items: ['Orçamento', 'Aguardando Aprovação', 'Aprovado', 'Finalizado'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => status = v!),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: salvarOS,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.green),
                child: const Text("SALVAR ORDEM DE SERVIÇO", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessaoTitulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
  );

  Widget _buildSelector(String texto, IconData icon, VoidCallback onTap, {Color color = Colors.white70}) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Expanded(child: Text(texto, style: TextStyle(color: color)))]),
    ),
  );

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool readOnly = false, TextInputType keyboard = TextInputType.text}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
    ),
  );
}