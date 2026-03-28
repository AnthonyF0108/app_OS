import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfService {
  static Future<void> gerarEEnviarWhatsApp({
    required Map<String, dynamic> os,
    required String telefoneCliente,
  }) async {
    final pdf = pw.Document();

    // Criando o layout do PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("COMPROVANTE DE ORDEM DE SERVIÇO",
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Cliente: ${os['cliente_nome']}"),
              pw.Text("Equipamento: ${os['equipamento']}"),
              pw.Text("Status Atual: ${os['status']}"),
              pw.SizedBox(height: 15),
              pw.Text("DEFEITO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("${os['defeito']}"),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Peças: R\$ ${os['valor_pecas'].toStringAsFixed(2)}"),
                  pw.Text("Mão de Obra: R\$ ${os['valor_servico'].toStringAsFixed(2)}"),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                "VALOR TOTAL: R\$ ${(os['valor_pecas'] + os['valor_servico']).toStringAsFixed(2)}",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

// 1. Salva o PDF temporário (essa parte continua igual)
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/OS_${os['cliente_nome']}.pdf");
    await file.writeAsBytes(await pdf.save());

    // 2. Formata o número para referência (opcional)
    String numeroLimpo = telefoneCliente.replaceAll(RegExp(r'[^0-9]'), '');

    // 3. Em vez de abrir o link wa.me, vamos direto para o ShareXFiles
    // O ShareXFiles abre o menu do Android onde você clica no ícone do Zap
    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Olá ${os['cliente_nome']}, segue o PDF da sua Ordem de Serviço de ${os['equipamento']}.",
    );

    // 4. Abre o seletor de compartilhamento para enviar o ARQUIVO logo em seguida
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Arquivo PDF da Ordem de Serviço',
    );
  }
}