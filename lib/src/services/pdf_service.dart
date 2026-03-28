import 'dart:io';
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

    // Extrai a lista de produtos/peças do Firebase
    final List<dynamic> produtosDetalhes = os['produtos_detalhes'] ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Text("ORDEM DE SERVIÇO", style: pw.TextStyle(font: fontBold, fontSize: 22)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // Informações do Cliente e Equipamento
              pw.Text("CLIENTE: ${os['cliente_nome'] ?? 'Não informado'}", style: pw.TextStyle(font: fontNormal)),
              pw.Text("EQUIPAMENTO: ${os['equipamento'] ?? 'Não informado'}", style: pw.TextStyle(font: fontNormal)),
              pw.Text("STATUS: ${os['status'] ?? 'Orçamento'}", style: pw.TextStyle(font: fontNormal)),
              pw.Text("PAGAMENTO: ${os['forma_pagamento'] ?? 'Não definido'}", style: pw.TextStyle(font: fontNormal, color: PdfColors.blueGrey)),

              pw.SizedBox(height: 15),
              pw.Text("DEFEITO RELATADO:", style: pw.TextStyle(font: fontBold)),
              pw.Text("${os['defeito'] ?? 'Nenhum detalhe informado'}", style: pw.TextStyle(font: fontNormal)),

              pw.SizedBox(height: 20),

              // --- SEÇÃO DE PEÇAS UTILIZADAS ---
              pw.Text("PEÇAS UTILIZADAS:", style: pw.TextStyle(font: fontBold)),
              pw.SizedBox(height: 5),
              if (produtosDetalhes.isEmpty)
                pw.Text("Nenhuma peça utilizada.", style: pw.TextStyle(font: fontNormal, color: PdfColors.grey))
              else
                pw.Column(
                  children: produtosDetalhes.map((item) {
                    // Mapeia o nome e preço de cada item da lista
                    final nomePeca = item['nome'] ?? 'Peça';
                    final precoPeca = item['preco'] ?? 0.0;

                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("- $nomePeca", style: pw.TextStyle(font: fontNormal)),
                          pw.Text("R\$ ${precoPeca.toDouble().toStringAsFixed(2)}", style: pw.TextStyle(font: fontNormal)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              // ---------------------------------

              pw.SizedBox(height: 20),
              pw.Divider(),

              // Resumo de Valores
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Subtotal Peças: R\$ ${(os['valor_pecas'] ?? 0.0).toDouble().toStringAsFixed(2)}"),
                  pw.Text("Mão de Obra: R\$ ${(os['valor_servico'] ?? 0.0).toDouble().toStringAsFixed(2)}"),
                ],
              ),

              pw.SizedBox(height: 10),

              // Valor Total
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL: R\$ ${((os['valor_pecas'] ?? 0) + (os['valor_servico'] ?? 0)).toDouble().toStringAsFixed(2)}",
                  style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.green),
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