import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
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

    final fontBold   = pw.Font.helveticaBold();
    final fontNormal = pw.Font.helvetica();

    // ── LOGO ──────────────────────────────────────────────────────────────
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // ── DADOS DO CLIENTE ──────────────────────────────────────────────────
    Map<String, dynamic> cliente = {};
    if (os['cliente_id'] != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('clientes')
            .doc(os['cliente_id'])
            .get();
        if (doc.exists && doc.data() != null) cliente = doc.data()!;
      } catch (_) {}
    }

    final List<dynamic> pecas    = os['pecas_detalhes']    ?? [];
    final List<dynamic> servicos = os['servicos_detalhes'] ?? [];
    final String numeroOS        = os['numero_os']         ?? '';
    final double totalPecas      = (os['valor_pecas']   as num?)?.toDouble() ?? 0;
    final double totalServicos   = (os['valor_servico'] as num?)?.toDouble() ?? 0;
    final double totalGeral      = totalPecas + totalServicos;

    const corEscura = PdfColor.fromInt(0xFF000033);
    const corAzul   = PdfColor.fromInt(0xFF1565C0);
    const corCinza  = PdfColors.grey200;

    // ── CABEÇALHO (repetido em todas as páginas) ───────────────────────────
    pw.Widget cabecalho() => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: corEscura,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoImage != null)
            pw.Container(
              width: 60, height: 60,
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
          if (logoImage != null) pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('AF Motors & Serviços',
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 18, color: PdfColors.white)),
                pw.SizedBox(height: 3),
                pw.Text('Ordem de Serviço',
                    style: pw.TextStyle(
                        font: fontNormal, fontSize: 11,
                        color: PdfColors.blueGrey200)),
              ],
            ),
          ),
          if (numeroOS.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: corAzul,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Nº OS',
                      style: pw.TextStyle(
                          font: fontNormal, fontSize: 8,
                          color: PdfColors.blueGrey100)),
                  pw.SizedBox(height: 2),
                  pw.Text(numeroOS,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 12,
                          color: PdfColors.white)),
                ],
              ),
            ),
        ],
      ),
    );

    // ── BLOCO DE TOTAIS (sempre exibido ao final) ──────────────────────────
    pw.Widget blocoTotais() => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: corEscura,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _totalLinha(fontNormal, 'Total Peças',
              'R\$ ${totalPecas.toStringAsFixed(2)}', PdfColors.white),
          pw.SizedBox(height: 5),
          _totalLinha(fontNormal, 'Total Serviços',
              'R\$ ${totalServicos.toStringAsFixed(2)}', PdfColors.white),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Divider(color: PdfColors.blueGrey600, thickness: 0.5),
          ),
          _totalLinha(fontBold, 'TOTAL GERAL',
              'R\$ ${totalGeral.toStringAsFixed(2)}',
              PdfColors.greenAccent,
              fontSize: 15),
        ],
      ),
    );

    // ── RODAPÉ ─────────────────────────────────────────────────────────────
    pw.Widget rodape() => pw.Column(children: [
      pw.SizedBox(height: 10),
      pw.Divider(color: PdfColors.grey300),
      pw.Center(
        child: pw.Text(
          'AF Motors & Serviços — Documento gerado automaticamente',
          style: pw.TextStyle(
              font: fontNormal, fontSize: 8, color: PdfColors.grey),
        ),
      ),
    ]);

    // ── PÁGINA ─────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        // Cabeçalho repetido em todas as páginas
        header: (_) => pw.Column(children: [
          cabecalho(),
          pw.SizedBox(height: 14),
        ]),
        // Rodapé com numeração
        footer: (ctx) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('AF Motors & Serviços',
                  style: pw.TextStyle(
                      font: fontNormal, fontSize: 8, color: PdfColors.grey)),
              pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                  style: pw.TextStyle(
                      font: fontNormal, fontSize: 8, color: PdfColors.grey)),
            ],
          ),
        ]),
        build: (pw.Context context) => [

          // ── DADOS DO CLIENTE ─────────────────────────────────────────
          _secao(fontBold, 'DADOS DO CLIENTE', corAzul),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: corCinza,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _linha(fontBold, fontNormal, 'Nome',
                    os['cliente_nome'] ?? 'Não informado'),
                if ((cliente['telefone'] ?? '').toString().isNotEmpty)
                  _linha(fontBold, fontNormal, 'Telefone',
                      cliente['telefone'].toString()),
                if ((cliente['cpf'] ?? '').toString().isNotEmpty)
                  _linha(fontBold, fontNormal, 'CPF',
                      cliente['cpf'].toString()),
                if ((cliente['endereco'] ?? '').toString().isNotEmpty)
                  _linha(fontBold, fontNormal, 'Endereço', [
                    cliente['endereco'],
                    if ((cliente['numero'] ?? '').toString().isNotEmpty)
                      cliente['numero'],
                    if ((cliente['bairro'] ?? '').toString().isNotEmpty)
                      cliente['bairro'],
                    if ((cliente['cidade'] ?? '').toString().isNotEmpty)
                      cliente['cidade'],
                  ].join(', ')),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // ── DADOS DA OS ───────────────────────────────────────────────
          _secao(fontBold, 'DADOS DA ORDEM DE SERVIÇO', corAzul),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: corCinza,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _linha(fontBold, fontNormal, 'Equipamento',
                    os['equipamento'] ?? 'Não informado'),
                _linha(fontBold, fontNormal, 'Status',
                    os['status'] ?? 'Orçamento'),
                _linha(fontBold, fontNormal, 'Pagamento',
                    os['forma_pagamento'] ?? 'Não definido'),
                _linha(fontBold, fontNormal, 'Defeito relatado',
                    os['defeito'] ?? 'Não informado'),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // ── SERVIÇOS ──────────────────────────────────────────────────
          _secao(fontBold, 'SERVIÇOS REALIZADOS', corAzul),
          pw.SizedBox(height: 4),
          if (servicos.isEmpty)
            pw.Text('Nenhum serviço adicionado.',
                style: pw.TextStyle(font: fontNormal, color: PdfColors.grey))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: corAzul),
                  children: [
                    _celula('Serviço',  fontBold, cor: PdfColors.white),
                    _celula('Obs',      fontBold, cor: PdfColors.white),
                    _celula('Valor',    fontBold, cor: PdfColors.white,
                        align: pw.Alignment.centerRight),
                  ],
                ),
                ...servicos.map((s) {
                  final preco = (s['preco'] as num?)?.toDouble() ?? 0;
                  return pw.TableRow(children: [
                    _celula(s['nome']      ?? '-', fontNormal),
                    _celula((s['descricao'] ?? '').toString().isNotEmpty
                        ? s['descricao'] : '-', fontNormal,
                        cor: PdfColors.grey700),
                    _celula('R\$ ${preco.toStringAsFixed(2)}', fontNormal,
                        align: pw.Alignment.centerRight),
                  ]);
                }),
              ],
            ),

          pw.SizedBox(height: 12),

          // ── PEÇAS ─────────────────────────────────────────────────────
          _secao(fontBold, 'PEÇAS UTILIZADAS', corAzul),
          pw.SizedBox(height: 4),
          if (pecas.isEmpty)
            pw.Text('Nenhuma peça utilizada.',
                style: pw.TextStyle(font: fontNormal, color: PdfColors.grey))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: corAzul),
                  children: [
                    _celula('Peça',     fontBold, cor: PdfColors.white),
                    _celula('Qtd',      fontBold, cor: PdfColors.white,
                        align: pw.Alignment.center),
                    _celula('Subtotal', fontBold, cor: PdfColors.white,
                        align: pw.Alignment.centerRight),
                  ],
                ),
                ...pecas.map((p) {
                  final qtd      = (p['qtd']   as num?)?.toInt()    ?? 1;
                  final preco    = (p['preco'] as num?)?.toDouble() ?? 0;
                  final subtotal = preco * qtd;
                  return pw.TableRow(children: [
                    _celula(p['nome'] ?? '-', fontNormal),
                    _celula('$qtd', fontNormal, align: pw.Alignment.center),
                    _celula('R\$ ${subtotal.toStringAsFixed(2)}', fontNormal,
                        align: pw.Alignment.centerRight),
                  ]);
                }),
              ],
            ),

          pw.SizedBox(height: 16),

          // ── TOTAIS ────────────────────────────────────────────────────
          blocoTotais(),

          // ── RODAPÉ EXTRA ──────────────────────────────────────────────
          rodape(),
        ],
      ),
    );

    // ── SALVA E COMPARTILHA ────────────────────────────────────────────────
    final output = await getTemporaryDirectory();
    final nomeArquivo = numeroOS.isNotEmpty
        ? '$numeroOS - ${os['cliente_nome'] ?? 'OS'}.pdf'
        : 'OS_${os['cliente_nome'] ?? 'Documento'}.pdf';
    final file = File('${output.path}/$nomeArquivo');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
      'Segue a Ordem de Serviço${numeroOS.isNotEmpty ? " $numeroOS" : ""} de ${os['cliente_nome'] ?? ""}',
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  static pw.Widget _secao(pw.Font font, String titulo, PdfColor cor) =>
      pw.Row(children: [
        pw.Container(
            width: 4, height: 14,
            decoration: pw.BoxDecoration(
                color: cor, borderRadius: pw.BorderRadius.circular(2))),
        pw.SizedBox(width: 6),
        pw.Text(titulo,
            style: pw.TextStyle(font: font, fontSize: 11, color: cor)),
      ]);

  static pw.Widget _linha(
      pw.Font bold, pw.Font normal, String label, String valor) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('$label: ',
                style: pw.TextStyle(font: bold, fontSize: 10)),
            pw.Expanded(
              child: pw.Text(valor,
                  style: pw.TextStyle(font: normal, fontSize: 10)),
            ),
          ],
        ),
      );

  static pw.Widget _celula(String texto, pw.Font font,
      {PdfColor? cor,
        pw.Alignment align = pw.Alignment.centerLeft}) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(5),
        alignment: align,
        child: pw.Text(texto,
            style: pw.TextStyle(
                font: font, fontSize: 9, color: cor ?? PdfColors.black)),
      );

  static pw.Widget _totalLinha(
      pw.Font font, String label, String valor, PdfColor cor,
      {double fontSize = 11}) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style:
              pw.TextStyle(font: font, fontSize: fontSize, color: cor)),
          pw.Text(valor,
              style:
              pw.TextStyle(font: font, fontSize: fontSize, color: cor)),
        ],
      );
}