import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'produto_search_delegate.dart';

class EntradaEstoquePage extends StatefulWidget {
  const EntradaEstoquePage({super.key});

  @override
  State<EntradaEstoquePage> createState() => _EntradaEstoquePageState();
}

class _EntradaEstoquePageState extends State<EntradaEstoquePage> {
  final _qtdController = TextEditingController();
  DocumentSnapshot? _produtoSelecionado;
  bool _processandoEntrada = false;

  Future<String> _gerarNovoCodigo() async {
    final snapshot = await FirebaseFirestore.instance.collection('produtos').get();
    if (snapshot.docs.isEmpty) return "00001";
    List<int> codigos = snapshot.docs
        .map((doc) => int.tryParse(doc.data()['codigo']?.toString() ?? "0") ?? 0)
        .toList();
    codigos.sort();
    return (codigos.last + 1).toString().padLeft(5, '0');
  }

  void _confirmarEntrada() async {
    if (_produtoSelecionado == null || _qtdController.text.isEmpty) return;
    setState(() => _processandoEntrada = true);
    await FirebaseFirestore.instance.collection('produtos').doc(_produtoSelecionado!.id).update({
      'quantidade': FieldValue.increment(int.parse(_qtdController.text)),
      'ultima_entrada': FieldValue.serverTimestamp(),
    });
    setState(() {
      _produtoSelecionado = null;
      _qtdController.clear();
      _processandoEntrada = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Estoque Atualizado!")));
  }

  void _abrirCadastroNovo() {
    final nomeCtrl = TextEditingController();
    final precoCtrl = TextEditingController();
    final eanCtrl = TextEditingController(); // Controlador do EAN já estava aqui
    File? imagemArquivo;
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Novo Cadastro", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 50);
                  if (picked != null) setModalState(() => imagemArquivo = File(picked.path));
                },
                child: Container(
                  width: double.infinity, height: 100,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                  child: imagemArquivo != null ? Image.file(imagemArquivo!, fit: BoxFit.cover) : const Icon(Icons.camera_alt, color: Colors.white54),
                ),
              ),
              TextField(controller: nomeCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nome", labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: precoCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Preço", labelStyle: TextStyle(color: Colors.white70))),
              TextField(controller: eanCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Código de Barras (EAN)", labelStyle: TextStyle(color: Colors.white70))),
              const SizedBox(height: 20),
              if (salvando) const CircularProgressIndicator()
              else ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                onPressed: () async {
                  if (nomeCtrl.text.isEmpty) return; // Evita salvar sem nome

                  setModalState(() => salvando = true);

                  try {
                    String code = await _gerarNovoCodigo();
                    String url = "";

                    if (imagemArquivo != null) {
                      final ref = FirebaseStorage.instance.ref().child('produtos/$code.jpg');
                      await ref.putFile(imagemArquivo!);
                      url = await ref.getDownloadURL();
                    }

                    // ADICIONADO O CAMPO 'ean' NO MAPA DO FIREBASE
                    await FirebaseFirestore.instance.collection('produtos').add({
                      'codigo': code,
                      'nome': nomeCtrl.text,
                      'preco': double.tryParse(precoCtrl.text) ?? 0.0,
                      'ean': eanCtrl.text, // <--- Salvando o EAN aqui
                      'quantidade': 0,
                      'foto_url': url,
                      'ultima_entrada': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produto cadastrado com sucesso!"), backgroundColor: Colors.green));
                  } catch (e) {
                    setModalState(() => salvando = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red));
                  }
                },
                child: const Text("SALVAR NOVO PRODUTO", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonAcao(String titulo, String sub, IconData icone, Color cor, VoidCallback clique) {
    return InkWell(
      onTap: clique,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: cor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(icone, size: 40, color: cor),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(sub, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      appBar: AppBar(title: const Text("Entrada de Estoque"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildBotonAcao("Novo Cadastro", "Registrar item novo", Icons.add_box, Colors.orange, _abrirCadastroNovo),
            const SizedBox(height: 30),
            ListTile(
              tileColor: Colors.white10,
              title: Text(_produtoSelecionado == null ? "Buscar Produto..." : _produtoSelecionado!['nome'], style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.search, color: Colors.blue),
              onTap: () async {
                final res = await showSearch(context: context, delegate: ProdutoSearchDelegate());
                if (res != null) setState(() => _produtoSelecionado = res as DocumentSnapshot);
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _qtdController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Quantidade", labelStyle: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _confirmarEntrada, child: const Text("CONFIRMAR ENTRADA")),
          ],
        ),
      ),
    );
  }
}