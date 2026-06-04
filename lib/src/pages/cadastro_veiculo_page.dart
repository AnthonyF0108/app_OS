import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../core/shared_widgets.dart';

class CadastroVeiculoPage extends StatefulWidget {
  // Permite edição ao passar um documento existente
  final QueryDocumentSnapshot? veiculoExistente;

  const CadastroVeiculoPage({super.key, this.veiculoExistente});

  @override
  State<CadastroVeiculoPage> createState() => _CadastroVeiculoPageState();
}

class _CadastroVeiculoPageState extends State<CadastroVeiculoPage> {

  final _formKey       = GlobalKey<FormState>();
  final marcaCtrl      = TextEditingController();
  final modeloCtrl     = TextEditingController();
  final anoCtrl        = TextEditingController();
  final placaCtrl      = TextEditingController();
  final compraCtrl     = TextEditingController();
  final vendaCtrl      = TextEditingController();
  final obsCtrl        = TextEditingController();

  String _status = AppOptions.statusVeiculo.first;
  bool   _salvando = false;

  bool get _modoEdicao => widget.veiculoExistente != null;

  @override
  void initState() {
    super.initState();
    if (_modoEdicao) {
      final d = widget.veiculoExistente!.data() as Map<String, dynamic>;
      marcaCtrl.text  = d['marca']  ?? '';
      modeloCtrl.text = d['modelo'] ?? '';
      anoCtrl.text    = d['ano']    ?? '';
      placaCtrl.text  = d['placa']  ?? '';
      compraCtrl.text =
          (d['valor_compra'] as num?)?.toStringAsFixed(2) ?? '';
      vendaCtrl.text  =
          (d['valor_venda'] as num?)?.toStringAsFixed(2) ?? '';
      obsCtrl.text    = d['observacoes'] ?? '';
      final s = d['status'] ?? AppOptions.statusVeiculo.first;
      _status = AppOptions.statusVeiculo.contains(s) ? s : AppOptions.statusVeiculo.first;
    }
  }

  @override
  void dispose() {
    marcaCtrl.dispose();
    modeloCtrl.dispose();
    anoCtrl.dispose();
    placaCtrl.dispose();
    compraCtrl.dispose();
    vendaCtrl.dispose();
    obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);

    final payload = <String, dynamic>{
      'marca':        marcaCtrl.text.trim(),
      'modelo':       modeloCtrl.text.trim(),
      'ano':          anoCtrl.text.trim(),
      'placa':        placaCtrl.text.trim().toUpperCase(),
      'valor_compra': double.tryParse(compraCtrl.text.replaceAll(',', '.')) ?? 0,
      'valor_venda':  double.tryParse(vendaCtrl.text.replaceAll(',', '.')) ?? 0,
      'observacoes':  obsCtrl.text.trim(),
      'status':       _status,
      'ultima_atualizacao': FieldValue.serverTimestamp(),
    };

    try {
      if (_modoEdicao) {
        await FirebaseFirestore.instance
            .collection(AppCollections.veiculos)
            .doc(widget.veiculoExistente!.id)
            .update(payload);
      } else {
        payload['data'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection(AppCollections.veiculos)
            .add(payload);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_modoEdicao
            ? 'Veículo atualizado!'
            : 'Veículo salvo com sucesso!'),
        backgroundColor: Colors.green,
      ));
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
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: Text(_modoEdicao ? 'Editar Veículo' : 'Novo Veículo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _campo('Marca',  marcaCtrl,  Icons.branding_watermark),
            _campo('Modelo', modeloCtrl, Icons.directions_car),
            _campo('Ano',    anoCtrl,    Icons.calendar_today,
                tipo: TextInputType.number),
            _campo('Placa',  placaCtrl,  Icons.pin),
            _campo('Valor de Compra (R\$)', compraCtrl, Icons.arrow_downward,
                tipo: TextInputType.numberWithOptions(decimal: true),
                obrigatorio: false),
            _campo('Valor de Venda (R\$)',  vendaCtrl,  Icons.arrow_upward,
                tipo: TextInputType.numberWithOptions(decimal: true),
                obrigatorio: false),

            const SizedBox(height: 15),

            // Status
            DropdownButtonFormField<String>(
              value: _status,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              decoration: _decFiled('Status', Icons.info_outline),
              items: AppOptions.statusVeiculo
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),

            const SizedBox(height: 15),

            // Observações (sem validação obrigatória)
            TextFormField(
              controller: obsCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _decFiled('Observações', Icons.notes),
            ),

            const SizedBox(height: 25),

            _salvando
                ? kLoadingCenter
                : SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _modoEdicao
                      ? Colors.orange
                      : Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _salvar,
                icon: Icon(
                    _modoEdicao ? Icons.update : Icons.save,
                    color: Colors.white),
                label: Text(
                  _modoEdicao
                      ? 'ATUALIZAR VEÍCULO'
                      : 'SALVAR VEÍCULO',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
      String label,
      TextEditingController ctrl,
      IconData icon, {
        TextInputType tipo = TextInputType.text,
        bool obrigatorio   = true,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        keyboardType: tipo,
        style: const TextStyle(color: Colors.white),
        decoration: _decFiled(label, icon),
        validator: obrigatorio
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
            : null,
      ),
    );
  }

  InputDecoration _decFiled(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: Colors.white38, size: 18),
    filled: true,
    fillColor: Colors.white10,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.blueAccent),
    ),
  );
}