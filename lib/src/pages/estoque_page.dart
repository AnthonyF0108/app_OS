import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  String _busca = "";

  // FUNÇÃO PARA EDITAR PRODUTO
  void _abrirEditorProduto(DocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>;
    final nomeController = TextEditingController(text: dados['nome']);
    final precoController = TextEditingController(text: (dados['preco'] ?? 0.0).toString());
    final eanController = TextEditingController(text: (dados['ean'] ?? "").toString());

    File? novaImagem;
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Editar Produto", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              // SEÇÃO DE FOTO
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                  if (pickedFile != null) setModalState(() => novaImagem = File(pickedFile.path));
                },
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                  child: novaImagem != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(novaImagem!, fit: BoxFit.cover))
                      : (dados['foto_url'] != null && dados['foto_url'] != ""
                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(dados['foto_url'], fit: BoxFit.cover))
                      : const Icon(Icons.camera_alt, color: Colors.blueAccent)),
                ),
              ),
              const SizedBox(height: 10),

              // CAMPOS APENAS LEITURA (CÓDIGO E QTD)
              Row(
                children: [
                  Expanded(child: _buildReadOnlyField("Código", dados['codigo'] ?? "00000")),
                  const SizedBox(width: 10),
                  Expanded(child: _buildReadOnlyField("Qtd Atual", (dados['quantidade'] ?? 0).toString())),
                ],
              ),

              TextField(
                controller: nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Nome do Produto", labelStyle: TextStyle(color: Colors.white70)),
              ),
              TextField(
                controller: eanController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "EAN / Código de Barras", labelStyle: TextStyle(color: Colors.white70)),
              ),
              TextField(
                controller: precoController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Preço de Venda", labelStyle: TextStyle(color: Colors.white70)),
              ),

              const SizedBox(height: 25),
              if (salvando) const CircularProgressIndicator()
              else ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
                onPressed: () async {
                  setModalState(() => salvando = true);
                  try {
                    String fotoUrl = dados['foto_url'] ?? "";

                    // Se tirou foto nova, faz upload
                    if (novaImagem != null) {
                      final ref = FirebaseStorage.instance.ref().child('produtos/${dados['codigo']}.jpg');
                      await ref.putFile(novaImagem!);
                      fotoUrl = await ref.getDownloadURL();
                    }

                    await FirebaseFirestore.instance.collection('produtos').doc(doc.id).update({
                      'nome': nomeController.text,
                      'ean': eanController.text,
                      'preco': double.tryParse(precoController.text) ?? 0.0,
                      'foto_url': fotoUrl,
                    });
                    Navigator.pop(context);
                  } catch (e) {
                    setModalState(() => salvando = false);
                  }
                },
                child: const Text("SALVAR ALTERAÇÕES"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _confirmarExclusao(String id, String nome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Excluir Item", style: TextStyle(color: Colors.white)),
        content: Text("Deseja remover '$nome'?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('produtos').doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
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
        title: const Text("Gestão de Estoque"),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (val) => setState(() => _busca = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Procurar...",
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final itens = snapshot.data!.docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return (d['nome'] ?? "").toString().toLowerCase().contains(_busca);
          }).toList();

          return ListView.builder(
            itemCount: itens.length,
            itemBuilder: (context, index) {
              final item = itens[index];
              final d = item.data() as Map<String, dynamic>;
              num qtd = d['quantidade'] ?? 0;
              num preco = d['preco'] ?? 0.0;

              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                    child: (d['foto_url'] != null && d['foto_url'] != "")
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(d['foto_url'], fit: BoxFit.cover))
                        : const Icon(Icons.inventory_2, color: Colors.white24),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                        child: Text(d['codigo'] ?? "00000", style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d['nome'] ?? "S/N", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Text("R\$ ${preco.toDouble().toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent)),
                      const SizedBox(width: 15),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                        onPressed: () => _abrirEditorProduto(item),
                      ),
                    ],
                  ),
                  trailing: Text(qtd.toString(), style: TextStyle(color: qtd > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                  onLongPress: () => _confirmarExclusao(item.id, d['nome'] ?? "Item"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}