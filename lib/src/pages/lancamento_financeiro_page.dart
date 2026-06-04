import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../core/shared_widgets.dart';

class LancamentoFinanceiroPage extends StatefulWidget {
  final Map<String, dynamic>? dadosOS;
  final String? osId;

  const LancamentoFinanceiroPage({super.key, this.dadosOS, this.osId});

  @override
  State<LancamentoFinanceiroPage> createState() =>
      _LancamentoFinanceiroPageState();
}

class _LancamentoFinanceiroPageState
    extends State<LancamentoFinanceiroPage> {

  String _tipo            = 'Entrada';
  String _categoria       = AppOptions.categoriasEntrada.first;
  String _formaPagamento  = AppOptions.formasPagamento.first;
  DateTime _dataSelecionada = DateTime.now();
  bool _salvando = false;

  final _descController  = TextEditingController();
  final _valorController = TextEditingController();

  @override
  void dispose() {
    _descController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  List<String> get _categorias => _tipo == 'Entrada'
      ? AppOptions.categoriasEntrada
      : AppOptions.categoriasSaida;

  @override
  void initState() {
    super.initState();
    if (widget.dadosOS != null) {
      final os = widget.dadosOS!;
      _tipo      = 'Entrada';
      _categoria = AppOptions.categoriasEntrada.first;
      final total =
          ((os['valor_pecas']   as num?)?.toDouble() ?? 0) +
              ((os['valor_servico'] as num?)?.toDouble() ?? 0);
      _valorController.text = total.toStringAsFixed(2);
      _descController.text  =
      'OS - ${os['cliente_nome'] ?? ''} / ${os['equipamento'] ?? ''}';
      _formaPagamento =
          _normalizeFormaPagamento(os['forma_pagamento']);
    }
  }

  /// Garante que o valor de forma_pagamento salvo na OS existe na lista atual.
  String _normalizeFormaPagamento(dynamic raw) {
    final v = raw?.toString() ?? '';
    return AppOptions.formasPagamento.contains(v)
        ? v
        : AppOptions.formasPagamento.first;
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

        await FirebaseFirestore.instance
            .collection(AppCollections.ordens)
            .doc(widget.osId)
            .update({
          'recebido':         true,
          'data_recebimento': Timestamp.fromDate(_dataSelecionada),
        });
      }

      await FirebaseFirestore.instance
          .collection(AppCollections.transacoes)
          .add(payload);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lançamento de $_tipo registrado!'),
          backgroundColor:
          _tipo == 'Entrada' ? Colors.green : Colors.orange,
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
    final corTipo =
    _tipo == 'Entrada' ? Colors.greenAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: Text(
            widget.osId != null ? 'Confirmar Recebimento' : 'Novo Lançamento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── TIPO: apenas exibido quando NÃO é OS ─────────
            if (widget.osId == null) ...[
              sectionLabel('Tipo de lançamento'),
              Row(children: [
                _botaoTipo('Entrada', Colors.greenAccent),
                const SizedBox(width: 12),
                _botaoTipo('Saída', Colors.redAccent),
              ]),
              const SizedBox(height: 20),
            ],

            // ── VALOR ─────────────────────────────────────────
            sectionLabel('Valor (R\$)'),
            TextField(
              controller: _valorController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  color: corTipo, fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                prefixStyle: TextStyle(
                    color: corTipo.withOpacity(0.7), fontSize: 22),
                hintText: '0,00',
                hintStyle:
                TextStyle(color: corTipo.withOpacity(0.3), fontSize: 28),
                filled: true,
                fillColor: corTipo.withOpacity(0.07),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: corTipo.withOpacity(0.3))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: corTipo.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: corTipo)),
              ),
            ),
            const SizedBox(height: 20),

            // ── DESCRIÇÃO ─────────────────────────────────────
            sectionLabel('Descrição'),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration:
              darkInputDeco('Ex: Troca de tela iPhone 13', icon: Icons.notes),
            ),
            const SizedBox(height: 20),

            // ── CATEGORIA ─────────────────────────────────────
            DarkDropdown(
              label: 'Categoria',
              value: _categorias.contains(_categoria)
                  ? _categoria
                  : _categorias.first,
              items: _categorias,
              icon: Icons.category_outlined,
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 16),

            // ── FORMA DE PAGAMENTO ────────────────────────────
            DarkDropdown(
              label: 'Forma de Pagamento',
              value: _formaPagamento,
              items: AppOptions.formasPagamento,
              icon: Icons.credit_card,
              onChanged: (v) => setState(() => _formaPagamento = v!),
            ),
            const SizedBox(height: 16),

            // ── DATA ──────────────────────────────────────────
            sectionLabel('Data'),
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
                  const Icon(Icons.calendar_today,
                      color: Colors.white54, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${_dataSelecionada.day.toString().padLeft(2, '0')}/'
                        '${_dataSelecionada.month.toString().padLeft(2, '0')}/'
                        '${_dataSelecionada.year}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit_calendar,
                      color: Colors.white38, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 36),

            // ── BOTÃO SALVAR ──────────────────────────────────
            _salvando
                ? kLoadingCenter
                : ElevatedButton.icon(
              onPressed: _salvar,
              icon: Icon(
                _tipo == 'Entrada'
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: Colors.white,
              ),
              label: Text(
                widget.osId != null
                    ? 'CONFIRMAR RECEBIMENTO'
                    : 'SALVAR LANÇAMENTO',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tipo == 'Entrada'
                    ? Colors.green
                    : Colors.redAccent,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
          final cats = tipo == 'Entrada'
              ? AppOptions.categoriasEntrada
              : AppOptions.categoriasSaida;
          if (!cats.contains(_categoria)) _categoria = cats.first;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: ativo
                ? cor.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: ativo ? cor : Colors.transparent, width: 2),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    tipo == 'Entrada'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: ativo ? cor : Colors.white38,
                    size: 18),
                const SizedBox(width: 6),
                Text(tipo,
                    style: TextStyle(
                        color: ativo ? cor : Colors.white38,
                        fontWeight: FontWeight.bold)),
              ]),
        ),
      ),
    );
  }
}