import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EstoquePinturaPage extends StatefulWidget {
  const EstoquePinturaPage({super.key});

  @override
  State<EstoquePinturaPage> createState() => _EstoquePinturaPageState();
}

class _EstoquePinturaPageState extends State<EstoquePinturaPage> {
  String _busca = '';

  // ── ABRIR FORMULÁRIO (novo ou editar) ──────────────────────────────────────
  void _abrirFormulario({DocumentSnapshot? docExistente}) {
    final dados = docExistente?.data() as Map<String, dynamic>?;

    final nomeCtrl      = TextEditingController(text: dados?['nome']           ?? '');
    final precoCtrl     = TextEditingController(
        text: dados != null
            ? (dados['preco'] as num?)?.toStringAsFixed(2) ?? ''
            : '');
    final qtdCtrl       = TextEditingController(text: dados?['quantidade']     ?? '');
    final codigoCtrl    = TextEditingController(text: dados?['codigo_barras']  ?? '');
    final categoriaCtrl = TextEditingController(text: dados?['categoria']      ?? '');

    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D2B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── TÍTULO ────────────────────────────────────────────
                  Row(children: [
                    const Icon(Icons.format_paint, color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    Text(
                      docExistente == null ? 'Novo Item' : 'Editar Item',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── NOME ──────────────────────────────────────────────
                  _inputModal(nomeCtrl, 'Nome do produto', Icons.label_outline),
                  const SizedBox(height: 10),

                  // ── CATEGORIA ─────────────────────────────────────────
                  _inputModal(categoriaCtrl, 'Categoria (ex: Tinta, Lixa, Verniz)',
                      Icons.category_outlined),
                  const SizedBox(height: 10),

                  // ── PREÇO E QUANTIDADE ────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: precoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration:
                        _decModal('Preço (R\$)', Icons.attach_money),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      // Quantidade aceita número OU letra (ex: "2", "P", "G", "500ml")
                      child: _inputModal(
                          qtdCtrl, 'Qtd (ex: 3, G, 500ml)', Icons.numbers),
                    ),
                  ]),
                  const SizedBox(height: 10),

                  // ── CÓDIGO DE BARRAS ──────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: codigoCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _decModal(
                            'Código de barras', Icons.barcode_reader),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botão câmera
                    GestureDetector(
                      onTap: () async {
                        final codigo = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _ScannerPage(),
                          ),
                        );
                        if (codigo != null) {
                          setModal(() => codigoCtrl.text = codigo);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.blueAccent, size: 22),
                      ),
                    ),
                  ]),

                  if (codigoCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.check_circle,
                          color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        codigoCtrl.text,
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 12),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 28),

                  // ── SALVAR ────────────────────────────────────────────
                  salvando
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (nomeCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Informe o nome do produto.'),
                              backgroundColor: Colors.red),
                        );
                        return;
                      }
                      setModal(() => salvando = true);
                      try {
                        final payload = {
                          'nome':          nomeCtrl.text.trim(),
                          'categoria':     categoriaCtrl.text.trim(),
                          'preco':         double.tryParse(
                              precoCtrl.text.replaceAll(',', '.')) ?? 0.0,
                          'quantidade':    qtdCtrl.text.trim(),
                          'codigo_barras': codigoCtrl.text.trim(),
                          'ultima_atualizacao':
                          FieldValue.serverTimestamp(),
                        };

                        if (docExistente == null) {
                          payload['data_cadastro'] =
                              FieldValue.serverTimestamp();
                          await FirebaseFirestore.instance
                              .collection('estoque_pintura')
                              .add(payload);
                        } else {
                          await FirebaseFirestore.instance
                              .collection('estoque_pintura')
                              .doc(docExistente.id)
                              .update(payload);
                        }

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setModal(() => salvando = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Erro: $e'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Text(
                      docExistente == null
                          ? 'SALVAR ITEM'
                          : 'ATUALIZAR ITEM',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── SCANNER PARA CONFIRMAR PRODUTO ────────────────────────────────────────
  // Abre a câmera, lê o código, busca no Firestore e mostra o produto encontrado
  void _confirmarProduto() async {
    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerPage()),
    );
    if (codigo == null || !mounted) return;

    // Busca no Firestore pelo código de barras
    final snap = await FirebaseFirestore.instance
        .collection('estoque_pintura')
        .where('codigo_barras', isEqualTo: codigo)
        .limit(1)
        .get();

    if (!mounted) return;

    if (snap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhum produto encontrado para o código: $codigo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final doc   = snap.docs.first;
    final dados = doc.data();
    _mostrarConfirmacao(doc, dados);
  }

  // ── DIALOG DE CONFIRMAÇÃO DO PRODUTO ESCANEADO ────────────────────────────
  void _mostrarConfirmacao(
      DocumentSnapshot doc, Map<String, dynamic> dados) {
    final preco = (dados['preco'] as num?)?.toDouble() ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
          const SizedBox(width: 10),
          const Text('Produto Encontrado',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoDialog('Nome',       dados['nome']       ?? '---', Colors.white),
            _infoDialog('Categoria',  dados['categoria']  ?? '---', Colors.white70),
            _infoDialog('Quantidade', dados['quantidade'] ?? '---', Colors.cyanAccent),
            _infoDialog('Preço',
                preco > 0 ? 'R\$ ${preco.toStringAsFixed(2)}' : '---',
                Colors.greenAccent),
            _infoDialog('Código',     dados['codigo_barras'] ?? '---', Colors.white38),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('FECHAR'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            label: const Text('EDITAR',
                style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              _abrirFormulario(docExistente: doc);
            },
          ),
        ],
      ),
    );
  }

  Widget _infoDialog(String label, String valor, Color cor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text('$label:',
              style: const TextStyle(
                  color: Colors.white38, fontSize: 13)),
        ),
        Expanded(
          child: Text(valor,
              style: TextStyle(
                  color: cor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  // ── CONFIRMAR EXCLUSÃO ────────────────────────────────────────────────────
  void _confirmarExclusao(String id, String nome) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Excluir Item?',
            style: TextStyle(color: Colors.white)),
        content: Text('Remover "$nome"? Esta ação não pode ser desfeita.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance
                  .collection('estoque_pintura')
                  .doc(id)
                  .delete();
            },
            child: const Text('EXCLUIR',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      appBar: AppBar(
        title: const Text('Estoque de Pintura'),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        actions: [
          // Botão de escanear para confirmar/buscar produto
          IconButton(
            icon: const Icon(Icons.barcode_reader, color: Colors.blueAccent),
            tooltip: 'Escanear produto',
            onPressed: _confirmarProduto,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TextField(
              onChanged: (v) => setState(() => _busca = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nome, categoria ou código...',
                prefixIcon:
                const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                hintStyle: const TextStyle(color: Colors.white60),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Item',
            style: TextStyle(color: Colors.white)),
        onPressed: () => _abrirFormulario(),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('estoque_pintura')
            .orderBy('nome')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final itens = snapshot.data!.docs.where((doc) {
            final d       = doc.data() as Map<String, dynamic>;
            final nome    = (d['nome']          ?? '').toString().toLowerCase();
            final cat     = (d['categoria']     ?? '').toString().toLowerCase();
            final codigo  = (d['codigo_barras'] ?? '').toString().toLowerCase();
            return nome.contains(_busca) ||
                cat.contains(_busca) ||
                codigo.contains(_busca);
          }).toList();

          if (itens.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.format_paint,
                      size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    _busca.isEmpty
                        ? 'Nenhum item cadastrado.'
                        : 'Nenhum item encontrado.',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  if (_busca.isEmpty)
                    const Text('Toque em + para adicionar.',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 13)),
                ],
              ),
            );
          }

          // Agrupa por categoria para exibir separadores
          final Map<String, List<QueryDocumentSnapshot>> porCategoria = {};
          for (final doc in itens) {
            final d   = doc.data() as Map<String, dynamic>;
            final cat = (d['categoria'] ?? 'Sem categoria').toString();
            porCategoria.putIfAbsent(cat, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
            children: porCategoria.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER DA CATEGORIA ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 0, 6),
                    child: Row(children: [
                      const Icon(Icons.folder_open,
                          color: Colors.blueAccent, size: 15),
                      const SizedBox(width: 6),
                      Text(
                        entry.key,
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value.length} item${entry.value.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ]),
                  ),

                  // ── CARDS DOS ITENS ───────────────────────────────
                  ...entry.value.map((doc) {
                    final d     = doc.data() as Map<String, dynamic>;
                    final preco = (d['preco'] as num?)?.toDouble() ?? 0;
                    final temCodigo =
                        (d['codigo_barras'] ?? '').toString().isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.2)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.format_paint,
                              color: Colors.blueAccent, size: 20),
                        ),
                        title: Text(
                          d['nome'] ?? 'Sem nome',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            // Qtd + código de barras
                            Row(children: [
                              if ((d['quantidade'] ?? '').toString().isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color:
                                        Colors.cyanAccent.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    'Qtd: ${d['quantidade']}',
                                    style: const TextStyle(
                                        color: Colors.cyanAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (temCodigo)
                                const Icon(Icons.barcode_reader,
                                    color: Colors.white38, size: 13),
                            ]),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              preco > 0
                                  ? 'R\$ ${preco.toStringAsFixed(2)}'
                                  : '---',
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            // Botões de ação inline
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _abrirFormulario(docExistente: doc),
                                  child: const Icon(Icons.edit,
                                      color: Colors.blueAccent, size: 18),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => _confirmarExclusao(
                                      doc.id, d['nome'] ?? 'Item'),
                                  child: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Widget _inputModal(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
      }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _decModal(label, icon),
      );

  InputDecoration _decModal(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white60),
    prefixIcon: Icon(icon, color: Colors.white38, size: 18),
    filled: true,
    fillColor: Colors.white.withOpacity(0.07),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
        BorderSide(color: Colors.white.withOpacity(0.1))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blueAccent)),
  );
}

// ── PÁGINA DO SCANNER DE CÓDIGO DE BARRAS ─────────────────────────────────────

class _ScannerPage extends StatefulWidget {
  const _ScannerPage();

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _escaneado = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Código'),
        backgroundColor: const Color(0xFF000033),
        foregroundColor: Colors.white,
        actions: [
          // Ligar/desligar lanterna
          IconButton(
            icon: const Icon(Icons.flashlight_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Lanterna',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── CÂMERA ────────────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_escaneado) return;
              final codigo = capture.barcodes.first.rawValue;
              if (codigo != null && codigo.isNotEmpty) {
                setState(() => _escaneado = true);
                Navigator.pop(context, codigo);
              }
            },
          ),

          // ── OVERLAY: MOLDURA DE MIRA ──────────────────────────────
          Center(
            child: Container(
              width: 260,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(children: [
                // Cantos decorativos
                _canto(Alignment.topLeft),
                _canto(Alignment.topRight),
                _canto(Alignment.bottomLeft),
                _canto(Alignment.bottomRight),
              ]),
            ),
          ),

          // ── TEXTO INSTRUCIONAL ────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(children: [
              const Icon(Icons.barcode_reader,
                  color: Colors.white54, size: 32),
              const SizedBox(height: 10),
              const Text(
                'Aponte para o código de barras',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                'A leitura é automática',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _canto(Alignment alignment) {
    const size = 20.0;
    const thickness = 3.0;
    final isTop    = alignment == Alignment.topLeft ||
        alignment == Alignment.topRight;
    final isLeft   = alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CantoPainter(
              isTop: isTop, isLeft: isLeft, thickness: thickness),
        ),
      ),
    );
  }
}

class _CantoPainter extends CustomPainter {
  final bool isTop, isLeft;
  final double thickness;

  _CantoPainter(
      {required this.isTop, required this.isLeft, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CantoPainter old) => false;
}