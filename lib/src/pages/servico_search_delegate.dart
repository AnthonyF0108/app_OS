import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServicoSearchDelegate extends SearchDelegate<DocumentSnapshot?> {
  @override
  String get searchFieldLabel => 'Buscar serviço...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = "")];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('servicos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final resultados = snapshot.data!.docs.where((doc) {
          final nome = (doc['nome'] ?? '').toString().toLowerCase();
          final desc = (doc['descricao'] ?? '').toString().toLowerCase();
          return nome.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
        }).toList();

        if (resultados.isEmpty) {
          return const Center(
            child: Text('Nenhum serviço encontrado.', style: TextStyle(color: Colors.white54)),
          );
        }

        return ListView.builder(
          itemCount: resultados.length,
          itemBuilder: (context, index) {
            final servico = resultados[index];
            final dados = servico.data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.miscellaneous_services, color: Colors.white, size: 18),
              ),
              title: Text(dados['nome'] ?? 'Sem nome'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((dados['descricao'] ?? '').toString().isNotEmpty)
                    Text(dados['descricao'], style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  Text(
                    "R\$ ${(dados['preco'] as num?)?.toStringAsFixed(2) ?? '0.00'}",
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              onTap: () => close(context, servico),
            );
          },
        );
      },
    );
  }
}