import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_constants.dart';
import '../core/shared_widgets.dart';
import 'cadastro_cliente_page.dart';

class ListaClientesPage extends StatefulWidget {
  const ListaClientesPage({super.key});

  @override
  State<ListaClientesPage> createState() => _ListaClientesPageState();
}

class _ListaClientesPageState extends State<ListaClientesPage> {
  String _filtro = '';

  // CORREÇÃO: verificação de mounted antes de usar context pós-await
  Future<void> _excluirCliente(String id, String nome) async {
    final confirmado = await confirmarAcao(
      context,
      titulo: 'Excluir Cliente?',
      mensagem:
      'Deseja excluir $nome? As ordens de serviço não serão apagadas, mas perderão o vínculo.',
      confirmLabel: 'EXCLUIR',
    );
    if (!confirmado || !mounted) return;

    await FirebaseFirestore.instance
        .collection(AppCollections.clientes)
        .doc(id)
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nome excluído.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              onChanged: (val) => setState(() => _filtro = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Pesquisar cliente...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                hintStyle: const TextStyle(color: Colors.white60),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppCollections.clientes)
            .orderBy('nome')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const ErrorState();
          if (!snapshot.hasData) return kLoadingCenter;

          final clientes = snapshot.data!.docs.where((doc) {
            final nome = (doc['nome'] ?? '').toString().toLowerCase();
            return nome.contains(_filtro);
          }).toList();

          if (clientes.isEmpty) {
            return const EmptyState(
              icon: Icons.person_off,
              message: 'Nenhum cliente encontrado.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 80),
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final doc   = clientes[index];
              final dados = doc.data() as Map<String, dynamic>;
              final nome  = dados['nome'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.info,
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(nome,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(dados['telefone'] ?? 'Sem telefone'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Editar',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CadastroClientePage(clienteExistente: doc),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        tooltip: 'Excluir',
                        onPressed: () => _excluirCliente(doc.id, nome),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.info,
        tooltip: 'Novo cliente',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CadastroClientePage()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}