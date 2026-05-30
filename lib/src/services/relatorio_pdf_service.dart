import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
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

    // ── LOGO ─────────────────────────────────────────────
    pw.ImageProvider? logoImage;

    try {

      final logoBytes =
      await rootBundle.load('assets/logo.png');

      logoImage = pw.MemoryImage(
        logoBytes.buffer.asUint8List(),
      );

    } catch (_) {}

    // ── CORES ───────────────────────────────────────────
    const corEscura = PdfColor.fromInt(0xFF000033);
    const corAzul   = PdfColor.fromInt(0xFF1565C0);

    // ── TOTAIS ──────────────────────────────────────────
    double totalEntradas = 0;
    double totalSaidas   = 0;

    final Map<String, double> porCategoria = {};

    for (final t in transacoes) {

      final valor =
          (t['valor'] as num?)?.toDouble() ?? 0;

      final tipo =
          t['tipo'] ?? 'Entrada';

      final categoria =
          t['categoria'] ?? 'Outros';

      if (tipo == 'Entrada') {
        totalEntradas += valor;
      } else {
        totalSaidas += valor;
      }

      porCategoria[categoria] =
          (porCategoria[categoria] ?? 0) + valor;
    }

    final saldo =
        totalEntradas - totalSaidas;

    // ── CABEÇALHO ───────────────────────────────────────
    pw.Widget cabecalho() {

      return pw.Container(

        width: double.infinity,

        padding: const pw.EdgeInsets.all(14),

        decoration: pw.BoxDecoration(
          color: corEscura,

          borderRadius:
          pw.BorderRadius.circular(8),
        ),

        child: pw.Row(

          crossAxisAlignment:
          pw.CrossAxisAlignment.center,

          children: [

            // LOGO
            if (logoImage != null)
              pw.Container(
                width: 60,
                height: 60,

                child: pw.Image(
                  logoImage,
                  fit: pw.BoxFit.contain,
                ),
              ),

            if (logoImage != null)
              pw.SizedBox(width: 14),

            // TEXTOS
            pw.Expanded(
              child: pw.Column(

                crossAxisAlignment:
                pw.CrossAxisAlignment.start,

                children: [

                  pw.Text(
                    'AF Motors & Serviços',

                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.white,
                    ),
                  ),

                  pw.SizedBox(height: 3),

                  pw.Text(
                    'Relatório Financeiro',

                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 11,
                      color: PdfColors.blueGrey200,
                    ),
                  ),
                ],
              ),
            ),

            // BADGE
            pw.Container(

              padding:
              const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),

              decoration: pw.BoxDecoration(
                color: corAzul,

                borderRadius:
                pw.BorderRadius.circular(6),
              ),

              child: pw.Column(

                children: [

                  pw.Text(
                    'PERÍODO',

                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 8,
                      color: PdfColors.blueGrey100,
                    ),
                  ),

                  pw.SizedBox(height: 2),

                  pw.Text(
                    '$mes/$ano',

                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── GRÁFICO DE BARRAS ──────────────────────────────
    pw.Widget graficoResumo() {

      final maxValor =
      totalEntradas > totalSaidas
          ? totalEntradas
          : totalSaidas;

      double altura(double valor) {

        if (maxValor == 0) return 0;

        return (valor / maxValor) * 120;
      }

      return pw.Container(

        padding: const pw.EdgeInsets.all(16),

        decoration: pw.BoxDecoration(

          border: pw.Border.all(
            color: PdfColors.grey300,
          ),

          borderRadius:
          pw.BorderRadius.circular(8),
        ),

        child: pw.Column(

          crossAxisAlignment:
          pw.CrossAxisAlignment.start,

          children: [

            pw.Text(
              'RESUMO FINANCEIRO',

              style: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Row(

              mainAxisAlignment:
              pw.MainAxisAlignment.spaceEvenly,

              crossAxisAlignment:
              pw.CrossAxisAlignment.end,

              children: [

                // ENTRADAS
                pw.Column(

                  children: [

                    pw.Text(
                      'R\$ ${totalEntradas.toStringAsFixed(2)}',

                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        color: PdfColors.green700,
                      ),
                    ),

                    pw.SizedBox(height: 6),

                    pw.Container(
                      width: 50,
                      height:
                      altura(totalEntradas),

                      decoration: pw.BoxDecoration(
                        color: PdfColors.green600,

                        borderRadius:
                        pw.BorderRadius.circular(4),
                      ),
                    ),

                    pw.SizedBox(height: 6),

                    pw.Text(
                      'Entradas',

                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),

                // SAIDAS
                pw.Column(

                  children: [

                    pw.Text(
                      'R\$ ${totalSaidas.toStringAsFixed(2)}',

                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        color: PdfColors.red700,
                      ),
                    ),

                    pw.SizedBox(height: 6),

                    pw.Container(
                      width: 50,
                      height:
                      altura(totalSaidas),

                      decoration: pw.BoxDecoration(
                        color: PdfColors.red600,

                        borderRadius:
                        pw.BorderRadius.circular(4),
                      ),
                    ),

                    pw.SizedBox(height: 6),

                    pw.Text(
                      'Saídas',

                      style: pw.TextStyle(
                        font: fontNormal,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ── GRÁFICO CATEGORIAS ─────────────────────────────
    pw.Widget graficoCategorias() {

      final maxCategoria =
      porCategoria.values.isEmpty
          ? 1
          : porCategoria.values.reduce(
            (a, b) => a > b ? a : b,
      );

      return pw.Container(

        padding: const pw.EdgeInsets.all(16),

        decoration: pw.BoxDecoration(

          border: pw.Border.all(
            color: PdfColors.grey300,
          ),

          borderRadius:
          pw.BorderRadius.circular(8),
        ),

        child: pw.Column(

          crossAxisAlignment:
          pw.CrossAxisAlignment.start,

          children: [

            pw.Text(
              'MOVIMENTAÇÃO POR CATEGORIA',

              style: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
              ),
            ),

            pw.SizedBox(height: 16),

            ...porCategoria.entries.map((e) {

              final largura =
                  (e.value / maxCategoria) * 220;

              return pw.Padding(

                padding:
                const pw.EdgeInsets.only(
                  bottom: 12,
                ),

                child: pw.Column(

                  crossAxisAlignment:
                  pw.CrossAxisAlignment.start,

                  children: [

                    pw.Row(

                      mainAxisAlignment:
                      pw.MainAxisAlignment
                          .spaceBetween,

                      children: [

                        pw.Text(
                          e.key,

                          style: pw.TextStyle(
                            font: fontNormal,
                            fontSize: 10,
                          ),
                        ),

                        pw.Text(
                          'R\$ ${e.value.toStringAsFixed(2)}',

                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 4),

                    pw.Stack(

                      children: [

                        // FUNDO
                        pw.Container(

                          height: 12,

                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey300,

                            borderRadius:
                            pw.BorderRadius.circular(10),
                          ),
                        ),

                        // BARRA
                        pw.Container(

                          width: largura,
                          height: 12,

                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue600,

                            borderRadius:
                            pw.BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    }

    // ── PDF ─────────────────────────────────────────────
    pdf.addPage(

      pw.MultiPage(

        pageFormat: PdfPageFormat.a4,

        margin:
        const pw.EdgeInsets.all(32),

        footer: (context) {

          return pw.Column(

            children: [

              pw.Divider(
                color: PdfColors.grey300,
              ),

              pw.Row(

                mainAxisAlignment:
                pw.MainAxisAlignment
                    .spaceBetween,

                children: [

                  pw.Text(
                    'AF Motors & Serviços',

                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 8,
                      color: PdfColors.grey,
                    ),
                  ),

                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',

                    style: pw.TextStyle(
                      font: fontNormal,
                      fontSize: 8,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          );
        },

        build: (context) => [

          // CABEÇALHO
          cabecalho(),

          pw.SizedBox(height: 20),

          // GRAFICO 1
          graficoResumo(),

          pw.SizedBox(height: 20),

          // GRAFICO 2
          graficoCategorias(),

          pw.SizedBox(height: 20),

          // CARDS
          pw.Row(

            children: [

              _pdfCard(
                fontBold,
                'ENTRADAS',
                'R\$ ${totalEntradas.toStringAsFixed(2)}',
                PdfColors.green800,
              ),

              pw.SizedBox(width: 8),

              _pdfCard(
                fontBold,
                'SAÍDAS',
                'R\$ ${totalSaidas.toStringAsFixed(2)}',
                PdfColors.red800,
              ),

              pw.SizedBox(width: 8),

              _pdfCard(
                fontBold,
                'SALDO',
                'R\$ ${saldo.toStringAsFixed(2)}',

                saldo >= 0
                    ? PdfColors.blue800
                    : PdfColors.orange800,
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // TABELA
          pw.Text(
            'LANÇAMENTOS',

            style: pw.TextStyle(
              font: fontBold,
              fontSize: 12,
            ),
          ),

          pw.SizedBox(height: 8),

          pw.Table(

            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),

            children: [

              pw.TableRow(

                decoration:
                const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),

                children: [

                  _cell(
                    'Descrição',
                    fontBold,
                    true,
                  ),

                  _cell(
                    'Categoria',
                    fontBold,
                    true,
                  ),

                  _cell(
                    'Valor',
                    fontBold,
                    true,
                  ),
                ],
              ),

              ...transacoes.map((t) {

                final valor =
                    (t['valor'] as num?)
                        ?.toDouble() ?? 0;

                return pw.TableRow(

                  children: [

                    _cell(
                      t['descricao'] ?? '-',
                      fontNormal,
                      false,
                    ),

                    _cell(
                      t['categoria'] ?? '-',
                      fontNormal,
                      false,
                    ),

                    _cell(
                      'R\$ ${valor.toStringAsFixed(2)}',
                      fontNormal,
                      false,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    // ── SALVAR ──────────────────────────────────────────
    final dir =
    await getTemporaryDirectory();

    final file = File(
      '${dir.path}/Relatorio_$mes$ano.pdf',
    );

    await file.writeAsBytes(
      await pdf.save(),
    );

    // ── COMPARTILHAR ───────────────────────────────────
    await Share.shareXFiles(
      [XFile(file.path)],

      text:
      'Relatório Financeiro - $mes/$ano',
    );
  }

  // ── CARD ─────────────────────────────────────────────
  static pw.Widget _pdfCard(
      pw.Font font,
      String titulo,
      String valor,
      PdfColor cor,
      ) {

    return pw.Expanded(

      child: pw.Container(

        padding:
        const pw.EdgeInsets.all(12),

        decoration: pw.BoxDecoration(
          color: cor,

          borderRadius:
          pw.BorderRadius.circular(6),
        ),

        child: pw.Column(

          crossAxisAlignment:
          pw.CrossAxisAlignment.start,

          children: [

            pw.Text(
              titulo,

              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: PdfColors.white,
              ),
            ),

            pw.SizedBox(height: 5),

            pw.Text(
              valor,

              style: pw.TextStyle(
                font: font,
                fontSize: 13,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CELL ─────────────────────────────────────────────
  static pw.Widget _cell(
      String texto,
      pw.Font font,
      bool header,
      ) {

    return pw.Padding(

      padding:
      const pw.EdgeInsets.all(5),

      child: pw.Text(

        texto,

        style: pw.TextStyle(

          font: font,

          fontSize:
          header ? 9 : 8,

          color:
          header
              ? PdfColors.grey800
              : PdfColors.black,
        ),
      ),
    );
  }
}