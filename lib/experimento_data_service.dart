// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class DadosMembros {
  String nome;
  String matricula;
  final UniqueKey id = UniqueKey();

  DadosMembros({this.nome = '', this.matricula = ''});
}

class DadosData {
  String dia;
  String mes;
  String ano;

  DadosData({this.dia = '', this.mes = '', this.ano = ''});
}

class ServicoDadosExperimento {
  static final ServicoDadosExperimento _instancia =
      ServicoDadosExperimento._interno();
  factory ServicoDadosExperimento() => _instancia;
  ServicoDadosExperimento._interno();

  List<DadosMembros> membros = [DadosMembros()];
  DadosData dataDoExperimento = DadosData();

  bool _possuiAlteracoesNaoSalvas = false;
  bool get possuiAlteracoesNaoSalvas => _possuiAlteracoesNaoSalvas;

  VoidCallback? _aoMudarDadosCallback;

  void definirCallbackAoMudarDados(VoidCallback? callback) {
    _aoMudarDadosCallback = callback;
  }

  void _notificarMudancaDeDados() {
    _possuiAlteracoesNaoSalvas = true;
    _aoMudarDadosCallback?.call();
  }

  void atualizarMembro(int indice, {String? nome, String? matricula}) {
    if (indice < membros.length) {
      if (nome != null) membros[indice].nome = nome;
      if (matricula != null) membros[indice].matricula = matricula;
      _notificarMudancaDeDados();
    }
  }

  void adicionarMembro() {
    if (membros.length < 4) {
      membros.add(DadosMembros());
      _notificarMudancaDeDados();
    }
  }

  void removerMembro(int indice) {
    if (membros.length > 1 && indice < membros.length) {
      membros.removeAt(indice);
      _notificarMudancaDeDados();
    }
  }

  void atualizarData({String? dia, String? mes, String? ano}) {
    if (dia != null) dataDoExperimento.dia = dia;
    if (mes != null) dataDoExperimento.mes = mes;
    if (ano != null) dataDoExperimento.ano = ano;
    _notificarMudancaDeDados();
  }

  void salvarDados() {
    print("Dados Salvos:");
    for (var membro in membros) {
      print(
          " Integrante: Nome: ${membro.nome}, Matrícula: ${membro.matricula}");
    }
    print(
        "Data: ${dataDoExperimento.dia}/${dataDoExperimento.mes}/${dataDoExperimento.ano}");
    _possuiAlteracoesNaoSalvas = false;
    _aoMudarDadosCallback?.call();
  }

  void carregarDadosNosControladores({
    required List<TextEditingController> controladoresNome,
    required List<TextEditingController> controladoresMatricula,
    required TextEditingController controladorDia,
    required TextEditingController controladorMes,
    required TextEditingController controladorAno,
    required Function(int) atualizarContagemDeMembrosUINaInterface,
  }) {
    while (controladoresNome.length < membros.length) {
      controladoresNome.add(TextEditingController());
      controladoresMatricula.add(TextEditingController());
    }

    while (controladoresNome.length > membros.length &&
        controladoresNome.isNotEmpty) {
      controladoresNome.removeLast().dispose();
      controladoresMatricula.removeLast().dispose();
    }

    for (int i = 0; i < membros.length; i++) {
      controladoresNome[i].text = membros[i].nome;
      controladoresMatricula[i].text = membros[i].matricula;
    }

    controladorDia.text = dataDoExperimento.dia;
    controladorMes.text = dataDoExperimento.mes;
    controladorAno.text = dataDoExperimento.ano;

    atualizarContagemDeMembrosUINaInterface(membros.length);
    _possuiAlteracoesNaoSalvas = false;
  }
}
