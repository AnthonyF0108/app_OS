import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class VeiculoPdfService {
  static Future<void> gerarPdf(
      Map<String, dynamic> veiculo,
      ) async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'AF Motors & Serviços',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Marca: ${veiculo['marca']}'),
              pw.Text('Modelo: ${veiculo['modelo']}'),
              pw.Text('Ano: ${veiculo['ano']}'),
              pw.Text(
                'Valor Compra: R\$ ${veiculo['valor_compra']}',
              ),
              pw.Text(
                'Valor Venda: R\$ ${veiculo['valor_venda']}',
              ),
              pw.Text('Status: ${veiculo['status']}'),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();

    final file = File(
      '${dir.path}/veiculo.pdf',
    );

    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path),
    ]);
  }
}