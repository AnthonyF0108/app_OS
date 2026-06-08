import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easy_mask/easy_mask.dart'; // Pacote para máscaras

class CadastroClientePage extends StatefulWidget {
  // Se receber este parâmetro, entra em modo de edição
  final QueryDocumentSnapshot? clienteExistente;

  const CadastroClientePage({super.key, this.clienteExistente});

  @override
  State<CadastroClientePage> createState() => _CadastroClientePageState();
}

class _CadastroClientePageState extends State<CadastroClientePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nomeController = TextEditingController();
  final cpfController = TextEditingController();
  final nascimentoController = TextEditingController();
  final telController = TextEditingController();
  final emailController = TextEditingController();
  final cepController = TextEditingController();
  final ruaController = TextEditingController();
  final numController = TextEditingController();
  final bairroController = TextEditingController();
  final cidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.clienteExistente != null) {
      final dados = widget.clienteExistente!.data() as Map<String, dynamic>;
      nomeController.text = dados['nome'] ?? '';
      cpfController.text = dados['cpf'] ?? '';
      nascimentoController.text = dados['nascimento'] ?? '';
      telController.text = dados['telefone'] ?? '';
      emailController.text = dados['email'] ?? '';
      cepController.text = dados['cep'] ?? '';
      ruaController.text = dados['endereco'] ?? '';
      numController.text = dados['numero'] ?? '';
      bairroController.text = dados['bairro'] ?? '';
      cidadeController.text = dados['cidade'] ?? '';
    }
  }

  bool isCpfValido(String cpf) {
    final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpf)) return false;
    List<int> digits = cleanCpf.split('').map((d) => int.parse(d)).toList();
    int temp1 = 0;
    for (int i = 0; i < 9; i++) temp1 += digits[i] * (10 - i);
    int res1 = (temp1 * 10) % 11;
    if (res1 == 10) res1 = 0;
    if (res1 != digits[9]) return false;
    int temp2 = 0;
    for (int i = 0; i < 10; i++) temp2 += digits[i] * (11 - i);
    int res2 = (temp2 * 10) % 11;
    if (res2 == 10) res2 = 0;
    if (res2 != digits[10]) return false;
    return true;
  }

  Future<void> buscarCEP(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return;

    final url = Uri.parse('https://viacep.com.br/ws/$cleanCep/json/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final dados = json.decode(response.body);
        if (dados['erro'] == null) {
          setState(() {
            ruaController.text = dados['logradouro'] ?? '';
            bairroController.text = dados['bairro'] ?? '';
            cidadeController.text = dados['localidade'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Erro CEP: $e");
    }
  }

  void salvarCliente() async {
    if (_formKey.currentState!.validate()) {
      final dadosParaSalvar = {
        'nome': nomeController.text,
        'cpf': cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'nascimento': nascimentoController.text,
        'telefone': telController.text,
        'email': emailController.text,
        'cep': cepController.text,
        'endereco': ruaController.text,
        'numero': numController.text,
        'bairro': bairroController.text,
        'cidade': cidadeController.text,
        'ultima_atualizacao': FieldValue.serverTimestamp(),
      };

      try {
        if (widget.clienteExistente != null) {
          await FirebaseFirestore.instance
              .collection('clientes')
              .doc(widget.clienteExistente!.id)
              .update(dadosParaSalvar);
        } else {
          dadosParaSalvar['data_cadastro'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('clientes').add(dadosParaSalvar);
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.clienteExistente != null ? 'Cliente Atualizado!' : 'Cliente Cadastrado!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool modoEdicao = widget.clienteExistente != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(modoEdicao ? 'Editar Cliente' : 'Cadastrar Cliente'),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField(nomeController, 'Nome Completo', Icons.person),

              TextFormField(
                controller: cpfController,
                inputFormatters: [TextInputMask(mask: '999.999.999-99')],
                decoration: const InputDecoration(labelText: 'CPF', icon: Icon(Icons.badge)),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Obrigatório';
                  if (!isCpfValido(val)) return 'CPF Inválido';
                  return null;
                },
              ),

              TextFormField(
                controller: telController,
                inputFormatters: [TextInputMask(mask: '(99) 99999-9999')],
                decoration: const InputDecoration(labelText: 'Telefone', icon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),

              TextFormField(
                controller: nascimentoController,
                inputFormatters: [TextInputMask(mask: '99/99/9999')],
                decoration: const InputDecoration(labelText: 'Nascimento', icon: Icon(Icons.cake)),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),

              _buildField(emailController, 'Email', Icons.email, keyboard: TextInputType.emailAddress),

              TextFormField(
                controller: cepController,
                inputFormatters: [TextInputMask(mask: '99999-999')],
                decoration: const InputDecoration(labelText: 'CEP', icon: Icon(Icons.location_on)),
                keyboardType: TextInputType.number,
                onChanged: (valor) {
                  if (valor.length >= 8) buscarCEP(valor);
                },
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),

              _buildField(ruaController, 'Endereço (Rua/Av)', Icons.map),
              _buildField(numController, 'Número', Icons.home, keyboard: TextInputType.number),
              _buildField(bairroController, 'Bairro', Icons.location_city),
              _buildField(cidadeController, 'Cidade', Icons.reorder),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: salvarCliente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: modoEdicao ? Colors.orange : Colors.blue,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  modoEdicao ? 'ATUALIZAR DADOS' : 'SALVAR CLIENTE',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, icon: Icon(icon)),
        keyboardType: keyboard,
        validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
      ),
    );
  }
}