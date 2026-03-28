import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  String _busca = "";

  // Função para abrir o formulário de cadastro/edição de peça
  void _abrirFormulario({QueryDocumentSnapshot? produto}) {
    final nomeController = TextEditingController(text: produto != null ? produto['nome'] : '');
    final quantidadeController = TextEditingController(text: produto != null ? produto['quantidade'].toString() : '');
    final precoController = TextEditingController(text: produto != null ? produto['preco'].toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(produto == null ? "Nova Peça" : "Editar Peça", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Nome da Peça")),
            TextField(controller: quantidadeController, decoration: const InputDecoration(labelText: "Quantidade em Estoque"), keyboardType: TextInputType.number),
            TextField(controller: precoController, decoration: const InputDecoration(labelText: "Preço de Venda (R\$)"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                final dados = {
                  'nome': nomeController.text,
                  'quantidade': int.tryParse(quantidadeController.text) ?? 0,
                  'preco': double.tryParse(precoController.text) ?? 0.0,
                  'ultima_atualizacao': FieldValue.serverTimestamp(),
                };

                if (produto == null) {
                  await FirebaseFirestore.instance.collection('produtos').add(dados);
                } else {
                  await FirebaseFirestore.instance.collection('produtos').doc(produto.id).update(dados);
                }
                Navigator.pop(context);
              },
              child: const Text("SALVAR NO ESTOQUE"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                hintText: "Procurar peça...",
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                hintStyle: const TextStyle(color: Colors.white60),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('produtos').orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final itens = snapshot.data!.docs.where((doc) => doc['nome'].toString().toLowerCase().contains(_busca)).toList();

          return ListView.builder(
            itemCount: itens.length,
            itemBuilder: (context, index) {
              final item = itens[index];
              int qtd = item['quantidade'];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: qtd > 2 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  child: Text(qtd.toString(), style: TextStyle(color: qtd > 2 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                ),
                title: Text(item['nome']),
                subtitle: Text("Preço: R\$ ${item['preco'].toStringAsFixed(2)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_note),
                  onPressed: () => _abrirFormulario(produto: item),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }
}