import 'package:flutter/material.dart';

/// Constantes globais do AF Motors & Serviços.
/// Centraliza cores, strings de coleções e listas de opções,
/// evitando duplicação espalhada pelos arquivos.
class AppColors {
  AppColors._();

  static const primary   = Color(0xFF000033);
  static const secondary = Color(0xFF000044);
  static const surface   = Color(0xFF1A1A2E);

  // Cores semânticas
  static const entrada   = Colors.greenAccent;
  static const saida     = Colors.redAccent;
  static const pendente  = Colors.orangeAccent;
  static const info      = Colors.blueAccent;

  // Utilitários
  static Color cardBg(double opacity) => Colors.white.withOpacity(opacity);
}

class AppCollections {
  AppCollections._();

  static const clientes   = 'clientes';
  static const ordens     = 'ordens';
  static const transacoes = 'transacoes';
  static const veiculos   = 'veiculos';
  static const leilao     = 'motos_leilao';
}

class AppStrings {
  AppStrings._();

  static const appName = 'AF Motors & Serviços';
}

class AppOptions {
  AppOptions._();

  static const formasPagamento = [
    'Dinheiro',
    'PIX',
    'Cartão Débito',
    'Cartão Crédito',
    'Transferência',
  ];

  static const statusOS = [
    'Orçamento',
    'Aguardando Aprovação',
    'Aprovado',
    'Finalizado',
  ];

  static const statusVeiculo = ['Estoque', 'Vendido', 'Reservado'];

  static const categoriasEntrada = ['OS / Serviço', 'Peça Vendida', 'Outros'];
  static const categoriasSaida   = [
    'Fornecedor',
    'Aluguel',
    'Salário',
    'Energia / Água',
    'Outros',
  ];

  static const meses = [
    'Jan','Fev','Mar','Abr','Mai','Jun',
    'Jul','Ago','Set','Out','Nov','Dez',
  ];
}