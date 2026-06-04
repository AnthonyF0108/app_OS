import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MotosLeilaoPage extends StatefulWidget {
  const MotosLeilaoPage({super.key});

  @override
  State<MotosLeilaoPage> createState() => _MotosLeilaoPageState();
}

class _MotosLeilaoPageState extends State<MotosLeilaoPage> {
  String _busca = "";

  // ── ABRIR FORMULÁRIO (nova ou editar) ──────────────────────────────────────
  void _abrirFormulario({DocumentSnapshot? docExistente}) {
    final dados = docExistente != null
        ? docExistente.data() as Map<String, dynamic>
        : null;

    final modeloCtrl = TextEditingController(text: dados?['modelo'] ?? '');
    final anoCtrl    = TextEditingController(text: dados?['ano']    ?? '');
    final placaCtrl  = TextEditingController(text: dados?['placa']  ?? '');
    final corCtrl    = TextEditingController(text: dados?['cor']    ?? '');
    final compraCtrl = TextEditingController(
        text: dados != null
            ? (dados['valor_compra'] as num?)?.toStringAsFixed(2) ?? ''
            : '');
    final fipeCtrl   = TextEditingController(
        text: dados != null
            ? (dados['valor_fipe'] as num?)?.toStringAsFixed(2) ?? ''
            : '');
    final vendaCtrl  = TextEditingController(
        text: dados != null
            ? (dados['valor_venda'] as num?)?.toStringAsFixed(2) ?? ''
            : '');
    final obsCtrl = TextEditingController(text: dados?['observacoes'] ?? '');

    // Status: Padrão é 'Em conserto' se for nova, ou pega o valor do banco
    String statusSelecionado = dados?['status'] ?? 'Em conserto';

    // Peças já salvas
    List<Map<String, dynamic>> pecas = dados?['pecas'] != null
        ? List<Map<String, dynamic>>.from(dados!['pecas'])
        : [];

    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D2B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) {
          // ── Totais ─────────────────────────────────────────────────────
          double totalPecas = pecas.fold(0, (sum, p) =>
          sum + ((p['valor'] as num?)?.toDouble() ?? 0) *
              ((p['qtd']   as num?)?.toInt()    ?? 1));
          double compra     = double.tryParse(
              compraCtrl.text.replaceAll(',', '.')) ?? 0;
          double custoTotal = compra + totalPecas;

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Título
                  Row(children: [
                    const Icon(Icons.two_wheeler, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(
                      docExistente == null ? 'Nova Moto' : 'Editar Moto',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── STATUS DA MOTO ──────────────────────────────────────
                  DropdownButtonFormField<String>(
                    value: statusSelecionado,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    decoration: _decModal('Status do Veículo', Icons.info_outline),
                    items: const [
                      DropdownMenuItem(value: 'Em conserto', child: Text('Em conserto')),
                      DropdownMenuItem(value: 'Finalizada', child: Text('Finalizada')),
                    ],
                    onChanged: (novoStatus) {
                      if (novoStatus != null) {
                        setModal(() => statusSelecionado = novoStatus);
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // ── DADOS DA MOTO ───────────────────────────────────────
                  _inputModal(modeloCtrl, 'Modelo (ex: Honda CG 160)',
                      Icons.directions_bike),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _inputModal(anoCtrl, 'Ano', Icons.calendar_today,
                        keyboard: TextInputType.number)),
                    const SizedBox(width: 10),
                    Expanded(child: _inputModal(placaCtrl, 'Placa', Icons.pin)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _inputModal(corCtrl, 'Cor', Icons.palette)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: compraCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setModal(() {}),
                        decoration: _decModal(
                            'Valor de Compra (R\$)', Icons.attach_money),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // ── VALORES FIPE E VENDA ─────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: fipeCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _decModal(
                            'Valor FIPE (R\$)', Icons.bar_chart),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: vendaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _decModal(
                            'Vendido por (R\$)', Icons.monetization_on),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  _inputModal(obsCtrl, 'Observações', Icons.notes,
                      maxLines: 2),

                  const SizedBox(height: 20),

                  // ── PEÇAS ────────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Peças / Gastos',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16,
                            color: Colors.blueAccent),
                        label: const Text('Adicionar',
                            style: TextStyle(color: Colors.blueAccent)),
                        onPressed: () => _dialogPeca(
                          context: context,
                          onSalvar: (peca) =>
                              setModal(() => pecas.add(peca)),
                        ),
                      ),
                    ],
                  ),

                  if (pecas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nenhuma peça adicionada.',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 13)),
                    )
                  else
                    ...pecas.asMap().entries.map((e) {
                      final i = e.key;
                      final p = e.value;
                      final sub = ((p['valor'] as num?)?.toDouble() ?? 0) *
                          ((p['qtd']   as num?)?.toInt()    ?? 1);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.build_circle,
                              color: Colors.orangeAccent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['nome'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  '${p['qtd']}x R\$ ${(p['valor'] as num?)?.toStringAsFixed(2)} = R\$ ${sub.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          // Editar peça
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent, size: 18),
                            onPressed: () => _dialogPeca(
                              context: context,
                              pecaExistente: p,
                              onSalvar: (nova) =>
                                  setModal(() => pecas[i] = nova),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 18),
                            onPressed: () =>
                                setModal(() => pecas.removeAt(i)),
                          ),
                        ]),
                      );
                    }),

                  const SizedBox(height: 12),

                  // ── RESUMO DE CUSTO ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000033),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      _linhaResumo('Valor de Compra',
                          'R\$ ${compra.toStringAsFixed(2)}',
                          Colors.white70),
                      const SizedBox(height: 4),
                      _linhaResumo('Total em Peças',
                          'R\$ ${totalPecas.toStringAsFixed(2)}',
                          Colors.orangeAccent),
                      const Divider(color: Colors.white12, height: 16),
                      _linhaResumo('CUSTO TOTAL',
                          'R\$ ${custoTotal.toStringAsFixed(2)}',
                          Colors.greenAccent,
                          bold: true, fontSize: 16),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // ── SALVAR ───────────────────────────────────────────────
                  salvando
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (modeloCtrl.text.trim().isEmpty) return;
                      setModal(() => salvando = true);
                      try {
                        final payload = {
                          'modelo': modeloCtrl.text.trim(),
                          'ano':    anoCtrl.text.trim(),
                          'placa':  placaCtrl.text.trim().toUpperCase(),
                          'cor':    corCtrl.text.trim(),
                          'status': statusSelecionado,
                          'valor_compra': double.tryParse(
                              compraCtrl.text.replaceAll(',', '.')) ?? 0.0,
                          'valor_fipe': double.tryParse(
                              fipeCtrl.text.replaceAll(',', '.')) ?? 0.0,
                          'valor_venda': double.tryParse(
                              vendaCtrl.text.replaceAll(',', '.')) ?? 0.0,
                          'observacoes': obsCtrl.text.trim(),
                          'pecas':       pecas,
                          'custo_total': custoTotal,
                          'ultima_atualizacao':
                          FieldValue.serverTimestamp(),
                        };
                        if (docExistente == null) {
                          payload['data_compra'] =
                              FieldValue.serverTimestamp();
                          await FirebaseFirestore.instance
                              .collection('motos_leilao')
                              .add(payload);
                        } else {
                          await FirebaseFirestore.instance
                              .collection('motos_leilao')
                              .doc(docExistente.id)
                              .update(payload);
                        }
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setModal(() => salvando = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Erro: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Text(
                      docExistente == null
                          ? 'SALVAR MOTO'
                          : 'ATUALIZAR MOTO',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── DIALOG PEÇA ────────────────────────────────────────────────────────────
  void _dialogPeca({
    required BuildContext context,
    Map<String, dynamic>? pecaExistente,
    required Function(Map<String, dynamic>) onSalvar,
  }) {
    final nomeCtrl  = TextEditingController(
        text: pecaExistente?['nome'] ?? '');
    final qtdCtrl   = TextEditingController(
        text: (pecaExistente?['qtd'] ?? 1).toString());
    final valorCtrl = TextEditingController(
        text: pecaExistente != null
            ? (pecaExistente['valor'] as num?)?.toStringAsFixed(2) ?? ''
            : '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          pecaExistente == null ? 'Adicionar Peça' : 'Editar Peça',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nomeCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: _decModal('Nome da peça', Icons.build),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: qtdCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _decModal('Qtd', Icons.numbers),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: valorCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: _decModal('Valor unit. (R\$)', Icons.attach_money),
              ),
            ),
          ]),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (nomeCtrl.text.trim().isEmpty) return;
              onSalvar({
                'nome':  nomeCtrl.text.trim(),
                'qtd':   int.tryParse(qtdCtrl.text) ?? 1,
                'valor': double.tryParse(
                    valorCtrl.text.replaceAll(',', '.')) ?? 0.0,
              });
              Navigator.pop(context);
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  // ── CONFIRMAR EXCLUSÃO ─────────────────────────────────────────────────────
  void _confirmarExclusao(String id, String modelo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Excluir Moto?',
            style: TextStyle(color: Colors.white)),
        content: Text('Remover "$modelo"? Esta ação não pode ser desfeita.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('motos_leilao')
                  .doc(id)
                  .delete();
            },
            child: const Text('EXCLUIR',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      appBar: AppBar(
        title: const Text('Motos do Leilão'),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (v) => setState(() => _busca = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por modelo ou placa...',
                prefixIcon:
                const Icon(Icons.search, color: Colors.white70),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
        const Text('Nova Moto', style: TextStyle(color: Colors.white)),
        onPressed: () => _abrirFormulario(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('motos_leilao')
            .orderBy('ultima_atualizacao', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final motas = snapshot.data!.docs.where((doc) {
            final d      = doc.data() as Map<String, dynamic>;
            final modelo = (d['modelo'] ?? '').toString().toLowerCase();
            final placa  = (d['placa']  ?? '').toString().toLowerCase();
            return modelo.contains(_busca) || placa.contains(_busca);
          }).toList();

          if (motas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.two_wheeler,
                      size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    _busca.isEmpty
                        ? 'Nenhuma moto cadastrada.'
                        : 'Nenhuma moto encontrada.',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  if (_busca.isEmpty)
                    const Text('Toque em + para adicionar.',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }

          // Resumo geral no topo
          double totalGeral = motas.fold(0, (sum, doc) {
            final d = doc.data() as Map<String, dynamic>;
            return sum + ((d['custo_total'] as num?)?.toDouble() ?? 0);
          });

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                  itemCount: motas.length,
                  itemBuilder: (context, index) {
                    final doc  = motas[index];
                    final d    = doc.data() as Map<String, dynamic>;
                    final pecas = (d['pecas'] as List?)?.length ?? 0;
                    final custoTotal = (d['custo_total'] as num?)
                        ?.toDouble() ?? 0;
                    final compra = (d['valor_compra'] as num?)
                        ?.toDouble() ?? 0;
                    final totalPecas = custoTotal - compra;

                    final status = d['status'] ?? 'Em conserto';
                    final fipe = (d['valor_fipe'] as num?)?.toDouble() ?? 0.0;
                    final venda = (d['valor_venda'] as num?)?.toDouble() ?? 0.0;

                    return Card(
                      color: Colors.white.withValues(alpha: 0.05),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                            color: Colors.blueAccent.withValues(alpha: 0.2)),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.two_wheeler,
                              color: Colors.blueAccent, size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                d['modelo'] ?? 'Sem modelo',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Etiqueta de Status (Em Conserto ou Finalizada)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: status == 'Finalizada'
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: status == 'Finalizada' ? Colors.green : Colors.orange,
                                      width: 1
                                  )
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'Finalizada' ? Colors.greenAccent : Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(children: [
                          if ((d['placa'] ?? '').toString().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(d['placa'],
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if ((d['ano'] ?? '').toString().isNotEmpty)
                            Text(d['ano'],
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12)),
                          if ((d['cor'] ?? '').toString().isNotEmpty)
                            Text(' • ${d['cor']}',
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12)),
                        ]),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'R\$ ${custoTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            Text(
                              '$pecas peça${pecas != 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Detalhes financeiros primários
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                                  children: [
                                    _cardCusto('Compra',
                                        'R\$ ${compra.toStringAsFixed(2)}',
                                        Colors.blueAccent),
                                    _cardCusto('Peças',
                                        'R\$ ${totalPecas.toStringAsFixed(2)}',
                                        Colors.orangeAccent),
                                    _cardCusto('Custo Total',
                                        'R\$ ${custoTotal.toStringAsFixed(2)}',
                                        Colors.greenAccent),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Detalhes financeiros secundários (FIPE e Venda)
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                                  children: [
                                    _cardCusto('Valor FIPE',
                                        fipe > 0 ? 'R\$ ${fipe.toStringAsFixed(2)}' : '---',
                                        Colors.purpleAccent),
                                    _cardCusto('Vendida por',
                                        venda > 0 ? 'R\$ ${venda.toStringAsFixed(2)}' : '---',
                                        Colors.tealAccent),
                                  ],
                                ),

                                // Observações
                                if ((d['observacoes'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Divider(color: Colors.white12),
                                  Text('Obs: ${d['observacoes']}',
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13)),
                                ],

                                // Lista de peças
                                if ((d['pecas'] as List?)?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: 10),
                                  const Divider(color: Colors.white12),
                                  const Text('Peças:',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                  ...(d['pecas'] as List).map((p) {
                                    final sub =
                                        ((p['valor'] as num?)?.toDouble() ??
                                            0) *
                                            ((p['qtd'] as num?)?.toInt() ??
                                                1);
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, top: 3),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${p['qtd']}x ${p['nome']}',
                                            style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12),
                                          ),
                                          Text(
                                            'R\$ ${sub.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],

                                const SizedBox(height: 10),
                                const Divider(color: Colors.white12),

                                // Botões
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blueAccent),
                                      tooltip: 'Editar',
                                      onPressed: () => _abrirFormulario(
                                          docExistente: doc),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent),
                                      tooltip: 'Excluir',
                                      onPressed: () => _confirmarExclusao(
                                          doc.id, d['modelo'] ?? 'Moto'),
                                    ),
                                  ],
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
        },
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  Widget _cardCusto(String label, String valor, Color cor) => Column(
    children: [
      Text(label,
          style: TextStyle(color: cor.withValues(alpha: 0.7),
              fontSize: 11)),
      const SizedBox(height: 2),
      Text(valor,
          style: TextStyle(
              color: cor,
              fontWeight: FontWeight.bold,
              fontSize: 14)),
    ],
  );

  Widget _linhaResumo(String label, String valor, Color cor,
      {bool bold = false, double fontSize = 13}) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                color: cor,
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        Text(valor,
            style: TextStyle(
                color: cor,
                fontSize: fontSize,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ]);

  Widget _inputModal(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
      }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _decModal(label, icon),
      );

  InputDecoration _decModal(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white60),
    prefixIcon: Icon(icon, color: Colors.white38, size: 18),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.07),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none),
  );
}