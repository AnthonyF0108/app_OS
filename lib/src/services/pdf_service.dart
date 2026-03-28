import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfService {
  // Método estático para que possa ser chamado como PdfService.gerarEEnviarWhatsApp
  static Future<void> gerarEEnviarWhatsApp({
    required Map<String, dynamic> os,
    required String telefoneCliente,
  }) async {
    final pdf = pw.Document();

    // Estilo básico de fonte
    final fontBold = pw.Font.helveticaBold();
    final fontNormal = pw.Font.helvetica();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("ORDEM DE SERVIÇO", style: pw.TextStyle(font: fontBold, fontSize: 22)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              pw.Text("CLIENTE: ${os['cliente_nome'] ?? 'Não informado'}", style: pw.TextStyle(font: fontNormal)),
              pw.Text("EQUIPAMENTO: ${os['equipamento'] ?? 'Não informado'}", style: pw.TextStyle(font: fontNormal)),
              pw.Text("STATUS: ${os['status'] ?? 'Em Aberto'}", style: pw.TextStyle(font: fontNormal)),
              pw.SizedBox(height: 15),
              pw.Text("DEFEITO RELATADO:", style: pw.TextStyle(font: fontBold)),
              pw.Text("${os['defeito'] ?? 'Nenhum detalhe informado'}", style: pw.TextStyle(font: fontNormal)),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Peças: R\$ ${(os['valor_pecas'] ?? 0.0).toStringAsFixed(2)}"),
                  pw.Text("Mão de Obra: R\$ ${(os['valor_servico'] ?? 0.0).toStringAsFixed(2)}"),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL: R\$ ${((os['valor_pecas'] ?? 0) + (os['valor_servico'] ?? 0)).toStringAsFixed(2)}",
                  style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.green),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Salva em pasta temporária
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/OS_${os['cliente_nome']}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Abre a partilha do arquivo
    await Share.shareXFiles([XFile(file.path)], text: 'Segue a Ordem de Serviço de ${os['cliente_nome']}');
  }
}