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

  String nomeClienteExibicao = "Nenhum cliente selecionado";
  String? idClienteFirebase;

  List<Map<String, dynamic>> pecasSelecionadas    = [];
  List<Map<String, dynamic>> servicosSelecionados = [];

  String formaPagamento = 'Dinheiro';
  String status         = 'Orçamento';
  String? numeroOS;

  final equipamentoController = TextEditingController();
  final defeitoController     = TextEditingController();

  double get totalPecas => pecasSelecionadas.fold(0, (sum, p) =>
  sum + ((p['preco'] as num?)?.toDouble() ?? 0) *
      ((p['qtd']   as num?)?.toInt()    ?? 1));

  double get totalServicos => servicosSelecionados.fold(0, (sum, s) =>
  sum + ((s['preco'] as num?)?.toDouble() ?? 0));

  double get totalGeral => totalPecas + totalServicos;

  @override
  void initState() {
    super.initState();
    if (widget.osExistente != null) {
      final d = widget.osExistente!.data() as Map<String, dynamic>;
      nomeClienteExibicao        = d['cliente_nome']    ?? 'Sem Nome';
      idClienteFirebase          = d['cliente_id'];
      equipamentoController.text = d['equipamento']     ?? '';
      defeitoController.text     = d['defeito']         ?? '';
      status                     = d['status']          ?? 'Orçamento';
      formaPagamento             = d['forma_pagamento'] ?? 'Dinheiro';
      numeroOS                   = d['numero_os'];

      if (d['pecas_detalhes'] != null) {
        pecasSelecionadas = List<Map<String, dynamic>>.from(d['pecas_detalhes']);
      }
      if (d['servicos_detalhes'] != null) {
        servicosSelecionados = List<Map<String, dynamic>>.from(d['servicos_detalhes']);
      }
      if (d['produtos_detalhes'] != null && pecasSelecionadas.isEmpty) {
        pecasSelecionadas = List<Map<String, dynamic>>.from(d['produtos_detalhes']);
      }
    }
  }

  // ── GERAR NÚMERO DA OS ─────────────────────────────────────────────────────
  Future<String> _gerarNumeroOS() async {
    final ano = DateTime.now().year.toString();
    final snap = await FirebaseFirestore.instance
        .collection('ordens')
        .where('ano_os', isEqualTo: ano)
        .get();

    int maior = 0;
    for (final doc in snap.docs) {
      final seq = doc.data()['sequencial_os'] as int? ?? 0;
      if (seq > maior) maior = seq;
    }
    final sequencial = (maior + 1).toString().padLeft(3, '0');
    return 'OS-$ano-$sequencial';
  }

  // ── PESQUISAR CLIENTE ──────────────────────────────────────────────────────
  void _pesquisarCliente() async {
    if (widget.osExistente != null) return;
    final resultado = await showSearch<DocumentSnapshot?>(
        context: context, delegate: ClienteSearchDelegate());
    if (resultado != null) {
      setState(() {
        idClienteFirebase   = resultado.id;
        nomeClienteExibicao = resultado['nome'] ?? 'Sem Nome';
      });
    }
  }

  // ── ADICIONAR PEÇA ─────────────────────────────────────────────────────────
  void _adicionarPeca() {
    final nomeCtrl  = TextEditingController();
    final precoCtrl = TextEditingController();
    final qtdCtrl   = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Adicionar Peça"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nomeCtrl, autofocus: true,
                decoration: const InputDecoration(labelText: "Nome da peça", prefixIcon: Icon(Icons.build))),
            const SizedBox(height: 8),
            TextField(controller: precoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Preço unitário (R\$)", prefixIcon: Icon(Icons.attach_money))),
            const SizedBox(height: 8),
            TextField(controller: qtdCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantidade", prefixIcon: Icon(Icons.numbers))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (nomeCtrl.text.trim().isEmpty) return;
              setState(() => pecasSelecionadas.add({
                'nome':  nomeCtrl.text.trim(),
                'preco': double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                'qtd':   int.tryParse(qtdCtrl.text) ?? 1,
              }));
              Navigator.pop(context);
            },
            child: const Text("ADICIONAR"),
          ),
        ],
      ),
    );
  }

  // ── ADICIONAR SERVIÇO ──────────────────────────────────────────────────────
  void _adicionarServico() {
    final nomeCtrl  = TextEditingController();
    final precoCtrl = TextEditingController();
    final descCtrl  = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Adicionar Serviço"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nomeCtrl, autofocus: true,
                decoration: const InputDecoration(labelText: "Nome do serviço", prefixIcon: Icon(Icons.miscellaneous_services))),
            const SizedBox(height: 8),
            TextField(controller: precoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Preço (R\$)", prefixIcon: Icon(Icons.attach_money))),
            const SizedBox(height: 8),
            TextField(controller: descCtrl,
                decoration: const InputDecoration(labelText: "Obs (opcional)", prefixIcon: Icon(Icons.description))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (nomeCtrl.text.trim().isEmpty) return;
              setState(() => servicosSelecionados.add({
                'nome':      nomeCtrl.text.trim(),
                'preco':     double.tryParse(precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                'descricao': descCtrl.text.trim(),
              }));
              Navigator.pop(context);
            },
            child: const Text("ADICIONAR"),
          ),
        ],
      ),
    );
  }

  // ── SALVAR OS ──────────────────────────────────────────────────────────────
  void _salvarOS() async {
    if (idClienteFirebase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um cliente!')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    String numOS       = numeroOS ?? '';
    int    sequencial  = 0;
    String ano         = DateTime.now().year.toString();

    if (widget.osExistente == null) {
      numOS      = await _gerarNumeroOS();
      sequencial = int.tryParse(numOS.split('-').last) ?? 0;
    } else {
      final d   = widget.osExistente!.data() as Map<String, dynamic>;
      sequencial = d['sequencial_os'] ?? 0;
      ano        = d['ano_os']        ?? ano;
    }

    final dadosParaSalvar = {
      'numero_os':     numOS,
      'sequencial_os': sequencial,
      'ano_os':        ano,
      'cliente_id':    idClienteFirebase,
      'cliente_nome':  nomeClienteExibicao,
      'equipamento':   equipamentoController.text,
      'defeito':       defeitoController.text,
      'valor_pecas':   totalPecas,
      'valor_servico': totalServicos,
      'status':          status,
      'forma_pagamento': formaPagamento,
      'pecas_detalhes':    pecasSelecionadas,
      'servicos_detalhes': servicosSelecionados,
      'produtos_detalhes': [
        ...pecasSelecionadas.map((p) => {
          'nome':  '${(p['qtd'] ?? 1) > 1 ? "${p['qtd']}x " : ""}${p['nome']}',
          'preco': ((p['preco'] as num?)?.toDouble() ?? 0) *
              ((p['qtd']   as num?)?.toInt()    ?? 1),
        }),
        ...servicosSelecionados.map((s) => {
          'nome':  '[Serviço] ${s['nome']}',
          'preco': (s['preco'] as num?)?.toDouble() ?? 0,
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.osExistente != null ? 'Editar OS' : 'Nova OS'),
            if (numeroOS != null)
              Text(numeroOS!,
                  style: const TextStyle(fontSize: 12, color: Colors.white60)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _titulo("Cliente"),
              _seletor(nomeClienteExibicao, Icons.person, _pesquisarCliente),
              const SizedBox(height: 20),

              _titulo("Equipamento"),
              _campo(equipamentoController, 'Aparelho / Modelo', Icons.smartphone),
              _campo(defeitoController,     'Defeito / Relato',  Icons.error_outline),
              const SizedBox(height: 20),

              _titulo("Peças Utilizadas"),
              ...pecasSelecionadas.asMap().entries.map((e) {
                final i   = e.key;
                final p   = e.value;
                final sub = ((p['preco'] as num?)?.toDouble() ?? 0) *
                    ((p['qtd']   as num?)?.toInt()    ?? 1);
                return _itemCard(
                  icone: Icons.build_circle, cor: Colors.orangeAccent,
                  titulo: (p['qtd'] ?? 1) > 1 ? "${p['qtd']}x ${p['nome']}" : p['nome'],
                  valor: sub,
                  onDelete: () => setState(() => pecasSelecionadas.removeAt(i)),
                );
              }),
              _seletor("+ Adicionar Peça", Icons.add_box, _adicionarPeca,
                  cor: Colors.orangeAccent),
              const SizedBox(height: 20),

              _titulo("Serviços"),
              ...servicosSelecionados.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return _itemCard(
                  icone: Icons.miscellaneous_services, cor: Colors.blueAccent,
                  titulo: s['nome'],
                  subtitulo: (s['descricao'] ?? '').toString().isNotEmpty ? s['descricao'] : null,
                  valor: (s['preco'] as num?)?.toDouble() ?? 0,
                  onDelete: () => setState(() => servicosSelecionados.removeAt(i)),
                );
              }),
              _seletor("+ Adicionar Serviço", Icons.miscellaneous_services,
                  _adicionarServico, cor: Colors.blueAccent),
              const SizedBox(height: 20),

              _titulo("Resumo Financeiro"),
              _linhaValor("Total Peças",    totalPecas,    Colors.orangeAccent),
              _linhaValor("Total Serviços", totalServicos, Colors.blueAccent),
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("TOTAL GERAL",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("R\$ ${totalGeral.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 22)),
                ]),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: formaPagamento,
                decoration: const InputDecoration(labelText: 'Pagamento', icon: Icon(Icons.credit_card)),
                items: ['Dinheiro', 'PIX', 'Cartão Débito', 'Cartão Crédito']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => formaPagamento = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status', icon: Icon(Icons.sync)),
                items: ['Orçamento', 'Aguardando Aprovação', 'Aprovado', 'Finalizado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => status = v!),
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _salvarOS,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    backgroundColor: Colors.green),
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

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
  );

  Widget _seletor(String texto, IconData icone, VoidCallback onTap, {Color cor = Colors.white70}) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              border: Border.all(color: cor.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(icone, color: cor),
            const SizedBox(width: 10),
            Expanded(child: Text(texto, style: TextStyle(color: cor))),
          ]),
        ),
      );

  Widget _campo(TextEditingController ctrl, String label, IconData icone) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icone), border: const OutlineInputBorder()),
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
        ),
      );

  Widget _itemCard({
    required IconData icone, required Color cor, required String titulo,
    String? subtitulo, required double valor, required VoidCallback onDelete,
  }) =>
      Card(
        color: Colors.white.withValues(alpha: 0.05),
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: Icon(icone, color: cor),
          title: Text(titulo, style: const TextStyle(color: Colors.white)),
          subtitle: subtitulo != null
              ? Text(subtitulo, style: const TextStyle(color: Colors.white54, fontSize: 12))
              : null,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text("R\$ ${valor.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
          ]),
        ),
      );

  Widget _linhaValor(String label, double valor, Color cor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    margin: const EdgeInsets.only(bottom: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: cor.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      Text("R\$ ${valor.toStringAsFixed(2)}",
          style: TextStyle(color: cor, fontWeight: FontWeight.bold)),
    ]),
  );
}