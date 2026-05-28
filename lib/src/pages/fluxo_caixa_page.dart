import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lancamento_financeiro_page.dart';
import '../services/relatorio_pdf_service.dart';

class FluxoCaixaPage extends StatefulWidget {
  const FluxoCaixaPage({super.key});

  @override
  State<FluxoCaixaPage> createState() => _FluxoCaixaPageState();
}

class _FluxoCaixaPageState extends State<FluxoCaixaPage> {
  // Filtro de período
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;

  // Filtro de tipo
  String _filtroTipo = 'Todos'; // Todos, Entrada, Saída

  final List<String> _meses = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];

  DateTime get _inicio => DateTime(_anoSelecionado, _mesSelecionado, 1);
  DateTime get _fim => DateTime(_anoSelecionado, _mesSelecionado + 1, 0, 23, 59, 59);

  void _mudarMes(int delta) {
    setState(() {
      _mesSelecionado += delta;
      if (_mesSelecionado > 12) { _mesSelecionado = 1; _anoSelecionado++; }
      if (_mesSelecionado < 1)  { _mesSelecionado = 12; _anoSelecionado--; }
    });
  }

  Color _corCategoria(String cat) {
    const mapa = {
      'OS / Serviço': Colors.greenAccent,
      'Peça Vendida': Colors.tealAccent,
      'Aluguel': Colors.redAccent,
      'Fornecedor': Colors.orangeAccent,
      'Salário': Colors.purpleAccent,
      'Energia / Água': Colors.yellowAccent,
      'Outros': Colors.blueGrey,
    };
    return mapa[cat] ?? Colors.white54;
  }

  IconData _iconeCategoria(String cat) {
    const mapa = {
      'OS / Serviço': Icons.build_circle,
      'Peça Vendida': Icons.inventory_2,
      'Aluguel': Icons.home,
      'Fornecedor': Icons.local_shipping,
      'Salário': Icons.badge,
      'Energia / Água': Icons.bolt,
      'Outros': Icons.category,
    };
    return mapa[cat] ?? Icons.attach_money;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      appBar: AppBar(
        title: const Text('Fluxo de Caixa'),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            tooltip: 'Exportar PDF',
            onPressed: _exportarPDF,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Lançamento', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LancamentoFinanceiroPage()),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transacoes')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Todas as transações do mês selecionado
          final todasDoMes = snapshot.data!.docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final data = (d['data'] as Timestamp?)?.toDate();
            if (data == null) return false;
            return data.isAfter(_inicio.subtract(const Duration(seconds: 1))) &&
                data.isBefore(_fim.add(const Duration(seconds: 1)));
          }).toList();

          // Filtro visual por tipo
          final listaFiltrada = todasDoMes.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            if (_filtroTipo == 'Todos') return true;
            return (d['tipo'] ?? '') == _filtroTipo;
          }).toList();

          // Totais
          double totalEntradas = 0;
          double totalSaidas = 0;
          for (var doc in todasDoMes) {
            final d = doc.data() as Map<String, dynamic>;
            final v = (d['valor'] as num?)?.toDouble() ?? 0;
            if (d['tipo'] == 'Entrada') totalEntradas += v;
            if (d['tipo'] == 'Saída')   totalSaidas   += v;
          }
          double saldo = totalEntradas - totalSaidas;

          // Dados para o gráfico (últimos 6 meses)
          return Column(
            children: [
              // ── SELETOR DE MÊS ────────────────────────────────────
              Container(
                color: const Color(0xFF000044),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () => _mudarMes(-1),
                    ),
                    Text(
                      '${_meses[_mesSelecionado - 1]} $_anoSelecionado',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () => _mudarMes(1),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 90),
                  children: [
                    // ── CARDS DE RESUMO ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _cardResumo('Entradas', totalEntradas, Colors.greenAccent, Icons.arrow_downward),
                          const SizedBox(width: 8),
                          _cardResumo('Saídas', totalSaidas, Colors.redAccent, Icons.arrow_upward),
                          const SizedBox(width: 8),
                          _cardResumo('Saldo', saldo, saldo >= 0 ? Colors.blueAccent : Colors.orangeAccent, Icons.account_balance_wallet),
                        ],
                      ),
                    ),

                    // ── GRÁFICO DE BARRAS ─────────────────────────
                    _GraficoMensal(
                      anoSelecionado: _anoSelecionado,
                      mesSelecionado: _mesSelecionado,
                    ),

                    // ── FILTRO DE TIPO ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: ['Todos', 'Entrada', 'Saída'].map((tipo) {
                          final ativo = _filtroTipo == tipo;
                          Color cor = tipo == 'Entrada'
                              ? Colors.greenAccent
                              : tipo == 'Saída'
                                  ? Colors.redAccent
                                  : Colors.blueAccent;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _filtroTipo = tipo),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: ativo ? cor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: ativo ? cor : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(tipo,
                                      style: TextStyle(
                                          color: ativo ? cor : Colors.white54,
                                          fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 13)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── LISTA DE TRANSAÇÕES ────────────────────────
                    if (listaFiltrada.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text('Nenhuma transação neste período.',
                              style: TextStyle(color: Colors.white38)),
                        ),
                      )
                    else
                      ...listaFiltrada.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final tipo = d['tipo'] ?? 'Entrada';
                        final valor = (d['valor'] as num?)?.toDouble() ?? 0.0;
                        final categoria = d['categoria'] ?? 'Outros';
                        final desc = d['descricao'] ?? '';
                        final forma = d['forma_pagamento'] ?? '';
                        final data = (d['data'] as Timestamp?)?.toDate();
                        final dataStr = data != null
                            ? '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}'
                            : '';
                        final isEntrada = tipo == 'Entrada';

                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red.withOpacity(0.3),
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          confirmDismiss: (_) async {
                            return await _confirmarExclusao(doc.id, desc);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isEntrada
                                    ? Colors.greenAccent.withOpacity(0.2)
                                    : Colors.redAccent.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _corCategoria(categoria).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_iconeCategoria(categoria),
                                    color: _corCategoria(categoria), size: 20),
                              ),
                              title: Text(desc.isNotEmpty ? desc : categoria,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '$categoria${forma.isNotEmpty ? " • $forma" : ""} • $dataStr',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isEntrada ? '+' : '-'} R\$ ${valor.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isEntrada ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isEntrada
                                          ? Colors.greenAccent.withOpacity(0.15)
                                          : Colors.redAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(tipo,
                                        style: TextStyle(
                                            color: isEntrada ? Colors.greenAccent : Colors.redAccent,
                                            fontSize: 10)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cardResumo(String label, double valor, Color cor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icone, color: cor, size: 14),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: cor, fontSize: 11)),
            ]),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'R\$ ${valor.toStringAsFixed(2)}',
                style: TextStyle(
                    color: cor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmarExclusao(String id, String desc) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Excluir lançamento?', style: TextStyle(color: Colors.white)),
        content: Text('Remover "$desc"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (resultado == true) {
      await FirebaseFirestore.instance.collection('transacoes').doc(id).delete();
    }
    return resultado ?? false;
  }

  Future<void> _exportarPDF() async {
    try {
      // Busca transações do mês para o PDF
      final snap = await FirebaseFirestore.instance
          .collection('transacoes')
          .orderBy('data', descending: false)
          .get();

      final transacoes = snap.docs
          .where((doc) {
            final d = doc.data();
            final data = (d['data'] as Timestamp?)?.toDate();
            if (data == null) return false;
            return data.isAfter(_inicio.subtract(const Duration(seconds: 1))) &&
                data.isBefore(_fim.add(const Duration(seconds: 1)));
          })
          .map((doc) => doc.data())
          .toList();

      await RelatorioPdfService.gerarRelatorio(
        transacoes: transacoes,
        mes: _meses[_mesSelecionado - 1],
        ano: _anoSelecionado,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// ── WIDGET DE GRÁFICO ──────────────────────────────────────────────────────────
class _GraficoMensal extends StatelessWidget {
  final int anoSelecionado;
  final int mesSelecionado;

  const _GraficoMensal({
    required this.anoSelecionado,
    required this.mesSelecionado,
  });

  @override
  Widget build(BuildContext context) {
    // Últimos 6 meses
    List<Map<String, dynamic>> periodos = [];
    for (int i = 5; i >= 0; i--) {
      int m = mesSelecionado - i;
      int a = anoSelecionado;
      while (m < 1) { m += 12; a--; }
      periodos.add({'mes': m, 'ano': a});
    }

    const mesesNome = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transacoes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
        }

        // Calcula entradas e saídas para cada mês dos últimos 6
        List<double> entradas = List.filled(6, 0);
        List<double> saidas   = List.filled(6, 0);

        for (var doc in snapshot.data!.docs) {
          final d = doc.data() as Map<String, dynamic>;
          final data = (d['data'] as Timestamp?)?.toDate();
          if (data == null) continue;
          final valor = (d['valor'] as num?)?.toDouble() ?? 0;
          final tipo = d['tipo'] ?? '';

          for (int i = 0; i < 6; i++) {
            if (data.month == periodos[i]['mes'] && data.year == periodos[i]['ano']) {
              if (tipo == 'Entrada') entradas[i] += valor;
              if (tipo == 'Saída')   saidas[i]   += valor;
            }
          }
        }

        double maxVal = 0;
        for (int i = 0; i < 6; i++) {
          if (entradas[i] > maxVal) maxVal = entradas[i];
          if (saidas[i]   > maxVal) maxVal = saidas[i];
        }
        if (maxVal == 0) maxVal = 1;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Últimos 6 meses',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Row(children: [
                _legenda(Colors.greenAccent, 'Entradas'),
                const SizedBox(width: 16),
                _legenda(Colors.redAccent, 'Saídas'),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(6, (i) {
                    final hE = (entradas[i] / maxVal) * 100;
                    final hS = (saidas[i]   / maxVal) * 100;
                    final isMesAtual = periodos[i]['mes'] == mesSelecionado &&
                        periodos[i]['ano'] == anoSelecionado;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _barra(hE, Colors.greenAccent, isMesAtual),
                                const SizedBox(width: 2),
                                _barra(hS, Colors.redAccent, isMesAtual),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mesesNome[periodos[i]['mes']! - 1],
                              style: TextStyle(
                                color: isMesAtual ? Colors.white : Colors.white38,
                                fontSize: 10,
                                fontWeight: isMesAtual ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _barra(double altura, Color cor, bool destaque) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: 10,
      height: altura.clamp(2, 100),
      decoration: BoxDecoration(
        color: destaque ? cor : cor.withOpacity(0.45),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _legenda(Color cor, String texto) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(texto, style: TextStyle(color: cor, fontSize: 11)),
    ]);
  }
}
