// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'broker.dart';
import 'dadosexperimento.dart';
import 'experimento.dart';
import 'experimento_data_service.dart';

class IntegrantesScreen extends StatefulWidget {
  const IntegrantesScreen({super.key});

  @override
  State<IntegrantesScreen> createState() => _IntegrantesScreenState();
}

class _IntegrantesScreenState extends State<IntegrantesScreen> {
  final ServicoDadosExperimento _servicoDados = ServicoDadosExperimento();

  List<TextEditingController> _controladoresNome = [];
  List<TextEditingController> _controladoresMatricula = [];
  int _contagemAtualMembros = 1;

  final TextEditingController _controladorDia = TextEditingController();
  final TextEditingController _controladorMes = TextEditingController();
  final TextEditingController _controladorAno = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _podeDarPopNaTela = true;

  final Color _corPrimaria = const Color.fromRGBO(19, 85, 156, 1);
  final Color _fundoAzulClaro = Colors.blue.shade50;
  final Color _corTextoBotaoBranco = Colors.white;
  final Color _corDestaqueVerde = const Color.fromARGB(255, 15, 220, 22);

  @override
  void initState() {
    super.initState();
    _inicializarControladoresECarregarDados();
    _servicoDados.definirCallbackAoMudarDados(_lidarComMudancaDeDados);
    _podeDarPopNaTela = !_servicoDados.possuiAlteracoesNaoSalvas;

    _controladorDia.addListener(
        () => _servicoDados.atualizarData(dia: _controladorDia.text));
    _controladorMes.addListener(
        () => _servicoDados.atualizarData(mes: _controladorMes.text));
    _controladorAno.addListener(
        () => _servicoDados.atualizarData(ano: _controladorAno.text));
  }

  @override
  void dispose() {
    for (var ctrl in _controladoresNome) {
      ctrl.dispose();
    }
    for (var ctrl in _controladoresMatricula) {
      ctrl.dispose();
    }
    _controladorDia.dispose();
    _controladorMes.dispose();
    _controladorAno.dispose();
    _servicoDados.definirCallbackAoMudarDados(null);
    super.dispose();
  }

  void _inicializarControladoresECarregarDados() {
    for (var ctrl in _controladoresNome) {
      ctrl.removeListener(() {});
      ctrl.dispose();
    }
    for (var ctrl in _controladoresMatricula) {
      ctrl.removeListener(() {});
      ctrl.dispose();
    }
    _controladoresNome = [];
    _controladoresMatricula = [];

    for (int i = 0; i < _servicoDados.membros.length; i++) {
      final ctrlNome =
          TextEditingController(text: _servicoDados.membros[i].nome);
      final ctrlMatricula =
          TextEditingController(text: _servicoDados.membros[i].matricula);

      final indiceAtual = i;
      ctrlNome.addListener(() {
        if (indiceAtual < _servicoDados.membros.length) {
          _servicoDados.atualizarMembro(indiceAtual, nome: ctrlNome.text);
        }
      });
      ctrlMatricula.addListener(() {
        if (indiceAtual < _servicoDados.membros.length) {
          _servicoDados.atualizarMembro(indiceAtual,
              matricula: ctrlMatricula.text);
        }
      });

      _controladoresNome.add(ctrlNome);
      _controladoresMatricula.add(ctrlMatricula);
    }

    _controladorDia.text = _servicoDados.dataDoExperimento.dia;
    _controladorMes.text = _servicoDados.dataDoExperimento.mes;
    _controladorAno.text = _servicoDados.dataDoExperimento.ano;

    if (mounted) {
      setState(() {
        _contagemAtualMembros = _servicoDados.membros.length;
        _podeDarPopNaTela = !_servicoDados.possuiAlteracoesNaoSalvas;
      });
    }
  }

  void _lidarComMudancaDeDados() {
    if (_contagemAtualMembros != _servicoDados.membros.length ||
        _controladoresNome.length != _servicoDados.membros.length) {
      _inicializarControladoresECarregarDados();
    } else if (mounted) {
      setState(() {
        _podeDarPopNaTela = !_servicoDados.possuiAlteracoesNaoSalvas;
      });
    }
  }

  void _adicionarNovoMembro() {
    _servicoDados.adicionarMembro();
  }

  void _removerMembroSelecionado(int indice) {
    if (_servicoDados.membros.length > 1) {
      _servicoDados.removerMembro(indice);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deve haver pelo menos um integrante.')),
      );
    }
  }

  void _salvarDadosNaLogicaLocal() {
    _servicoDados.salvarDados();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Dados salvos com sucesso!'),
          backgroundColor: Colors.green),
    );
  }

  void _iniciarFluxoDoExperimento() {
    final todosNomesPreenchidos =
        _servicoDados.membros.every((m) => m.nome.trim().isNotEmpty);
    final todasMatriculasPreenchidas =
        _servicoDados.membros.every((m) => m.matricula.trim().isNotEmpty);
    final dataPreenchida =
        _servicoDados.dataDoExperimento.dia.trim().isNotEmpty &&
            _servicoDados.dataDoExperimento.mes.trim().isNotEmpty &&
            _servicoDados.dataDoExperimento.ano.trim().isNotEmpty;

    if (todosNomesPreenchidos && todasMatriculasPreenchidas && dataPreenchida) {
      if (_servicoDados.possuiAlteracoesNaoSalvas) {
        showDialog(
          context: context,
          builder: (contextoDialogo) => AlertDialog(
            title: const Text('Salvar Alterações?'),
            content: const Text(
                'Você tem alterações não salvas. Deseja salvá-las antes de prosseguir para o Broker?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(contextoDialogo);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const ConectaBroker()),
                  );
                },
                child: const Text('Continuar sem Salvar'),
              ),
              ElevatedButton(
                onPressed: () {
                  _salvarDadosNaLogicaLocal();
                  Navigator.pop(contextoDialogo);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const ConectaBroker()),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _corPrimaria,
                    foregroundColor: Colors.white),
                child: const Text('Salvar e Continuar'),
              ),
            ],
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => const ConectaBroker()),
        );
      }
      return;
    }

    String textoAlerta;
    if (!dataPreenchida &&
        (!todosNomesPreenchidos || !todasMatriculasPreenchidas)) {
      textoAlerta =
          'Você não preencheu nem os dados dos integrantes nem a data.\nO relatório será gerado sem essas informações.';
    } else if (!dataPreenchida) {
      textoAlerta =
          'Você não informou a data do experimento.\nO relatório será gerado sem data.';
    } else {
      textoAlerta =
          'Você não preencheu os dados dos integrantes.\nO relatório será gerado sem identificação dos membros.';
    }

    showDialog(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Campos não preenchidos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: LottieBuilder.asset('assets/Alerta.json',
                  fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(textoAlerta,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(contextoDialogo),
            child: const Text('Preencher dados'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(contextoDialogo);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (BuildContext context) => const ConectaBroker()),
              );
            },
            child: const Text('Ir para Broker'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoracaoCampoTexto(String rotulo,
      {IconData? iconePrefixo}) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: TextStyle(color: _corPrimaria.withOpacity(0.9)),
      prefixIcon: iconePrefixo != null
          ? Icon(iconePrefixo, color: _corPrimaria.withOpacity(0.7))
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _corPrimaria, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controladoresNome.length != _servicoDados.membros.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _inicializarControladoresECarregarDados();
        }
      });
    }

    return PopScope(
      canPop: _podeDarPopNaTela,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final resultado = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (contextoDialogo) => AlertDialog(
            title: const Text('Alterações Não Salvas'),
            content: const Text(
                'Você tem alterações não salvas. Deseja salvá-las antes de sair desta tela?'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(contextoDialogo, 'descartar_e_sair'),
                child: const Text('Descartar e Sair'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(contextoDialogo, 'cancelar'),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(contextoDialogo, 'salvar_e_sair');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _corPrimaria,
                    foregroundColor: Colors.white),
                child: const Text('Salvar e Sair'),
              ),
            ],
          ),
        );

        if (mounted) {
          if (resultado == 'salvar_e_sair') {
            _salvarDadosNaLogicaLocal();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _podeDarPopNaTela) {
                Navigator.pop(context);
              }
            });
          } else if (resultado == 'descartar_e_sair') {
            if (mounted) {
              setState(() {
                _podeDarPopNaTela = true;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.pop(context);
              });
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Dados dos Integrantes',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          centerTitle: true,
          backgroundColor: _corPrimaria,
          elevation: 2,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Integrantes do Grupo',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _corPrimaria),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _contagemAtualMembros,
                        itemBuilder: (contextoItem, i) {
                          if (i >= _controladoresNome.length) {
                            _controladoresNome.add(TextEditingController());
                          }
                          if (i >= _controladoresMatricula.length) {
                            _controladoresMatricula
                                .add(TextEditingController());
                          }

                          return Card(
                            elevation: 1.5,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: _fundoAzulClaro,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline,
                                          color: _corPrimaria, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Integrante ${i + 1}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _corPrimaria,
                                            fontSize: 16),
                                      ),
                                      const Spacer(),
                                      if (_contagemAtualMembros > 1)
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () =>
                                              _removerMembroSelecionado(i),
                                          icon: Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.red.shade600),
                                          tooltip: 'Remover Integrante',
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    key: ValueKey(
                                        'nome_${_servicoDados.membros[i].id}'),
                                    controller: _controladoresNome[i],
                                    decoration:
                                        _decoracaoCampoTexto('Nome Completo'),
                                    textCapitalization:
                                        TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    key: ValueKey(
                                        'matricula_${_servicoDados.membros[i].id}'),
                                    controller: _controladoresMatricula[i],
                                    decoration:
                                        _decoracaoCampoTexto('Matrícula'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (_contagemAtualMembros < 4)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Center(
                            child: OutlinedButton.icon(
                              onPressed: _adicionarNovoMembro,
                              icon: Icon(Icons.add_circle_outline,
                                  color: _corPrimaria),
                              label: Text('Adicionar Integrante',
                                  style: TextStyle(
                                      color: _corPrimaria,
                                      fontWeight: FontWeight.w500)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: _corPrimaria.withOpacity(0.7)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Data do Experimento',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _corPrimaria),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 1.5,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _controladorDia,
                                  decoration: _decoracaoCampoTexto('Dia',
                                      iconePrefixo:
                                          Icons.calendar_today_outlined),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2)
                                  ],
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text("/",
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.grey)),
                              ),
                              Expanded(
                                  child: TextFormField(
                                controller: _controladorMes,
                                decoration: _decoracaoCampoTexto('Mês'),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2)
                                ],
                                textAlign: TextAlign.center,
                              )),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text("/",
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.grey)),
                              ),
                              Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _controladorAno,
                                    decoration: _decoracaoCampoTexto('Ano'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4)
                                    ],
                                    textAlign: TextAlign.center,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 5,
                        offset: const Offset(0, -2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _servicoDados.possuiAlteracoesNaoSalvas
                          ? _salvarDadosNaLogicaLocal
                          : null,
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text('Salvar Alterações'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _servicoDados.possuiAlteracoesNaoSalvas
                            ? _corPrimaria
                            : Colors.grey.shade400,
                        foregroundColor: _corTextoBotaoBranco,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        elevation:
                            _servicoDados.possuiAlteracoesNaoSalvas ? 2 : 0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _iniciarFluxoDoExperimento,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Inserir Dados do Broker'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _corDestaqueVerde,
                        foregroundColor: _corTextoBotaoBranco,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        elevation: 2,
                      ),
                    ),
                  ],
                )),
          ],
        ),
        bottomNavigationBar: _construirBarraNavegacaoInferior(),
      ),
    );
  }

  Widget _construirBarraNavegacaoInferior() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: _corPrimaria,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -1)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(Icons.group, 'Integrantes', () {
            _inicializarControladoresECarregarDados();
          }, isActive: true),
          _buildNavBarItem(Icons.cloud_outlined, 'Broker', () {
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ConectaBroker()));
            });
          }),
          _buildNavBarItem(Icons.assignment_outlined, 'Dados Exp.', () {
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DadosExperimentos()));
            });
          }),
          _buildNavBarItem(Icons.science_outlined, 'Experimento', () {
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const Experimento()));
            });
          }),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(
      IconData icone, String rotulo, VoidCallback aoPressionar,
      {bool isActive = false}) {
    final Color iconColor =
        isActive ? Colors.white : Colors.white.withOpacity(0.7);
    final double iconSize = isActive ? 28 : 24;
    return IconButton(
      icon: Icon(icone, color: iconColor, size: iconSize),
      tooltip: rotulo,
      onPressed: aoPressionar,
    );
  }

  void _verificarAlteracoesAntesDeNavegarParaOutraTela(
      VoidCallback acaoNavegar) async {
    if (_servicoDados.possuiAlteracoesNaoSalvas) {
      final resultado = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (contextoDialogo) => AlertDialog(
          title: const Text('Alterações Não Salvas'),
          content: const Text(
              'Você tem alterações não salvas nos dados dos integrantes. Deseja salvá-las antes de prosseguir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, 'descartar'),
              child: const Text('Descartar e Prosseguir'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, 'cancelar'),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(contextoDialogo, 'salvar');
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _corPrimaria,
                  foregroundColor: _corTextoBotaoBranco),
              child: const Text('Salvar e Prosseguir'),
            ),
          ],
        ),
      );
      if (resultado == 'salvar') {
        _salvarDadosNaLogicaLocal();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) acaoNavegar();
        });
      } else if (resultado == 'descartar') {
        acaoNavegar();
      }
    } else {
      acaoNavegar();
    }
  }
}
