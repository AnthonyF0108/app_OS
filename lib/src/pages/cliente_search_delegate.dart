import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClienteSearchDelegate extends SearchDelegate<DocumentSnapshot?> {
  // Configurações visuais da barra de pesquisa
  @override
  String get searchFieldLabel => 'Buscar cliente por nome...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000033),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Botões de ação do lado direito (limpar pesquisa)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; // Limpa o texto digitado
        },
      ),
    ];
  }

  // Botão de voltar do lado esquerdo
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Fecha sem retornar nenhum cliente
      },
    );
  }

  // Mostra os resultados reais baseados no que foi digitado
  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsOrSuggestions();
  }

  // Mostra sugestões enquanto o usuário digita (neste caso, é o mesmo que buildResults)
  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsOrSuggestions();
  }

  // Função auxiliar que lê o Firestore e filtra
  Widget _buildResultsOrSuggestions() {
    if (query.isEmpty) {
      return const Center(child: Text('Digite o nome do cliente para pesquisar.'));
    }

    // Normaliza a query para buscar ignorando maiúsculas/minúsculas básico
    // O Firestore é limitado em buscas de texto, isso funciona para buscas simples de início
    String capitalizedQuery = query.isNotEmpty
        ? query[0].toUpperCase() + query.substring(1)
        : '';

    return StreamBuilder<QuerySnapshot>(
      // Busca clientes onde o nome começa com o texto digitado
      stream: FirebaseFirestore.instance
          .collection('clientes')
          .where('nome', isGreaterThanOrEqualTo: capitalizedQuery)
          .where('nome', isLessThanOrEqualTo: capitalizedQuery + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Erro ao buscar.'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final clientes = snapshot.data!.docs;

        if (clientes.isEmpty) {
          return const Center(child: Text('Nenhum cliente encontrado.'));
        }

        return ListView.builder(
          itemCount: clientes.length,
          itemBuilder: (context, index) {
            var clienteDoc = clientes[index];
            var dados = clienteDoc.data() as Map<String, dynamic>;

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(dados['nome'] ?? 'Sem Nome'),
              subtitle: Text("CPF: ${dados['cpf'] ?? ''}"),
              onTap: () {
                // Ao clicar, fecha a pesquisa e retorna o documento inteiro do cliente
                close(context, clienteDoc);
              },
            );
          },
        );
      },
    );
  }
}