// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'broker.dart';

import 'experimento.dart';
import 'dados_integrantes.dart';

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

  final Color _corPrimaria = const Color.fromRGBO(19, 85, 156, 1);
  final Color _corTextoBotaoBranco = Colors.white;
  final Color _corDestaqueVerde = const Color.fromARGB(255, 15, 220, 22);

  final TextStyle _infoDialogTextStyle =
      const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5);
  final TextStyle _infoDialogTitleStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      height: 1.5);

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
      BuildContext context, String titulo, List<Widget> widgetsConteudo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: _corPrimaria, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(titulo,
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: _corPrimaria)),
                  ),
                ],
              ),
              const Divider(height: 25, thickness: 1),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widgetsConteudo,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('FECHAR',
                      style: TextStyle(
                          color: _corPrimaria,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
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
        title: Row(children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 10),
          const Text('Erro')
        ]),
        content: Text(mensagem, style: const TextStyle(fontSize: 16)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: TextStyle(
                    color: _corPrimaria, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarDadosParaBroker(BuildContext context) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
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
          title: Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade700),
            const SizedBox(width: 10),
            const Text('Sucesso!')
          ]),
          content: const Text('Dados enviados com sucesso para o Broker!'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(contextoDialogo);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Experimento()),
                );
              },
              child: Text('OK',
                  style: TextStyle(
                      color: _corPrimaria, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      _mostrarDialogoErro(context, 'Erro ao enviar dados para o Broker: $e');
    }
  }

  InputDecoration _decoracaoCampoTextoEstilizada(String rotulo,
      {IconData? iconePrefixo, VoidCallback? onInfoPressed}) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: TextStyle(color: _corPrimaria.withOpacity(0.9)),
      prefixIcon: iconePrefixo != null
          ? Icon(iconePrefixo, color: _corPrimaria.withOpacity(0.7))
          : null,
      suffixIcon: onInfoPressed != null
          ? IconButton(
              icon: Icon(Icons.help_outline,
                  color: _corPrimaria.withOpacity(0.7)),
              onPressed: onInfoPressed,
              tooltip: 'Mais informações sobre $rotulo',
            )
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

  Widget _construirCampoDeTexto(String rotulo, TextEditingController controller,
      IconData icone, VoidCallback aoPressionarInfo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: _decoracaoCampoTextoEstilizada(rotulo,
            iconePrefixo: icone, onInfoPressed: aoPressionarInfo),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
          LengthLimitingTextInputFormatter(15)
        ],
      ),
    );
  }

  Widget _buildInfoText(String text, {TextStyle? style, bool isTitle = false}) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: isTitle ? 4.0 : 8.0, top: isTitle ? 8.0 : 0),
      child: Text(text,
          style: style ??
              (isTitle ? _infoDialogTitleStyle : _infoDialogTextStyle)),
    );
  }

  Widget _buildEquationText(String equation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          equation,
          style: const TextStyle(
              fontFamily: 'monospace', fontSize: 15, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'Você tem alterações não salvas nos dados do experimento. Deseja descartá-las e sair?'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
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
            ],
          ),
        );

        if (mounted && resultado == 'descartar_e_sair') {
          _carregarDadosNosControladores();
          _dadosExperimento.marcarComoEnviadoComSucesso();

          if (mounted) {
            setState(() {
              _podeDarPopNaTela = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context);
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Dados do Experimento',
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
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
                child: Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                                  _buildInfoText(
                                      'O observador de estados estima as variáveis de estado do sistema que não são medidas diretamente.\n O ganho Ke é crucial para a dinâmica do erro de estimação.\n'),
                                  _buildInfoText('Passos para determinar Ke:',
                                      isTitle: true),
                                  _buildInfoText(
                                      '1. Equação dinâmica do erro (ε):',
                                      isTitle: true),
                                  _buildEquationText('ε(t) = (A - Ke*C)*ε(t)'),
                                  _buildInfoText(
                                      '2. Alocação de Polos Desejada:',
                                      isTitle: true),
                                  _buildInfoText(
                                      '   Defina os polos para a dinâmica do erro (ex: s = -p1). Para um sistema de 1ª ordem, um polo em s = -1 significa que o erro decai rapidamente.'),
                                  _buildEquationText(
                                      '|sI - (A - Ke*C)| = s + p1 = 0'),
                                  _buildInfoText(
                                      '3. Parâmetros do Tanque (Exemplo Eq.6):',
                                      isTitle: true),
                                  _buildInfoText('   A = -0.006, C = 1'),
                                  _buildInfoText(
                                      'Resolva a equação característica para encontrar Ke.'),
                                ]),
                              ),
                              _construirCampoDeTexto(
                                'Regulador K',
                                _reguladorKController,
                                Icons.tune_outlined,
                                () => _mostrarDialogoInformacaoEstilizado(
                                    context,
                                    'Regulador por Realimentação (K)', [
                                  _buildInfoText(
                                      'O regulador K ajusta as entradas de controle com base nos estados para atingir o comportamento desejado.\n'),
                                  _buildInfoText('Passos para determinar K:',
                                      isTitle: true),
                                  _buildInfoText(
                                      '1. Lei de Controle (sem referência, para regulação):',
                                      isTitle: true),
                                  _buildEquationText('u(t) = -K*x(t)'),
                                  _buildInfoText('2. Sistema em Malha Fechada:',
                                      isTitle: true),
                                  _buildEquationText(
                                      'x_ponto(t) = (A - B*K)*x(t)'),
                                  _buildInfoText(
                                      '3. Alocação de Polos Desejada:',
                                      isTitle: true),
                                  _buildInfoText(
                                      '   Defina os polos para o sistema em malha fechada (ex: s = -q1). Um polo em s = -0.1 pode ser um bom ponto de partida.'),
                                  _buildEquationText(
                                      '|sI - (A - B*K)| = s + q1 = 0'),
                                  _buildInfoText(
                                      '4. Parâmetros do Sistema (Exemplo):',
                                      isTitle: true),
                                  _buildInfoText('   A = -0.006, B = 0.002'),
                                  _buildInfoText(
                                      'Resolva para encontrar o ganho K.'),
                                ]),
                              ),
                              _construirCampoDeTexto(
                                'Nº de Estados (Nx)',
                                _nxController,
                                Icons.analytics_outlined,
                                () => _mostrarDialogoInformacaoEstilizado(
                                    context, 'Número de Estados (Nx)', [
                                  _buildInfoText(
                                      'Nx é o número mínimo de variáveis (vetor de estado x(t)) para descrever o estado interno do sistema.\n',
                                      style: _infoDialogTextStyle),
                                  _buildInfoText('Modelo do Tanque (Eq.6):',
                                      style: _infoDialogTitleStyle),
                                  _buildEquationText(
                                      'dh/dt = -0.006*h + 0.002*u'),
                                  _buildInfoText(
                                      'A única variável de estado é h (altura).\n',
                                      style: _infoDialogTextStyle),
                                  _buildInfoText('Espaço de Estados:',
                                      style: _infoDialogTitleStyle),
                                  _buildEquationText(
                                      'x_ponto = A*x + B*u  =>  [h_ponto] = [-0.006][h] + [0.002][u]'),
                                ]),
                              ),
                              _construirCampoDeTexto(
                                'Nº de Entradas (Nu)',
                                _nuController,
                                Icons.input_outlined,
                                () => _mostrarDialogoInformacaoEstilizado(
                                    context, 'Número de Entradas (Nu)', [
                                  _buildInfoText(
                                      'Nu é o número de sinais de controle independentes (vetor de entrada u(t)).\n',
                                      style: _infoDialogTextStyle),
                                  _buildInfoText('Modelo do Tanque (Eq.6):',
                                      style: _infoDialogTitleStyle),
                                  _buildEquationText(
                                      'dh/dt = -0.006*h + 0.002*u'),
                                  _buildInfoText(
                                      'A única entrada de controle é u (vazão).\n',
                                      style: _infoDialogTextStyle),
                                  _buildInfoText('Espaço de Estados:',
                                      style: _infoDialogTitleStyle),
                                  _buildEquationText(
                                      'x_ponto = Ax + Bu  =>  [h_ponto] = [-0.006][h] + [0.002][u]'),
                                  _buildInfoText(
                                      'A matriz de entrada B é [0.002] (1 coluna).\n',
                                      style: _infoDialogTextStyle),
                                ]),
                              ),
                              _construirCampoDeTexto(
                                'Referência (r)',
                                _referenciaController,
                                Icons.flag_outlined,
                                () => _mostrarDialogoInformacaoEstilizado(
                                    context, 'Referência do Sistema (r)', [
                                  _buildInfoText(
                                      'A referência (setpoint) é o valor desejado para a saída do sistema (altura do nível da água).\n',
                                      style: _infoDialogTextStyle),
                                  _buildInfoText('Exemplo:',
                                      style: _infoDialogTitleStyle),
                                  _buildInfoText(
                                      '   Se o objetivo é manter o nível em 10 cm, r = 10.\n',
                                      style: _infoDialogTextStyle),
                                  _buildInfoText(
                                      'Para controle com rastreamento de referência, a lei de controle pode ser:',
                                      style: _infoDialogTextStyle),
                                  _buildEquationText(
                                      'u(t) = -Kx_chapeu(t) + Nu*r'),
                                  _buildInfoText(
                                      'Onde x_chapeu(t) é o estado estimado e Nu é um ganho de pré-compensação para garantir erro zero em regime permanente.',
                                      style: _infoDialogTextStyle),
                                ]),
                              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 5,
                      offset: const Offset(0, -2)),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Enviar Dados para Experimento'),
                onPressed: _brokerInfo.status == 'Conectado'
                    ? () => _enviarDadosParaBroker(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brokerInfo.status == 'Conectado'
                      ? _corDestaqueVerde
                      : Colors.grey.shade400,
                  foregroundColor: _corTextoBotaoBranco,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  elevation: _brokerInfo.status == 'Conectado' ? 2 : 0,
                ),
              ),
            ),
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
          _buildNavBarItem(Icons.group_outlined, 'Integrantes', () {
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const IntegrantesScreen()));
            });
          }),
          _buildNavBarItem(Icons.cloud_outlined, 'Broker', () {
            _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ConectaBroker()));
            });
          }),
          _buildNavBarItem(Icons.assignment, 'Dados Exp.', () {
            _carregarDadosNosControladores();
            _dadosExperimento.marcarComoEnviadoComSucesso();
          }, isActive: true),
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
    if (_dadosExperimento.possuiAlteracoesNaoSalvas) {
      final resultado = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (contextoDialogo) => AlertDialog(
          title: const Text('Alterações Não Salvas'),
          content: const Text(
              'Você tem alterações não salvas nos dados do experimento. Deseja descartá-las antes de prosseguir?'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, 'descartar'),
              child: const Text('Descartar e Prosseguir'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(contextoDialogo, 'cancelar'),
              child: const Text('Cancelar'),
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
