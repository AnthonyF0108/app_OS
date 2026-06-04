import 'package:flutter/material.dart';
import 'app_constants.dart';

// ── APP BAR PADRÃO ────────────────────────────────────────────────────────────

/// AppBar com o estilo padrão do app (fundo escuro + branco).
AppBar buildAppBar(String titulo, {List<Widget>? actions}) => AppBar(
  title: Text(titulo),
  centerTitle: true,
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  elevation: 0,
  actions: actions,
);

// ── SCAFFOLD ESCURO PADRÃO ────────────────────────────────────────────────────

/// Scaffold com background escuro padrão do app.
class DarkScaffold extends StatelessWidget {
  final Widget appBar;
  final Widget body;
  final Widget? fab;

  const DarkScaffold({
    super.key,
    required this.appBar,
    required this.body,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: appBar as PreferredSizeWidget,
      body: body,
      floatingActionButton: fab,
    );
  }
}

// ── INPUT DECORATION PADRÃO ───────────────────────────────────────────────────

InputDecoration darkInputDeco(String hint, {IconData? icon}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Colors.white24),
  prefixIcon: icon != null ? Icon(icon, color: Colors.white38, size: 18) : null,
  filled: true,
  fillColor: Colors.white.withOpacity(0.07),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.white12),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.blueAccent),
  ),
);

// ── DROPDOWN DARK ─────────────────────────────────────────────────────────────

class DarkDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  final String? label;

  const DarkDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.surface,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
              items: items
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Row(children: [
                  Icon(icon, color: Colors.white38, size: 16),
                  const SizedBox(width: 10),
                  Text(e, style: const TextStyle(color: Colors.white)),
                ]),
              ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ── SEÇÃO LABEL ───────────────────────────────────────────────────────────────

Widget sectionLabel(String texto) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 13)),
);

// ── ESTADO VAZIO ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.white24),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 15)),
        ],
      ),
    );
  }
}

// ── ESTADO DE ERRO ────────────────────────────────────────────────────────────

class ErrorState extends StatelessWidget {
  final String message;

  const ErrorState({super.key, this.message = 'Erro ao carregar dados.'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

// ── LOADING ───────────────────────────────────────────────────────────────────

const Widget kLoadingCenter = Center(child: CircularProgressIndicator());

// ── BADGE DE STATUS ───────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String texto;
  final Color cor;

  const StatusBadge({super.key, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withOpacity(0.6)),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── CONFIRM DIALOG ────────────────────────────────────────────────────────────

/// Exibe um diálogo de confirmação e retorna `true` se o usuário confirmar.
Future<bool> confirmarAcao(
    BuildContext context, {
      required String titulo,
      required String mensagem,
      String confirmLabel = 'CONFIRMAR',
      Color confirmColor = Colors.red,
    }) async {
  final resultado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(titulo, style: const TextStyle(color: Colors.white)),
      content: Text(mensagem, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('CANCELAR'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
        ),
      ],
    ),
  );
  return resultado ?? false;
}