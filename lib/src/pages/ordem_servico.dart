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
    final ano  = DateTime.now().year.toString();
    final snap = await FirebaseFirestore.instance
        .collection('ordens')
        .where('ano_os', isEqualTo: ano)
        .get();
    int maior = 0;
    for (final doc in snap.docs) {
      final seq = doc.data()['sequencial_os'] as int? ?? 0;
      if (seq > maior) maior = seq;
    }
    return 'OS-$ano-${(maior + 1).toString().padLeft(3, '0')}';
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

  // ── DIALOG DE PEÇA (novo ou editar) ───────────────────────────────────────
  void _dialogPeca({Map<String, dynamic>? pecaExistente, int? indice}) {
    final nomeCtrl  = TextEditingController(text: pecaExistente?['nome']  ?? '');
    final precoCtrl = TextEditingController(
        text: pecaExistente != null
            ? (pecaExistente['preco'] as num?)?.toStringAsFixed(2) ?? ''
            : '');
    final qtdCtrl   = TextEditingController(
        text: (pecaExistente?['qtd'] ?? 1).toString());
    final custoCtrl = TextEditingController(
        text: pecaExistente != null && pecaExistente['custo'] != null
            ? (pecaExistente['custo'] as num).toStringAsFixed(2)
            : '');

    bool lancarGasto = pecaExistente?['lancar_gasto'] == true;
    final editando   = indice != null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(editando ? "Editar Peça" : "Adicionar Peça"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              TextField(
                controller: nomeCtrl,
                autofocus: !editando,
                decoration: const InputDecoration(
                    labelText: "Nome da peça",
                    prefixIcon: Icon(Icons.build)),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: precoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: "Preço de venda unitário (R\$)",
                    prefixIcon: Icon(Icons.attach_money)),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: qtdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Quantidade",
                    prefixIcon: Icon(Icons.numbers)),
              ),

              const SizedBox(height: 12),
              const Divider(),

              // ── CHECKBOX GASTO ─────────────────────────────────────
              InkWell(
                onTap: () => setDialog(() => lancarGasto = !lancarGasto),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: lancarGasto
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: lancarGasto
                          ? Colors.orangeAccent
                          : Colors.white24,
                    ),
                  ),
                  child: Row(children: [
                    Checkbox(
                      value: lancarGasto,
                      activeColor: Colors.orangeAccent,
                      onChanged: (v) =>
                          setDialog(() => lancarGasto = v ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        "Lançar custo no Fluxo de Caixa",
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ]),
                ),
              ),

              // Campo de custo (aparece só se checkbox marcado)
              if (lancarGasto) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: custoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: "Custo de compra da peça (R\$)",
                    prefixIcon: const Icon(Icons.shopping_cart,
                        color: Colors.orangeAccent),
                    helperText:
                    "Será lançado como saída ao salvar a OS",
                    filled: true,
                    fillColor: Colors.orange.withValues(alpha: 0.07),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CANCELAR")),
            ElevatedButton(
              onPressed: () {
                if (nomeCtrl.text.trim().isEmpty) return;
                final novaPeca = {
                  'nome':  nomeCtrl.text.trim(),
                  'preco': double.tryParse(
                      precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                  'qtd':   int.tryParse(qtdCtrl.text) ?? 1,
                  'lancar_gasto': lancarGasto,
                  if (lancarGasto)
                    'custo': double.tryParse(
                        custoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                };
                setState(() {
                  if (editando) {
                    pecasSelecionadas[indice!] = novaPeca;
                  } else {
                    pecasSelecionadas.add(novaPeca);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(editando ? "SALVAR" : "ADICIONAR"),
            ),
          ],
        ),
      ),
    );
  }

  // ── DIALOG DE SERVIÇO (novo ou editar) ────────────────────────────────────
  void _dialogServico({Map<String, dynamic>? servicoExistente, int? indice}) {
    final nomeCtrl  = TextEditingController(
        text: servicoExistente?['nome'] ?? '');
    final precoCtrl = TextEditingController(
        text: servicoExistente != null
            ? (servicoExistente['preco'] as num?)?.toStringAsFixed(2) ?? ''
            : '');
    final descCtrl  = TextEditingController(
        text: servicoExistente?['descricao'] ?? '');

    final editando = indice != null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editando ? "Editar Serviço" : "Adicionar Serviço"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: nomeCtrl,
              autofocus: !editando,
              decoration: const InputDecoration(
                  labelText: "Nome do serviço",
                  prefixIcon: Icon(Icons.miscellaneous_services)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: precoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: "Preço (R\$)",
                  prefixIcon: Icon(Icons.attach_money)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: "Obs (opcional)",
                  prefixIcon: Icon(Icons.description)),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (nomeCtrl.text.trim().isEmpty) return;
              final novoServico = {
                'nome':      nomeCtrl.text.trim(),
                'preco':     double.tryParse(
                    precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                'descricao': descCtrl.text.trim(),
              };
              setState(() {
                if (editando) {
                  servicosSelecionados[indice!] = novoServico;
                } else {
                  servicosSelecionados.add(novoServico);
                }
              });
              Navigator.pop(context);
            },
            child: Text(editando ? "SALVAR" : "ADICIONAR"),
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

    String numOS      = numeroOS ?? '';
    int    sequencial = 0;
    String ano        = DateTime.now().year.toString();

    // Lê dados anteriores da OS (se for edição)
    Map<String, dynamic> dadosAntigos = {};
    if (widget.osExistente != null) {
      dadosAntigos = widget.osExistente!.data() as Map<String, dynamic>;
      sequencial   = dadosAntigos['sequencial_os'] ?? 0;
      ano          = dadosAntigos['ano_os']        ?? ano;
    } else {
      numOS      = await _gerarNumeroOS();
      sequencial = int.tryParse(numOS.split('-').last) ?? 0;
    }

    // Flag que indica se os gastos de peças já foram lançados anteriormente
    final gastosJaLancados = dadosAntigos['gastos_lancados'] == true;
    final estaFinalizando  = status == 'Finalizado';

    final dadosParaSalvar = <String, dynamic>{
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

    // Marca a OS como tendo os gastos lançados quando finalizar
    if (estaFinalizando && !gastosJaLancados) {
      dadosParaSalvar['gastos_lancados']    = true;
      dadosParaSalvar['data_finalizacao']   = FieldValue.serverTimestamp();
    }

    try {
      String osId;
      if (widget.osExistente != null) {
        osId = widget.osExistente!.id;
        await FirebaseFirestore.instance
            .collection('ordens')
            .doc(osId)
            .update(dadosParaSalvar);
      } else {
        dadosParaSalvar['data_abertura'] = FieldValue.serverTimestamp();
        final ref = await FirebaseFirestore.instance
            .collection('ordens')
            .add(dadosParaSalvar);
        osId = ref.id;
      }

      // ── LANÇA GASTOS DE PEÇAS NO FLUXO DE CAIXA ─────────────────────
      // Regras:
      //   1. Só lança quando o status for "Finalizado"
      //   2. Só lança UMA VEZ (flag gastos_lancados protege contra edições futuras)
      if (estaFinalizando && !gastosJaLancados) {
        final pecasComGasto = pecasSelecionadas
            .where((p) => p['lancar_gasto'] == true)
            .toList();

        for (final peca in pecasComGasto) {
          final custo = (peca['custo'] as num?)?.toDouble() ?? 0;
          if (custo <= 0) continue;
          final qtd = (peca['qtd'] as num?)?.toInt() ?? 1;

          await FirebaseFirestore.instance.collection('transacoes').add({
            'tipo':            'Saída',
            'categoria':       'Fornecedor',
            'descricao':       'Peça: ${peca['nome']} ($numOS)',
            'valor':           custo * qtd,
            'forma_pagamento': 'Outros',
            'data':            Timestamp.now(),
            'os_numero':       numOS,
            'os_id':           osId,
            'criado_em':       FieldValue.serverTimestamp(),
          });
        }
      }

      if (!mounted) return;

      // Avisa o usuário sobre o que aconteceu ao finalizar
      if (estaFinalizando && !gastosJaLancados) {
        final totalGastos = pecasSelecionadas
            .where((p) => p['lancar_gasto'] == true)
            .fold<double>(0, (sum, p) =>
        sum +
            ((p['custo'] as num?)?.toDouble() ?? 0) *
                ((p['qtd'] as num?)?.toInt() ?? 1));

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            totalGastos > 0
                ? 'OS finalizada! Gasto de R\$ ${totalGastos.toStringAsFixed(2)} lançado no Fluxo de Caixa.'
                : 'OS finalizada!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ));
      }

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red));
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

              // ── CLIENTE ───────────────────────────────────────────────
              _titulo("Cliente"),
              _seletor(nomeClienteExibicao, Icons.person, _pesquisarCliente),
              const SizedBox(height: 20),

              // ── EQUIPAMENTO ───────────────────────────────────────────
              _titulo("Equipamento"),
              _campo(equipamentoController, 'Aparelho / Modelo', Icons.smartphone),
              _campo(defeitoController,     'Defeito / Relato',  Icons.error_outline),
              const SizedBox(height: 20),

              // ── PEÇAS ─────────────────────────────────────────────────
              _titulo("Peças Utilizadas"),
              ...pecasSelecionadas.asMap().entries.map((e) {
                final i   = e.key;
                final p   = e.value;
                final sub = ((p['preco'] as num?)?.toDouble() ?? 0) *
                    ((p['qtd']   as num?)?.toInt()    ?? 1);
                final temGasto = p['lancar_gasto'] == true;

                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: temGasto
                      ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                        color: Colors.orangeAccent, width: 1),
                  )
                      : null,
                  child: ListTile(
                    onTap: () => _dialogPeca(
                        pecaExistente: p, indice: i),
                    leading: Icon(Icons.build_circle,
                        color: temGasto
                            ? Colors.orangeAccent
                            : Colors.orangeAccent),
                    title: Text(
                      (p['qtd'] ?? 1) > 1
                          ? "${p['qtd']}x ${p['nome']}"
                          : p['nome'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("R\$ ${sub.toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Colors.greenAccent)),
                        if (temGasto)
                          Row(children: [
                            const Icon(Icons.arrow_downward,
                                size: 11, color: Colors.orangeAccent),
                            const SizedBox(width: 3),
                            Text(
                              "Custo: R\$ ${((p['custo'] as num?)?.toDouble() ?? 0) * ((p['qtd'] as num?)?.toInt() ?? 1).toDouble()}"
                                  .replaceAllMapped(
                                  RegExp(r'(\.\d{3,})'),
                                      (m) => (double.tryParse(
                                      m.group(0)!) ??
                                      0)
                                      .toStringAsFixed(2)
                                      .substring(1)),
                              style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 11),
                            ),
                          ]),
                      ],
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (temGasto)
                        const Tooltip(
                          message: 'Lança gasto no caixa',
                          child: Icon(Icons.account_balance_wallet,
                              size: 16, color: Colors.orangeAccent),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () =>
                            setState(() => pecasSelecionadas.removeAt(i)),
                      ),
                    ]),
                  ),
                );
              }),
              _seletor("+ Adicionar Peça", Icons.add_box,
                      () => _dialogPeca(),
                  cor: Colors.orangeAccent),
              const SizedBox(height: 20),

              // ── SERVIÇOS ──────────────────────────────────────────────
              _titulo("Serviços"),
              ...servicosSelecionados.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    onTap: () => _dialogServico(
                        servicoExistente: s, indice: i),
                    leading: const Icon(Icons.miscellaneous_services,
                        color: Colors.blueAccent),
                    title: Text(s['nome'],
                        style: const TextStyle(color: Colors.white)),
                    subtitle: (s['descricao'] ?? '').toString().isNotEmpty
                        ? Text(s['descricao'],
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12))
                        : null,
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          "R\$ ${(s['preco'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}",
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () => setState(
                                () => servicosSelecionados.removeAt(i)),
                      ),
                    ]),
                  ),
                );
              }),
              _seletor("+ Adicionar Serviço", Icons.miscellaneous_services,
                      () => _dialogServico(),
                  cor: Colors.blueAccent),
              const SizedBox(height: 20),

              // ── RESUMO FINANCEIRO ─────────────────────────────────────
              _titulo("Resumo Financeiro"),
              _linhaValor("Total Peças",    totalPecas,    Colors.orangeAccent),
              _linhaValor("Total Serviços", totalServicos, Colors.blueAccent),
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TOTAL GERAL",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text("R\$ ${totalGeral.toStringAsFixed(2)}",
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 22)),
                    ]),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: formaPagamento,
                decoration: const InputDecoration(
                    labelText: 'Pagamento',
                    icon: Icon(Icons.credit_card)),
                items: ['Dinheiro', 'PIX', 'Cartão Débito', 'Cartão Crédito']
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => formaPagamento = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(
                    labelText: 'Status', icon: Icon(Icons.sync)),
                items: [
                  'Orçamento',
                  'Aguardando Aprovação',
                  'Aprovado',
                  'Finalizado'
                ]
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
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

  // ── WIDGETS AUXILIARES ─────────────────────────────────────────────────────

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(texto,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent)),
  );

  Widget _seletor(String texto, IconData icone, VoidCallback onTap,
      {Color cor = Colors.white70}) =>
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
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icone),
              border: const OutlineInputBorder()),
          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
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
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text("R\$ ${valor.toStringAsFixed(2)}",
              style: TextStyle(
                  color: cor, fontWeight: FontWeight.bold)),
        ]),
  );
}