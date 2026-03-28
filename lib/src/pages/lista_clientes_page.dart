import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cadastro_cliente_page.dart'; // Importe sua página de cadastro

class ListaClientesPage extends StatefulWidget {
  const ListaClientesPage({super.key});

  @override
  State<ListaClientesPage> createState() => _ListaClientesPageState();
}

class _ListaClientesPageState extends State<ListaClientesPage> {
  String _filtro = "";

  // Função para excluir cliente com aviso
  void _excluirCliente(String id, String nome) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Cliente?"),
        content: Text("Deseja realmente excluir $nome? As ordens de serviço dele não serão apagadas, mas perderão o vínculo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('clientes').doc(id).delete();
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
      appBar: AppBar(
        title: const Text("Meus Clientes"),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (val) => setState(() => _filtro = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Pesquisar cliente...",
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
        stream: FirebaseFirestore.instance.collection('clientes').orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Erro ao carregar"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final clientes = snapshot.data!.docs.where((doc) {
            return doc['nome'].toString().toLowerCase().contains(_filtro);
          }).toList();

          if (clientes.isEmpty) return const Center(child: Text("Nenhum cliente encontrado."));

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final doc = clientes[index];
              final dados = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(dados['nome'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(dados['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(dados['telefone'] ?? "Sem telefone"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BOTÃO EDITAR
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CadastroClientePage(clienteExistente: doc)),
                        ),
                      ),
                      // BOTÃO EXCLUIR
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _excluirCliente(doc.id, dados['nome']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // BOTÃO PARA CRIAR NOVO CLIENTE
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CadastroClientePage()),
        ),
      ),
    );
  }
}