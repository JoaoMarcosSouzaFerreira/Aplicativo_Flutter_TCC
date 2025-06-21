import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

import 'broker.dart';
import 'dadosexperimento.dart';
import 'experimento.dart';
import 'experimento_data_service.dart';
import 'custom_page_route.dart';

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

  final PageController _pageController = PageController(
    viewportFraction: 0.8,
  );
  int _indiceVisivel = 0;

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
    _pageController.dispose();
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

        if (_indiceVisivel >= _contagemAtualMembros) {
          _indiceVisivel = math.max(0, _contagemAtualMembros - 1);
        }
      });
    }
  }

  void _lidarComMudancaDeDados() {
    final contagemAntiga = _contagemAtualMembros;
    if (contagemAntiga != _servicoDados.membros.length ||
        _controladoresNome.length != _servicoDados.membros.length) {
      _inicializarControladoresECarregarDados();

      if (_servicoDados.membros.length > contagemAntiga && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              _servicoDados.membros.length - 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } else if (mounted) {
      setState(() {
        _podeDarPopNaTela = !_servicoDados.possuiAlteracoesNaoSalvas;
      });
    }
  }

  void _adicionarNovoMembro() {
    if (_servicoDados.membros.length < 4) {
      _servicoDados.adicionarMembro();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('O limite é de 4 integrantes por grupo.'),
            backgroundColor: Colors.blueGrey.shade700),
      );
    }
  }

  void _removerMembroSelecionado(int indice) {
    if (_servicoDados.membros.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Deve haver pelo menos um integrante.'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }

    final bool isLastCard = indice == _servicoDados.membros.length - 1;
    if (indice == _indiceVisivel && isLastCard) {
      _pageController
          .animateToPage(
        indice - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      )
          .then((_) {
        if (mounted) {
          _servicoDados.removerMembro(indice);
        }
      });
    } else {
      _servicoDados.removerMembro(indice);
    }
  }

  void _salvarDadosNaLogicaLocal() {
    _servicoDados.salvarDados();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const Text('Dados salvos com sucesso!'),
          backgroundColor: Theme.of(context).colorScheme.secondary),
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
                      context, FadePageRoute(child: const ConectaBroker()));
                },
                child: const Text('Continuar sem Salvar'),
              ),
              ElevatedButton(
                onPressed: () {
                  _salvarDadosNaLogicaLocal();
                  Navigator.pop(contextoDialogo);
                  Navigator.push(
                      context, FadePageRoute(child: const ConectaBroker()));
                },
                child: const Text('Salvar e Continuar'),
              ),
            ],
          ),
        );
      } else {
        Navigator.push(context, FadePageRoute(child: const ConectaBroker()));
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
            onPressed: () => Navigator.pop(contextoDialogo),
            child: const Text('Preencher dados'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(contextoDialogo);
              Navigator.push(
                  context, FadePageRoute(child: const ConectaBroker()));
            },
            child: const Text('Ir para Broker'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0)
          .copyWith(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildIntegranteCard(int index, ThemeData theme) {
    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: theme.colorScheme.primary,
                  tooltip: 'Adicionar novo integrante',
                  onPressed:
                      _contagemAtualMembros < 4 ? _adicionarNovoMembro : null,
                ),
                Text(
                  'Integrante ${index + 1} / $_contagemAtualMembros',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  color: theme.colorScheme.error,
                  tooltip: 'Remover este integrante',
                  onPressed: () => _removerMembroSelecionado(index),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      key: ValueKey('nome_${_servicoDados.membros[index].id}'),
                      controller: _controladoresNome[index],
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: ValueKey(
                          'matricula_${_servicoDados.membros[index].id}'),
                      controller: _controladoresMatricula[index],
                      decoration: const InputDecoration(
                        labelText: 'Matrícula',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                      inputFormatters: [],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_controladoresNome.length != _servicoDados.membros.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _inicializarControladoresECarregarDados();
        }
      });
    }
    return PopScope(
      canPop: _podeDarPopNaTela,
      onPopInvokedWithResult: (bool didPop, dynamic _) async {
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
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(contextoDialogo, 'salvar_e_sair');
                },
                child: const Text('Salvar e Sair'),
              ),
            ],
          ),
        );
        if (mounted) {
          if (resultado == 'salvar_e_sair') {
            _salvarDadosNaLogicaLocal();
            setState(() => _podeDarPopNaTela = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context);
            });
          } else if (resultado == 'descartar_e_sair') {
            setState(() => _podeDarPopNaTela = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context);
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Dados dos Integrantes'),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Integrantes do Grupo', context),
                      SizedBox(
                        height: 320,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _contagemAtualMembros,
                          onPageChanged: (index) {
                            setState(() {
                              _indiceVisivel = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: _pageController,
                              builder: (context, child) {
                                double value = 1.0;
                                if (_pageController.position.haveDimensions) {
                                  value = (_pageController.page ?? 0.0) - index;
                                  value =
                                      (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                                }
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: _buildIntegranteCard(index, theme),
                            );
                          },
                        ),
                      ),
                      _buildSectionTitle('Data do Experimento', context),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _controladorDia,
                                    decoration: const InputDecoration(
                                        labelText: 'Dia',
                                        prefixIcon: Icon(
                                            Icons.calendar_today_outlined)),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(2)
                                    ],
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text("/",
                                        style: TextStyle(fontSize: 24))),
                                Expanded(
                                  child: TextFormField(
                                    controller: _controladorMes,
                                    decoration:
                                        const InputDecoration(labelText: 'Mês'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(2)
                                    ],
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text("/",
                                        style: TextStyle(fontSize: 24))),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _controladorAno,
                                    decoration:
                                        const InputDecoration(labelText: 'Ano'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4)
                                    ],
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
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
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: const Offset(0, -2))
                    ],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    )),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _servicoDados.possuiAlteracoesNaoSalvas
                          ? _salvarDadosNaLogicaLocal
                          : null,
                      icon: const Icon(Icons.save_alt_outlined),
                      label: const Text('Salvar Alterações'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: _servicoDados.possuiAlteracoesNaoSalvas
                                ? theme.colorScheme.primary
                                : Colors.grey.shade400,
                          )),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _iniciarFluxoDoExperimento,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Inserir Dados do Broker'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
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
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            break;
          case 1:
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(
                  context, FadePageRoute(child: const ConectaBroker()));
            });
            break;
          case 2:
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(
                  context, FadePageRoute(child: const DadosExperimentos()));
            });
            break;
          case 3:
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(
                  context, FadePageRoute(child: const Experimento()));
            });
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          selectedIcon: Icon(Icons.group),
          icon: Icon(Icons.group_outlined),
          label: 'Integrantes',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.cloud),
          icon: Icon(Icons.cloud_outlined),
          label: 'Broker',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.assignment),
          icon: Icon(Icons.assignment_outlined),
          label: 'Dados Exp.',
        ),
        NavigationDestination(
          selectedIcon: Icon(Icons.science),
          icon: Icon(Icons.science_outlined),
          label: 'Experimento',
        ),
      ],
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
              'Você tem alterações não salvas. Deseja descartá-las antes de prosseguir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, 'descartar'),
              child: const Text('Descartar e Prosseguir'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(contextoDialogo, 'salvar');
              },
              child: const Text('Salvar e Prosseguir'),
            ),
          ],
        ),
      );
      if (mounted) {
        if (resultado == 'salvar') {
          _salvarDadosNaLogicaLocal();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) acaoNavegar();
          });
        } else if (resultado == 'descartar') {
          acaoNavegar();
        }
      }
    } else {
      acaoNavegar();
    }
  }
}
