import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LancamentoFinanceiroPage extends StatefulWidget {
  /// Se passado, pré-preenche com dados de uma OS (confirmação de recebimento)
  final Map<String, dynamic>? dadosOS;
  final String? osId;
  /// Valor ainda não pago da OS — limita o campo valor e pré-preenche
  final double? valorRestante;

  const LancamentoFinanceiroPage({
    super.key,
    this.dadosOS,
    this.osId,
    this.valorRestante,
  });

  @override
  State<LancamentoFinanceiroPage> createState() => _LancamentoFinanceiroPageState();
}

class _LancamentoFinanceiroPageState extends State<LancamentoFinanceiroPage> {
  String _tipo = 'Entrada';
  String _categoria = 'OS / Serviço';
  String _formaPagamento = 'Dinheiro';
  DateTime _dataSelecionada = DateTime.now();
  bool _salvando = false;

  final _descController   = TextEditingController();
  final _valorController  = TextEditingController();

  // Categorias disponíveis por tipo
  static const _categoriasEntrada = ['OS / Serviço', 'Peça Vendida', 'Outros'];
  static const _categoriasSaida   = ['Fornecedor', 'Aluguel', 'Salário', 'Energia / Água', 'Outros'];

  List<String> get _categorias =>
      _tipo == 'Entrada' ? _categoriasEntrada : _categoriasSaida;

  @override
  void initState() {
    super.initState();
    if (widget.dadosOS != null) {
      final os = widget.dadosOS!;
      _tipo      = 'Entrada';
      _categoria = 'OS / Serviço';
      // Pré-preenche com o saldo RESTANTE, não o total da OS
      final valorParaPreencher = widget.valorRestante ?? (
          ((os['valor_pecas']   as num?)?.toDouble() ?? 0) +
              ((os['valor_servico'] as num?)?.toDouble() ?? 0)
      );
      _valorController.text = valorParaPreencher.toStringAsFixed(2);
      _descController.text  =
      'OS - ${os['cliente_nome'] ?? ''} / ${os['equipamento'] ?? ''}';
      _formaPagamento = os['forma_pagamento'] ?? 'Dinheiro';
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dataSelecionada = picked);
  }

  Future<void> _salvar() async {
    final valorStr = _valorController.text.replaceAll(',', '.');
    final valor    = double.tryParse(valorStr);

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Informe um valor válido.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Impede lançar mais do que o saldo restante
    if (widget.valorRestante != null && valor > widget.valorRestante! + 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Valor maior que o saldo restante (R\$ ${widget.valorRestante!.toStringAsFixed(2)}).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final payload = <String, dynamic>{
        'tipo':            _tipo,
        'categoria':       _categoria,
        'descricao':       _descController.text.trim(),
        'valor':           valor,
        'forma_pagamento': _formaPagamento,
        'data':            Timestamp.fromDate(_dataSelecionada),
        'criado_em':       FieldValue.serverTimestamp(),
      };

      if (widget.osId != null) {
        payload['os_id']       = widget.osId;
        payload['cliente_nome'] = widget.dadosOS?['cliente_nome'] ?? '';

        // Busca o valor já recebido para calcular o novo acumulado
        final osSnap = await FirebaseFirestore.instance
            .collection('ordens')
            .doc(widget.osId)
            .get();
        final dadosOS       = osSnap.data() ?? {};
        final totalOS       = ((dadosOS['valor_pecas']   as num?)?.toDouble() ?? 0) +
            ((dadosOS['valor_servico'] as num?)?.toDouble() ?? 0);
        final jaRecebido    = (dadosOS['valor_recebido'] as num?)?.toDouble() ?? 0;
        final novoRecebido  = jaRecebido + valor;
        final quitado       = novoRecebido >= totalOS - 0.01;

        final updateOS = <String, dynamic>{
          'valor_recebido': novoRecebido,
        };
        if (quitado) {
          updateOS['recebido']         = true;
          updateOS['data_recebimento'] = Timestamp.fromDate(_dataSelecionada);
        }

        await FirebaseFirestore.instance
            .collection('ordens')
            .doc(widget.osId)
            .update(updateOS);
      }

      await FirebaseFirestore.instance.collection('transacoes').add(payload);

      if (!mounted) return;
      Navigator.pop(context);

      final quitadoMsg = widget.osId != null &&
          (widget.valorRestante != null && valor >= widget.valorRestante! - 0.01);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quitadoMsg
              ? 'OS quitada! Recebimento registrado. ✓'
              : 'Parcela de R\$ ${valor.toStringAsFixed(2)} registrada!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF000033);
    final corTipo = _tipo == 'Entrada' ? Colors.greenAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(widget.osId == null
            ? 'Novo Lançamento'
            : (widget.valorRestante != null &&
            widget.dadosOS?['valor_recebido'] != null &&
            (widget.dadosOS!['valor_recebido'] as num) > 0)
            ? 'Nova Parcela'
            : 'Confirmar Recebimento'),
        backgroundColor: bg,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── BANNER DE SALDO (quando é parcela de OS) ──────────
            if (widget.osId != null && widget.valorRestante != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                ),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet,
                      color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo restante da OS',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Text(
                          'R\$ ${widget.valorRestante!.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Text('← teto máximo',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ]),
              ),
            ],

            // ── TIPO: ENTRADA / SAÍDA ──────────────────────────────
            if (widget.osId == null) ...[
              const Text('Tipo de lançamento',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                _botaoTipo('Entrada', Colors.greenAccent),
                const SizedBox(width: 12),
                _botaoTipo('Saída', Colors.redAccent),
              ]),
              const SizedBox(height: 20),
            ],

            // ── VALOR ─────────────────────────────────────────────
            _sectionLabel('Valor (R\$)'),
            TextField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: corTipo, fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(color: corTipo.withOpacity(0.7), fontSize: 22),
                hintText: '0,00',
                hintStyle: TextStyle(color: corTipo.withOpacity(0.3), fontSize: 28),
                filled: true,
                fillColor: corTipo.withOpacity(0.07),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: corTipo.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: corTipo.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: corTipo)),
              ),
            ),
            const SizedBox(height: 20),

            // ── DESCRIÇÃO ─────────────────────────────────────────
            _sectionLabel('Descrição'),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Ex: Troca de tela iPhone 13', Icons.notes),
            ),
            const SizedBox(height: 20),

            // ── CATEGORIA ─────────────────────────────────────────
            _sectionLabel('Categoria'),
            _dropdownField(
              value: _categorias.contains(_categoria) ? _categoria : _categorias.first,
              items: _categorias,
              icon: Icons.category_outlined,
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 16),

            // ── FORMA DE PAGAMENTO ────────────────────────────────
            _sectionLabel('Forma de Pagamento'),
            _dropdownField(
              value: _formaPagamento,
              items: ['Dinheiro', 'PIX', 'Cartão Débito', 'Cartão Crédito', 'Transferência'],
              icon: Icons.credit_card,
              onChanged: (v) => setState(() => _formaPagamento = v!),
            ),
            const SizedBox(height: 16),

            // ── DATA ──────────────────────────────────────────────
            _sectionLabel('Data'),
            InkWell(
              onTap: _selecionarData,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${_dataSelecionada.day.toString().padLeft(2,'0')}/'
                        '${_dataSelecionada.month.toString().padLeft(2,'0')}/'
                        '${_dataSelecionada.year}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar, color: Colors.white38, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 36),

            // ── BOTÃO SALVAR ──────────────────────────────────────
            _salvando
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
              onPressed: _salvar,
              icon: Icon(
                _tipo == 'Entrada' ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
              ),
              label: Text(
                widget.osId != null
                    ? 'CONFIRMAR RECEBIMENTO'
                    : 'SALVAR LANÇAMENTO',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tipo == 'Entrada' ? Colors.green : Colors.redAccent,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _botaoTipo(String tipo, Color cor) {
    final ativo = _tipo == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _tipo = tipo;
          // Ajusta a categoria ao mudar tipo
          final cats = tipo == 'Entrada' ? _categoriasEntrada : _categoriasSaida;
          if (!cats.contains(_categoria)) _categoria = cats.first;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: ativo ? cor.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ativo ? cor : Colors.transparent, width: 2),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(tipo == 'Entrada' ? Icons.arrow_downward : Icons.arrow_upward,
                color: ativo ? cor : Colors.white38, size: 18),
            const SizedBox(width: 6),
            Text(tipo, style: TextStyle(color: ativo ? cor : Colors.white38, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _sectionLabel(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 13)),
  );

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white24),
    prefixIcon: Icon(icon, color: Colors.white38, size: 18),
    filled: true,
    fillColor: Colors.white.withOpacity(0.07),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );

  Widget _dropdownField({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1A1A2E),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          items: items
              .map((e) => DropdownMenuItem(
            value: e,
            child: Row(children: [
              Icon(icon, color: Colors.white38, size: 16),
              const SizedBox(width: 10),
              Text(e, style: const TextStyle(color: Colors.white)),
            ]),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}