import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class RelatorioPdfService {
  static Future<void> gerarRelatorio({
    required List<Map<String, dynamic>> transacoes,
    required String mes,
    required int ano,
  }) async {
    final pdf = pw.Document();
    final fontBold   = pw.Font.helveticaBold();
    final fontNormal = pw.Font.helvetica();

    // Totais
    double totalEntradas = 0;
    double totalSaidas   = 0;
    final Map<String, double> porForma    = {};
    final Map<String, double> porCategoria = {};

    for (final t in transacoes) {
      final valor = (t['valor'] as num?)?.toDouble() ?? 0;
      final tipo  = t['tipo']  ?? 'Entrada';
      final forma = t['forma_pagamento'] ?? 'Outros';
      final cat   = t['categoria'] ?? 'Outros';

      if (tipo == 'Entrada') {
        totalEntradas += valor;
        porForma[forma] = (porForma[forma] ?? 0) + valor;
      } else {
        totalSaidas += valor;
      }
      porCategoria[cat] = (porCategoria[cat] ?? 0) + valor;
    }
    double saldo = totalEntradas - totalSaidas;

    // ── GRÁFICO TEXTUAL DE BARRAS ────────────────────────────────
    String _barraTexto(double valor, double maximo, {int largura = 30}) {
      if (maximo == 0) return '';
      int cheios = ((valor / maximo) * largura).round().clamp(0, largura);
      return '█' * cheios + '░' * (largura - cheios);
    }

    double maxForma = porForma.values.isEmpty ? 1 : porForma.values.reduce((a, b) => a > b ? a : b);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [

          // ── CABEÇALHO ──────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#000033'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('RELATÓRIO FINANCEIRO',
                      style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.white)),
                  pw.Text('$mes / $ano',
                      style: pw.TextStyle(font: fontNormal, fontSize: 13, color: PdfColors.blueGrey200)),
                ]),
                pw.Text('AF Motors & Serviços',
                    style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blueAccent)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── CARDS DE RESUMO ────────────────────────────────────
          pw.Row(children: [
            _pdfCard(fontBold, fontNormal, 'ENTRADAS', 'R\$ ${totalEntradas.toStringAsFixed(2)}', PdfColors.green800),
            pw.SizedBox(width: 8),
            _pdfCard(fontBold, fontNormal, 'SAÍDAS',   'R\$ ${totalSaidas.toStringAsFixed(2)}',   PdfColors.red800),
            pw.SizedBox(width: 8),
            _pdfCard(fontBold, fontNormal, 'SALDO',
                'R\$ ${saldo.toStringAsFixed(2)}',
                saldo >= 0 ? PdfColors.blue800 : PdfColors.orange800),
          ]),
          pw.SizedBox(height: 20),

          // ── FORMAS DE PAGAMENTO ────────────────────────────────
          if (porForma.isNotEmpty) ...[
            pw.Text('ENTRADAS POR FORMA DE PAGAMENTO',
                style: pw.TextStyle(font: fontBold, fontSize: 12)),
            pw.SizedBox(height: 8),
            ...porForma.entries.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text(e.key, style: pw.TextStyle(font: fontNormal, fontSize: 10)),
                    pw.Text('R\$ ${e.value.toStringAsFixed(2)}',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.green700)),
                  ]),
                  pw.SizedBox(height: 2),
                  pw.Text(_barraTexto(e.value, maxForma),
                      style: pw.TextStyle(font: fontNormal, fontSize: 8, color: PdfColors.green600)),
                ],
              ),
            )),
            pw.SizedBox(height: 16),
          ],

          // ── POR CATEGORIA ─────────────────────────────────────
          if (porCategoria.isNotEmpty) ...[
            pw.Text('MOVIMENTAÇÃO POR CATEGORIA',
                style: pw.TextStyle(font: fontBold, fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Categoria', fontBold, isHeader: true),
                    _cell('Total (R\$)', fontBold, isHeader: true),
                  ],
                ),
                ...porCategoria.entries.map((e) => pw.TableRow(children: [
                  _cell(e.key, fontNormal),
                  _cell(e.value.toStringAsFixed(2), fontNormal),
                ])),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // ── LISTA DETALHADA ────────────────────────────────────
          pw.Text('LANÇAMENTOS DETALHADOS',
              style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 6),
          if (transacoes.isEmpty)
            pw.Text('Nenhuma transação neste período.',
                style: pw.TextStyle(font: fontNormal, color: PdfColors.grey))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2), // data
                1: const pw.FlexColumnWidth(3),   // descrição
                2: const pw.FlexColumnWidth(2),   // categoria
                3: const pw.FlexColumnWidth(1.5), // forma
                4: const pw.FlexColumnWidth(1.5), // valor
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('Data',       fontBold, isHeader: true),
                    _cell('Descrição',  fontBold, isHeader: true),
                    _cell('Categoria',  fontBold, isHeader: true),
                    _cell('Pagamento',  fontBold, isHeader: true),
                    _cell('Valor',      fontBold, isHeader: true),
                  ],
                ),
                ...transacoes.map((t) {
                  final data  = (t['data'] as Timestamp?)?.toDate();
                  final dataStr = data != null
                      ? '${data.day.toString().padLeft(2,'0')}/${data.month.toString().padLeft(2,'0')}'
                      : '-';
                  final valor = (t['valor'] as num?)?.toDouble() ?? 0;
                  final isEntrada = (t['tipo'] ?? '') == 'Entrada';
                  final valorStr = '${isEntrada ? '+' : '-'} ${valor.toStringAsFixed(2)}';
                  final cor = isEntrada ? PdfColors.green700 : PdfColors.red700;

                  return pw.TableRow(children: [
                    _cell(dataStr,              fontNormal),
                    _cell(t['descricao'] ?? '-', fontNormal),
                    _cell(t['categoria'] ?? '-', fontNormal),
                    _cell(t['forma_pagamento'] ?? '-', fontNormal),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(valorStr,
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: cor)),
                    ),
                  ]);
                }),
              ],
            ),

          pw.SizedBox(height: 20),

          // ── RODAPÉ ────────────────────────────────────────────
          pw.Divider(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('AF Motors & Serviços — Relatório gerado automaticamente',
                style: pw.TextStyle(font: fontNormal, fontSize: 8, color: PdfColors.grey)),
            pw.Text('Saldo: R\$ ${saldo.toStringAsFixed(2)}',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 10,
                    color: saldo >= 0 ? PdfColors.green700 : PdfColors.red700)),
          ]),
        ],
      ),
    );

    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/Relatorio_${mes}_$ano.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório Financeiro — $mes/$ano');
  }

  static pw.Widget _pdfCard(pw.Font bold, pw.Font normal, String label, String valor, PdfColor cor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: cor,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white)),
          pw.SizedBox(height: 4),
          pw.Text(valor, style: pw.TextStyle(font: bold, fontSize: 13, color: PdfColors.white)),
        ]),
      ),
    );
  }

  static pw.Widget _cell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 9 : 8,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
      ),
    );
  }
}
