import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatrimonioPage extends StatefulWidget {
  const PatrimonioPage({super.key});

  @override
  State<PatrimonioPage> createState() => _PatrimonioPageState();
}

class _PatrimonioPageState extends State<PatrimonioPage> {
  String _busca = '';

  // Categorias padrão para equipamentos de oficina
  static const _categorias = [
    'Ferramentas',
    'Equipamentos',
    'Veículos',
    'Móveis / Estrutura',
    'Eletrônicos',
    'Outros',
  ];

  // ── ABRIR FORMULÁRIO ───────────────────────────────────────────────────────
  void _abrirFormulario({DocumentSnapshot? docExistente}) {
    final dados = docExistente?.data() as Map<String, dynamic>?;

    final nomeCtrl  = TextEditingController(text: dados?['nome'] ?? '');
    final valorCtrl = TextEditingController(
        text: dados != null
            ? (dados['valor_pago'] as num?)?.toStringAsFixed(2) ?? ''
            : '');
    final obsCtrl   = TextEditingController(text: dados?['observacoes'] ?? '');
    String categoria = dados?['categoria'] ?? _categorias.first;
    bool salvando    = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D2B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                // Título
                Row(children: [
                  const Icon(Icons.inventory_2, color: Colors.purpleAccent),
                  const SizedBox(width: 10),
                  Text(
                    docExistente == null ? 'Novo Item' : 'Editar Item',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ]),
                const SizedBox(height: 20),

                // Nome
                _input(nomeCtrl, 'Nome do equipamento / item',
                    Icons.label_outline),
                const SizedBox(height: 12),

                // Categoria
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: categoria,
                      dropdownColor: const Color(0xFF1A1A2E),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white38),
                      items: _categorias
                          .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(children: [
                          Icon(_iconeCategoria(c),
                              color: Colors.white38, size: 16),
                          const SizedBox(width: 10),
                          Text(c,
                              style: const TextStyle(
                                  color: Colors.white)),
                        ]),
                      ))
                          .toList(),
                      onChanged: (v) =>
                          setModal(() => categoria = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Valor pago
                TextField(
                  controller: valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(
                        color: Colors.greenAccent.withOpacity(0.7),
                        fontSize: 18),
                    hintText: '0,00',
                    hintStyle: TextStyle(
                        color: Colors.greenAccent.withOpacity(0.3),
                        fontSize: 22),
                    labelText: 'Valor pago',
                    labelStyle:
                    const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.greenAccent.withOpacity(0.06),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.greenAccent.withOpacity(0.2))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Colors.greenAccent)),
                  ),
                ),
                const SizedBox(height: 12),

                // Observações
                _input(obsCtrl, 'Observações (opcional)',
                    Icons.notes, maxLines: 2),
                const SizedBox(height: 24),

                // Botão salvar
                salvando
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nomeCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Informe o nome do item.'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }
                    setModal(() => salvando = true);
                    try {
                      final payload = <String, dynamic>{
                        'nome':       nomeCtrl.text.trim(),
                        'categoria':  categoria,
                        'valor_pago': double.tryParse(
                            valorCtrl.text
                                .replaceAll(',', '.')) ??
                            0.0,
                        'observacoes': obsCtrl.text.trim(),
                        'ultima_atualizacao':
                        FieldValue.serverTimestamp(),
                      };
                      if (docExistente == null) {
                        payload['data_cadastro'] =
                            FieldValue.serverTimestamp();
                        await FirebaseFirestore.instance
                            .collection('patrimonio')
                            .add(payload);
                      } else {
                        await FirebaseFirestore.instance
                            .collection('patrimonio')
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
                        ? 'SALVAR ITEM'
                        : 'ATUALIZAR ITEM',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── CONFIRMAR EXCLUSÃO ────────────────────────────────────────────────────
  Future<void> _excluir(String id, String nome) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Excluir Item?',
            style: TextStyle(color: Colors.white)),
        content: Text('Remover "$nome"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('EXCLUIR',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await FirebaseFirestore.instance
        .collection('patrimonio')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      appBar: AppBar(
        title: const Text('Patrimônio'),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              onChanged: (v) => setState(() => _busca = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar item ou categoria...',
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
        backgroundColor: Colors.purpleAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Item',
            style: TextStyle(color: Colors.white)),
        onPressed: _abrirFormulario,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patrimonio')
            .orderBy('categoria')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data!.docs.where((doc) {
            final d    = doc.data() as Map<String, dynamic>;
            final nome = (d['nome']      ?? '').toString().toLowerCase();
            final cat  = (d['categoria'] ?? '').toString().toLowerCase();
            return nome.contains(_busca) || cat.contains(_busca);
          }).toList();

          if (todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2,
                      size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    _busca.isEmpty
                        ? 'Nenhum item cadastrado.'
                        : 'Nenhum item encontrado.',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  if (_busca.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Toque em + para adicionar.',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 13)),
                    ),
                ],
              ),
            );
          }

          // Total geral investido
          final totalGeral = todos.fold<double>(0, (sum, doc) {
            final d = doc.data() as Map<String, dynamic>;
            return sum + ((d['valor_pago'] as num?)?.toDouble() ?? 0);
          });

          // Agrupa por categoria
          final Map<String, List<QueryDocumentSnapshot>> porCategoria = {};
          for (final doc in todos) {
            final d   = doc.data() as Map<String, dynamic>;
            final cat = (d['categoria'] ?? 'Outros').toString();
            porCategoria.putIfAbsent(cat, () => []).add(doc);
          }

          return Column(
            children: [

              // ── CARD DE TOTAL INVESTIDO ─────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purpleAccent.withOpacity(0.25),
                      Colors.deepPurple.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.purpleAccent.withOpacity(0.4)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet,
                        color: Colors.purpleAccent, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Investido em Patrimônio',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          'R\$ ${totalGeral.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${todos.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'item${todos.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ]),
              ),

              // ── LISTA POR CATEGORIA ─────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                  children: porCategoria.entries.map((entry) {
                    final totalCat = entry.value.fold<double>(0, (s, doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return s +
                          ((d['valor_pago'] as num?)?.toDouble() ?? 0);
                    });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Header da categoria
                        Padding(
                          padding:
                          const EdgeInsets.fromLTRB(4, 14, 4, 6),
                          child: Row(children: [
                            Icon(_iconeCategoria(entry.key),
                                color: Colors.purpleAccent, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                  color: Colors.purpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.value.length} item${entry.value.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              'R\$ ${totalCat.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Colors.purpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ]),
                        ),

                        // Cards dos itens
                        ...entry.value.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final valor =
                              (d['valor_pago'] as num?)?.toDouble() ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.purpleAccent
                                      .withOpacity(0.2)),
                            ),
                            child: ListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              leading: Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: Colors.purpleAccent
                                      .withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconeCategoria(d['categoria'] ?? ''),
                                  color: Colors.purpleAccent,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                d['nome'] ?? 'Sem nome',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: (d['observacoes'] ?? '')
                                  .toString()
                                  .isNotEmpty
                                  ? Padding(
                                padding:
                                const EdgeInsets.only(top: 3),
                                child: Text(
                                  d['observacoes'],
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    valor > 0
                                        ? 'R\$ ${valor.toStringAsFixed(2)}'
                                        : '---',
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _abrirFormulario(
                                            docExistente: doc),
                                        child: const Icon(Icons.edit,
                                            color: Colors.blueAccent,
                                            size: 18),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => _excluir(
                                            doc.id,
                                            d['nome'] ?? 'Item'),
                                        child: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                            size: 18),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  IconData _iconeCategoria(String cat) {
    switch (cat) {
      case 'Ferramentas':       return Icons.build;
      case 'Equipamentos':      return Icons.precision_manufacturing;
      case 'Veículos':          return Icons.directions_car;
      case 'Móveis / Estrutura': return Icons.chair;
      case 'Eletrônicos':       return Icons.devices;
      default:                  return Icons.inventory_2;
    }
  }

  Widget _input(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        int maxLines = 1,
      }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: Colors.white38, size: 18),
          filled: true,
          fillColor: Colors.white.withOpacity(0.07),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: Colors.purpleAccent)),
        ),
      );
}