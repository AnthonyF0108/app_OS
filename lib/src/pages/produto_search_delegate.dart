import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProdutoSearchDelegate extends SearchDelegate<DocumentSnapshot?> {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = "")];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final resultados = snapshot.data!.docs.where((doc) {
          return doc['nome'].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: resultados.length,
          itemBuilder: (context, index) {
            final produto = resultados[index];
            return ListTile(
              title: Text(produto['nome']),
              subtitle: Text("Estoque: ${produto['quantidade']} | R\$ ${produto['preco']}"),
              onTap: () => close(context, produto),
            );
          },
        );
      },
    );
  }
}