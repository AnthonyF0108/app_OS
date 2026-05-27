import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // NOVO: Para buscar dados do cliente
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfService {
  static Future<void> gerarEEnviarWhatsApp({
    required Map<String, dynamic> os,
    required String telefoneCliente,
  }) async {
    final pdf = pw.Document();

    // Estilos de fonte
    final fontBold = pw.Font.helveticaBold();
    final fontNormal = pw.Font.helvetica();

    // 1. BUSCA DADOS COMPLETOS DO CLIENTE NO FIRESTORE
    Map<String, dynamic> dadosClienteCompleto = {};
    if (os['cliente_id'] != null) {
      try {
        final docCliente = await FirebaseFirestore.instance
            .collection('clientes')
            .doc(os['cliente_id'])
            .get();
        if (docCliente.exists && docCliente.data() != null) {
          dadosClienteCompleto = docCliente.data()!;
        }
      } catch (e) {
        print("Erro ao buscar dados completos do cliente: $e");
      }
    }

    // Extrai as listas específicas do Firebase
    final List<dynamic> pecasDetalhes = os['pecas_detalhes'] ?? [];
    final List<dynamic> servicosDetalhes = os['servicos_detalhes'] ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho Principal
              pw.Text("ORDEM DE SERVIÇO", style: pw.TextStyle(font: fontBold, fontSize: 22)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // --- SEÇÃO: DADOS COMPLETOS DO CLIENTE ---
              pw.Text("DADOS DO CLIENTE", style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blueGrey)),
              pw.SizedBox(height: 4),
              pw.Text("Nome: ${os['cliente_nome'] ?? 'Não informado'}", style: pw.TextStyle(font: fontNormal)),

              // Exibe campos dinâmicos caso existam no seu cadastro de clientes do Firebase:
              if (dadosClienteCompleto['telefone'] != null)
                pw.Text("Telefone: ${dadosClienteCompleto['telefone']}", style: pw.TextStyle(font: fontNormal)),
              if (dadosClienteCompleto['cpf'] != null || dadosClienteCompleto['cnpj'] != null)
                pw.Text("Documento: ${dadosClienteCompleto['cpf'] ?? dadosClienteCompleto['cnpj']}", style: pw.TextStyle(font: fontNormal)),
              if (dadosClienteCompleto['endereco'] != null)
                pw.Text("Endereço: ${dadosClienteCompleto['endereco']}", style: pw.TextStyle(font: fontNormal)),

              pw.SizedBox(height: 10),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),

              // --- SEÇÃO: DETALHES DO EQUIPAMENTO ---
              pw.Text("INFORMAÇÕES DA OS", style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blueGrey)),
              pw.SizedBox(height: 4),
              pw.Text("EQUIPAMENTO: ${os['equipamento'] ?? 'Não informado'}", style: pw.TextStyle(font: fontNormal)),
              pw.Text("STATUS ATUAL: ${os['status'] ?? 'Orçamento'}", style: pw.TextStyle(font: fontNormal)),
              pw.Text("FORMA DE PAGAMENTO: ${os['forma_pagamento'] ?? 'Não definido'}", style: pw.TextStyle(font: fontNormal)),

              pw.SizedBox(height: 10),
              pw.Text("DEFEITO RELATADO:", style: pw.TextStyle(font: fontBold)),
              pw.Text("${os['defeito'] ?? 'Nenhum detalhe informado'}", style: pw.TextStyle(font: fontNormal)),

              pw.SizedBox(height: 15),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // --- SEÇÃO: DESCRIÇÃO DOS SERVIÇOS PRESTADOS ---
              pw.Text("SERVIÇOS REALIZADOS:", style: pw.TextStyle(font: fontBold)),
              pw.SizedBox(height: 5),
              if (servicosDetalhes.isEmpty)
                pw.Text("Nenhum serviço adicionado.", style: pw.TextStyle(font: fontNormal, color: PdfColors.grey))
              else
                pw.Column(
                  children: servicosDetalhes.map((item) {
                    final nomeServico = item['nome'] ?? 'Serviço';
                    final precoServico = item['preco'] ?? 0.0;
                    final descServico = item['descricao'] ?? '';

                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("- $nomeServico", style: pw.TextStyle(font: fontBold, fontSize: 11)),
                              pw.Text("R\$ ${precoServico.toDouble().toStringAsFixed(2)}", style: pw.TextStyle(font: fontNormal)),
                            ],
                          ),
                          if (descServico.toString().isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 10, top: 2),
                              child: pw.Text("Obs: $descServico", style: pw.TextStyle(font: fontNormal, fontSize: 10, color: PdfColors.grey700)),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              pw.SizedBox(height: 15),

              // --- SEÇÃO: PEÇAS UTILIZADAS ---
              pw.Text("PEÇAS UTILIZADAS:", style: pw.TextStyle(font: fontBold)),
              pw.SizedBox(height: 5),
              if (pecasDetalhes.isEmpty)
                pw.Text("Nenhuma peça utilizada.", style: pw.TextStyle(font: fontNormal, color: PdfColors.grey))
              else
                pw.Column(
                  children: pecasDetalhes.map((item) {
                    final nomePeca = item['nome'] ?? 'Peça';
                    final precoPeca = item['preco'] ?? 0.0;
                    final qtd = item['qtd'] ?? 1;
                    final subtotal = precoPeca * qtd;

                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("- ${qtd}x $nomePeca", style: pw.TextStyle(font: fontNormal)),
                          pw.Text("R\$ ${subtotal.toDouble().toStringAsFixed(2)}", style: pw.TextStyle(font: fontNormal)),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 15, color: PdfColors.grey100), // Divisória suave para o bloco financeiro

              // Resumo de Valores
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total Peças: R\$ ${(os['valor_pecas'] ?? 0.0).toDouble().toStringAsFixed(2)}", style: pw.TextStyle(font: fontNormal)),
                  pw.Text("Total Serviços: R\$ ${(os['valor_servico'] ?? 0.0).toDouble().toStringAsFixed(2)}", style: pw.TextStyle(font: fontNormal)),
                ],
              ),

              pw.SizedBox(height: 10),

              // Valor Total Geral
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL GERAL: R\$ ${((os['valor_pecas'] ?? 0) + (os['valor_servico'] ?? 0)).toDouble().toStringAsFixed(2)}",
                  style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green800),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Salva o arquivo temporariamente
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/OS_${os['cliente_nome'] ?? 'Documento'}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Compartilha via WhatsApp/Outros
    await Share.shareXFiles([XFile(file.path)], text: 'Segue a Ordem de Serviço de ${os['cliente_nome']}');
  }
}