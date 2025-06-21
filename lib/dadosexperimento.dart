// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';
import 'broker.dart';
import 'experimento.dart';
import 'dados_integrantes.dart';
import 'custom_page_route.dart';

class ExperimentoData {
  static final ExperimentoData _instance = ExperimentoData._internal();
  factory ExperimentoData() => _instance;
  ExperimentoData._internal();
  Map<String, String> valoresAtuais = {
    'observadorKe': '',
    'reguladorK': '',
    'nx': '',
    'nu': '',
    'referencia': '',
  };
  Map<String, String> _valoresUltimoEnvio = {
    'observadorKe': '',
    'reguladorK': '',
    'nx': '',
    'nu': '',
    'referencia': '',
  };
  bool _possuiAlteracoesNaoSalvas = false;
  bool get possuiAlteracoesNaoSalvas => _possuiAlteracoesNaoSalvas;
  VoidCallback? _aoMudarDadosCallback;
  void definirCallbackAoMudarDados(VoidCallback? callback) {
    _aoMudarDadosCallback = callback;
  }

  void atualizarValor(String chave, String valor) {
    if (valoresAtuais[chave] != valor) {
      valoresAtuais[chave] = valor;
      _possuiAlteracoesNaoSalvas = _verificarSeHaAlteracoes();
      _aoMudarDadosCallback?.call();
    }
  }

  bool _verificarSeHaAlteracoes() {
    for (var key in valoresAtuais.keys) {
      if (valoresAtuais[key] != _valoresUltimoEnvio[key]) {
        return true;
      }
    }
    return false;
  }

  void marcarComoEnviadoComSucesso() {
    _valoresUltimoEnvio = Map.from(valoresAtuais);
    _possuiAlteracoesNaoSalvas = false;
    _aoMudarDadosCallback?.call();
  }

  void carregarValoresNosControladores({
    required TextEditingController obsCtrl,
    required TextEditingController regCtrl,
    required TextEditingController nxCtrl,
    required TextEditingController nuCtrl,
    required TextEditingController refCtrl,
  }) {
    obsCtrl.text = valoresAtuais['observadorKe'] ?? '';
    regCtrl.text = valoresAtuais['reguladorK'] ?? '';
    nxCtrl.text = valoresAtuais['nx'] ?? '';
    nuCtrl.text = valoresAtuais['nu'] ?? '';
    refCtrl.text = valoresAtuais['referencia'] ?? '';
    _valoresUltimoEnvio = Map.from(valoresAtuais);
    _possuiAlteracoesNaoSalvas = false;
    _aoMudarDadosCallback?.call();
  }
}

class DadosExperimentos extends StatefulWidget {
  const DadosExperimentos({super.key});

  @override
  State<DadosExperimentos> createState() => _DadosExperimentosState();
}

class _DadosExperimentosState extends State<DadosExperimentos> {
  final ExperimentoData _dadosExperimento = ExperimentoData();
  final BrokerInfo _brokerInfo = BrokerInfo.instance;
  final TextEditingController _observadorKeController = TextEditingController();
  final TextEditingController _reguladorKController = TextEditingController();
  final TextEditingController _nxController = TextEditingController();
  final TextEditingController _nuController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  bool _podeDarPopNaTela = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosNosControladores();
    _dadosExperimento.definirCallbackAoMudarDados(_lidarComMudancaDeDados);
    _brokerInfo.statusNotifier.addListener(_lidarComMudancaDeStatusBroker);
    _atualizarEstadoPodeDarPop();
    _observadorKeController.addListener(() => _dadosExperimento.atualizarValor(
        'observadorKe', _observadorKeController.text));
    _reguladorKController.addListener(() => _dadosExperimento.atualizarValor(
        'reguladorK', _reguladorKController.text));
    _nxController.addListener(
        () => _dadosExperimento.atualizarValor('nx', _nxController.text));
    _nuController.addListener(
        () => _dadosExperimento.atualizarValor('nu', _nuController.text));
    _referenciaController.addListener(() => _dadosExperimento.atualizarValor(
        'referencia', _referenciaController.text));
  }

  @override
  void dispose() {
    _observadorKeController.dispose();
    _reguladorKController.dispose();
    _nxController.dispose();
    _nuController.dispose();
    _referenciaController.dispose();
    _dadosExperimento.definirCallbackAoMudarDados(null);
    _brokerInfo.statusNotifier.removeListener(_lidarComMudancaDeStatusBroker);
    super.dispose();
  }

  void _lidarComMudancaDeStatusBroker() {
    if (mounted) {
      setState(() {});
    }
  }

  void _carregarDadosNosControladores() {
    _dadosExperimento.carregarValoresNosControladores(
      obsCtrl: _observadorKeController,
      regCtrl: _reguladorKController,
      nxCtrl: _nxController,
      nuCtrl: _nuController,
      refCtrl: _referenciaController,
    );
  }

  void _lidarComMudancaDeDados() {
    if (mounted) {
      setState(() {
        _atualizarEstadoPodeDarPop();
      });
    }
  }

  void _atualizarEstadoPodeDarPop() {
    _podeDarPopNaTela = !_dadosExperimento.possuiAlteracoesNaoSalvas;
  }

  void _mostrarDialogoInformacaoEstilizado(
      BuildContext context, String titulo, List<InlineSpan> contentSpans) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 80,
                child: Lottie.asset('assets/Ideia.json'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(titulo,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(color: theme.colorScheme.primary))),
                ],
              ),
              const Divider(height: 25, thickness: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: contentSpans,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('FECHAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoErro(BuildContext context, String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        title: Row(children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 10),
          const Text('Erro')
        ]),
        content: Text(mensagem, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarDadosParaBroker(BuildContext context) async {
    final theme = Theme.of(context);
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _mostrarDialogoErro(context, 'Sem conexão com a Internet!');
      return;
    }
    if (_brokerInfo.status != 'Conectado') {
      _mostrarDialogoErro(context,
          'Não conectado ao Broker MQTT. Por favor, conecte-se primeiro na tela "Broker".');
      return;
    }
    final campos = {
      'observadorKe': _observadorKeController.text.trim(),
      'reguladorK': _reguladorKController.text.trim(),
      'nx': _nxController.text.trim(),
      'nu': _nuController.text.trim(),
      'referencia': _referenciaController.text.trim(),
    };
    if (campos.values.any((valor) => valor.isEmpty)) {
      _mostrarDialogoErro(context, 'Preencha todos os campos antes de enviar!');
      return;
    }
    try {
      for (var entry in campos.entries) {
        try {
          double valorDouble = double.parse(entry.value.replaceAll(',', '.'));
          _brokerInfo.publish(entry.key, valorDouble.toString());
        } catch (e) {
          _mostrarDialogoErro(context,
              'Valor inválido no campo "${entry.key}". Insira um número válido.');
          return;
        }
      }
      _dadosExperimento.marcarComoEnviadoComSucesso();
      showDialog(
        context: context,
        builder: (contextoDialogo) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Row(children: [
            Icon(Icons.check_circle_outline,
                color: theme.colorScheme.secondary),
            const SizedBox(width: 10),
            const Text('Sucesso!')
          ]),
          content: const Text('Dados enviados com sucesso para o Broker!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(contextoDialogo);
                Navigator.pushReplacement(
                    context, FadePageRoute(child: const Experimento()));
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _mostrarDialogoErro(context, 'Erro ao enviar dados para o Broker: $e');
    }
  }

  TextSpan _buildInfoTitle(String text) {
    return TextSpan(
      text: '\n$text\n',
      style: const TextStyle(fontWeight: FontWeight.bold, height: 1.8),
    );
  }

  TextSpan _buildEquationText(String equation, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextSpan(
      text: '$equation\n',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 15,
        backgroundColor:
            isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        height: 1.5,
      ),
    );
  }

  TextSpan _buildBodyText(String text) {
    return TextSpan(text: '$text\n', style: const TextStyle(height: 1.5));
  }

  Widget _construirCampoDeTexto(String rotulo, TextEditingController controller,
      IconData icone, VoidCallback aoPressionarInfo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: rotulo,
          prefixIcon: Icon(icone, color: Theme.of(context).colorScheme.primary),
          suffixIcon: IconButton(
            icon: Icon(Icons.help_outline, color: Colors.grey.shade500),
            onPressed: aoPressionarInfo,
            tooltip: 'Mais informações sobre $rotulo',
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[,.]?\d*')),
          LengthLimitingTextInputFormatter(15)
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 24.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                'Você tem alterações não salvas. Deseja descartá-las e sair?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(contextoDialogo, 'cancelar'),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(contextoDialogo, 'descartar_e_sair'),
                style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
                child: const Text('Descartar e Sair'),
              ),
            ],
          ),
        );
        if (mounted && resultado == 'descartar_e_sair') {
          _carregarDadosNosControladores();
          _dadosExperimento.marcarComoEnviadoComSucesso();
          if (mounted) {
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
          title: const Text('Dados do Experimento'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Parâmetros de Controle'),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _construirCampoDeTexto(
                              'Observador Ke',
                              _observadorKeController,
                              Icons.visibility_outlined,
                              () => _mostrarDialogoInformacaoEstilizado(
                                  context, 'Observador de Estados (Ke)', [
                                _buildBodyText(
                                    'Estima as variáveis de estado não medidas diretamente. O ganho Ke é crucial para a dinâmica do erro de estimação.'),
                                _buildInfoTitle('1. Dinâmica do Erro (ε):'),
                                _buildEquationText(
                                    'ε_ponto(t) = (A - Ke*C) * ε(t)', context),
                                _buildInfoTitle('2. Alocação de Polos:'),
                                _buildBodyText(
                                    'Defina os polos para a dinâmica do erro (ex: s = -p1).'),
                                _buildEquationText(
                                    '|sI - (A - Ke*C)| = s + p1 = 0', context),
                                _buildInfoTitle(
                                    '3. Parâmetros do Tanque (Exemplo):'),
                                _buildBodyText(
                                    'Com A = -0.006 e C = 1, resolva a equação para encontrar Ke.'),
                              ]),
                            ),
                            _construirCampoDeTexto(
                              'Regulador K',
                              _reguladorKController,
                              Icons.tune_outlined,
                              () => _mostrarDialogoInformacaoEstilizado(
                                  context, 'Regulador por Realimentação (K)', [
                                _buildBodyText(
                                    'Ajusta as entradas de controle com base nos estados para atingir o comportamento desejado.'),
                                _buildInfoTitle('1. Lei de Controle:'),
                                _buildEquationText('u(t) = -K * x(t)', context),
                                _buildInfoTitle('2. Sistema em Malha Fechada:'),
                                _buildEquationText(
                                    'x_ponto(t) = (A - B*K) * x(t)', context),
                                _buildInfoTitle('3. Alocação de Polos:'),
                                _buildBodyText(
                                    'Defina os polos para o sistema (ex: s = -q1).'),
                                _buildEquationText(
                                    '|sI - (A - B*K)| = s + q1 = 0', context),
                                _buildInfoTitle(
                                    '4. Parâmetros do Sistema (Exemplo):'),
                                _buildBodyText(
                                    'Com A = -0.006 e B = 0.002, resolva para encontrar o ganho K.'),
                              ]),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _construirCampoDeTexto(
                                    'Nx',
                                    _nxController,
                                    Icons.analytics_outlined,
                                    () => _mostrarDialogoInformacaoEstilizado(
                                        context, 'Número de Estados (Nx)', [
                                      _buildBodyText(
                                          'Nx é o número mínimo de variáveis (vetor x(t)) para descrever o estado interno do sistema.'),
                                      _buildInfoTitle('Modelo do Tanque:'),
                                      _buildEquationText(
                                          'dh/dt = -0.006*h + 0.002*u',
                                          context),
                                      _buildBodyText(
                                          'A única variável de estado é h (altura), portanto Nx=1.'),
                                      _buildInfoTitle('Espaço de Estados:'),
                                      _buildEquationText(
                                          'x_ponto = A*x + B*u', context),
                                      _buildEquationText(
                                          '[h_ponto] = [-0.006][h] + [0.002][u]',
                                          context),
                                    ]),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _construirCampoDeTexto(
                                    'Nu',
                                    _nuController,
                                    Icons.input_outlined,
                                    () => _mostrarDialogoInformacaoEstilizado(
                                        context, 'Número de Entradas (Nu)', [
                                      _buildBodyText(
                                          'Nu é o número de sinais de controle independentes (vetor u(t)).'),
                                      _buildInfoTitle('Modelo do Tanque:'),
                                      _buildEquationText(
                                          'dh/dt = -0.006*h + 0.002*u',
                                          context),
                                      _buildBodyText(
                                          'A única entrada de controle é u (vazão), portanto Nu=1.'),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildSectionTitle('Sinal de Referência'),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _construirCampoDeTexto(
                          'Referência (r)',
                          _referenciaController,
                          Icons.flag_outlined,
                          () => _mostrarDialogoInformacaoEstilizado(
                              context, 'Referência do Sistema (r)', [
                            _buildBodyText(
                                'A referência (setpoint) é o valor desejado para a saída do sistema (ex: altura do nível da água em cm).'),
                            _buildInfoTitle('Lei de Controle com Referência:'),
                            _buildEquationText(
                                'u(t) = -K * x_chapeu(t) + Nu_r * r', context),
                            _buildBodyText(
                                'Onde x_chapeu(t) é o estado estimado e Nu_r é um ganho de pré-compensação para garantir erro zero em regime permanente.'),
                          ]),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      topRight: Radius.circular(20))),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Enviar Dados para Experimento'),
                onPressed: _brokerInfo.status == 'Conectado'
                    ? () => _enviarDadosParaBroker(context)
                    : null,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: _brokerInfo.status == 'Conectado'
                        ? theme.colorScheme.secondary
                        : Colors.grey.shade400,
                    foregroundColor: _brokerInfo.status == 'Conectado'
                        ? theme.colorScheme.onSecondary
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0))),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _construirBarraNavegacaoInferior(),
      ),
    );
  }

  Widget _construirBarraNavegacaoInferior() {
    return NavigationBar(
      selectedIndex: 2,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(
                  context, FadePageRoute(child: const IntegrantesScreen()));
            });
            break;
          case 1:
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(
                  context, FadePageRoute(child: const ConectaBroker()));
            });
            break;
          case 2:
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
    if (_dadosExperimento.possuiAlteracoesNaoSalvas) {
      final resultado = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (contextoDialogo) => AlertDialog(
          title: const Text('Alterações Não Salvas'),
          content: const Text(
              'Você tem alterações não salvas. Deseja descartá-las antes de prosseguir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, 'cancelar'),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, 'descartar'),
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Descartar e Prosseguir'),
            ),
          ],
        ),
      );
      if (resultado == 'descartar') {
        _carregarDadosNosControladores();
        _dadosExperimento.marcarComoEnviadoComSucesso();
        acaoNavegar();
      }
    } else {
      acaoNavegar();
    }
  }
}
