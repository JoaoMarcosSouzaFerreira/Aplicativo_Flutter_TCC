// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:laboratorio_controle/main.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';
import 'dados_integrantes.dart';
import 'dadosexperimento.dart';
import 'experimento.dart';

class IpAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    text = text.replaceAll(RegExp(r'[^\d]'), '');

    StringBuffer newTextBuffer = StringBuffer();
    int digitCounter = 0;
    int dotCounter = 0;

    for (int i = 0; i < text.length; i++) {
      if (digitCounter < 3) {
        newTextBuffer.write(text[i]);
        digitCounter++;
      }
      if (digitCounter == 3 && i < text.length - 1 && dotCounter < 3) {
        if (text.length > i + 1) {
          newTextBuffer.write('.');
          dotCounter++;
          digitCounter = 0;
        }
      }
    }

    String proposed = newTextBuffer.toString();
    if (proposed.length > 15) {
      proposed = proposed.substring(0, 15);
    }

    return TextEditingValue(
      text: proposed,
      selection: TextSelection.collapsed(offset: proposed.length),
    );
  }
}

class BrokerInfo {
  static final BrokerInfo instance = BrokerInfo._internal();
  factory BrokerInfo() => instance;
  BrokerInfo._internal();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  MqttServerClient? client;

  String ip = '';
  int porta = 1883;
  String usuario = '';
  String senha = '';
  bool credenciais = true;

  ValueNotifier<String> statusNotifier = ValueNotifier<String>('Desconectado');
  String get status => statusNotifier.value;
  set status(String newStatus) => statusNotifier.value = newStatus;

  bool hasUnsavedChanges(
      TextEditingController ipCtrl,
      TextEditingController portCtrl,
      TextEditingController userCtrl,
      TextEditingController passCtrl,
      bool currentScreenCredenciais) {
    if (status == 'Conectado' ||
        status == 'Conectando...' ||
        status == 'Reconectando...') {
      return false;
    }

    bool ipChanged = ipCtrl.text.trim() != ip;
    int screenPort = int.tryParse(portCtrl.text.trim()) ?? 1883;
    bool portChanged = screenPort != porta;
    bool credenciaisChanged = currentScreenCredenciais != credenciais;

    bool userChanged = false;
    bool passChanged = false;

    if (currentScreenCredenciais) {
      userChanged = userCtrl.text.trim() != usuario;
      passChanged = passCtrl.text.trim() != senha;
      return ipChanged ||
          portChanged ||
          credenciaisChanged ||
          userChanged ||
          passChanged;
    } else {
      return ipChanged || portChanged || credenciaisChanged;
    }
  }

  Future<void> connect({
    required String newIp,
    required int newPorta,
    required String newUsuario,
    required String newSenha,
    required bool newCredenciais,
  }) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      status = 'Sem internet';
      _showErrorDialog('Erro de Conectividade',
          'Sem conexão com a internet. Verifique sua rede e tente novamente.');
      return;
    }

    try {
      ip = newIp;
      porta = newPorta;
      usuario = newUsuario;
      senha = newSenha;
      credenciais = newCredenciais;

      client = MqttServerClient(
          ip, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
      client!
        ..port = porta
        ..logging(on: false)
        ..keepAlivePeriod = 30
        ..autoReconnect = true
        ..resubscribeOnAutoReconnect = true
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onAutoReconnect = _onAutoReconnect
        ..onAutoReconnected = _onAutoReconnected;

      status = 'Conectando...';

      if (credenciais) {
        await client!.connect(usuario, senha);
      } else {
        await client!.connect();
      }
    } catch (e) {
      status = 'Erro de conexão';
      _showErrorDialog('Falha na Conexão',
          'Não foi possível conectar ao broker: ${e.toString()}');
    }
  }

  Future<void> disconnect() async {
    client?.disconnect();
  }

  void _onConnected() {
    status = 'Conectado';
    _subscribeToTopics();
  }

  void _onDisconnected() {
    status = 'Desconectado';
  }

  void _onAutoReconnect() {
    status = 'Reconectando...';
  }

  void _onAutoReconnected() {
    status = 'Conectado';
    _subscribeToTopics();
  }

  void _subscribeToTopics() {
    client?.subscribe('observadorKe', MqttQos.atLeastOnce);
    client?.subscribe('reguladorK', MqttQos.atLeastOnce);
    client?.subscribe('nx', MqttQos.atLeastOnce);
    client?.subscribe('nu', MqttQos.atLeastOnce);

    client?.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      // ignore: unused_local_variable
      for (var msg in messages) {}
    });
  }

  void publish(String topic, String message) {
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      _publishMessage(topic, message);
    } else {
      _showErrorDialog('Não Conectado',
          'Não é possível publicar. Cliente MQTT não conectado.');
    }
  }

  void _publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client?.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _showErrorDialog(String title, String message) {
    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class ConectaBroker extends StatefulWidget {
  const ConectaBroker({super.key});

  @override
  State<ConectaBroker> createState() => _ConectaBrokerState();
}

class _ConectaBrokerState extends State<ConectaBroker> {
  final TextEditingController _ipControler = TextEditingController();
  final TextEditingController _portaControler = TextEditingController();
  final TextEditingController _usuarioControler = TextEditingController();
  final TextEditingController _senhaControler = TextEditingController();
  final BrokerInfo _brokerInfo = BrokerInfo.instance;

  bool _isLoading = false;
  bool _podeDarPopNaTelaBroker = true;
  bool _credenciaisAtivasNaTela = true;

  final Color _corPrimaria = const Color.fromRGBO(19, 85, 156, 1);
  final Color _corTextoBotaoBranco = Colors.white;
  final Color _corDestaqueVerde = const Color.fromARGB(255, 15, 220, 22);
  final Color _corDestaqueVermelho = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    _carregarDadosBrokerNosControladores();

    _ipControler.addListener(_atualizarEstadoPodeDarPop);
    _portaControler.addListener(_atualizarEstadoPodeDarPop);
    _usuarioControler.addListener(_atualizarEstadoPodeDarPop);
    _senhaControler.addListener(_atualizarEstadoPodeDarPop);
    _brokerInfo.statusNotifier.addListener(_lidarComMudancaDeStatusBroker);

    _atualizarEstadoPodeDarPop();
  }

  @override
  void dispose() {
    _ipControler.removeListener(_atualizarEstadoPodeDarPop);
    _portaControler.removeListener(_atualizarEstadoPodeDarPop);
    _usuarioControler.removeListener(_atualizarEstadoPodeDarPop);
    _senhaControler.removeListener(_atualizarEstadoPodeDarPop);
    _brokerInfo.statusNotifier.removeListener(_lidarComMudancaDeStatusBroker);

    _ipControler.dispose();
    _portaControler.dispose();
    _usuarioControler.dispose();
    _senhaControler.dispose();
    super.dispose();
  }

  void _carregarDadosBrokerNosControladores() {
    _ipControler.text = _brokerInfo.ip;
    _portaControler.text = _brokerInfo.porta.toString();
    _usuarioControler.text = _brokerInfo.usuario;
    _senhaControler.text = _brokerInfo.senha;
    if (mounted) {
      setState(() {
        _credenciaisAtivasNaTela = _brokerInfo.credenciais;
      });
    } else {
      _credenciaisAtivasNaTela = _brokerInfo.credenciais;
    }
  }

  void _lidarComMudancaDeStatusBroker() {
    if (mounted) {
      setState(() {
        if (_brokerInfo.status == 'Desconectado') {
          _carregarDadosBrokerNosControladores();
        }
        _atualizarEstadoPodeDarPop();
      });
    }
  }

  void _atualizarEstadoPodeDarPop() {
    if (_brokerInfo.status == 'Conectado' ||
        _brokerInfo.status == 'Conectando...' ||
        _brokerInfo.status == 'Reconectando...') {
      _podeDarPopNaTelaBroker = false;
    } else {
      _podeDarPopNaTelaBroker = !_brokerInfo.hasUnsavedChanges(
          _ipControler,
          _portaControler,
          _usuarioControler,
          _senhaControler,
          _credenciaisAtivasNaTela);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _conectarAoBroker() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none && mounted) {
      _mostrarDialogoSimples('Sem Internet',
          'Verifique sua conexão com a internet e tente novamente.');
      return;
    }

    setState(() => _isLoading = true);
    await _brokerInfo.connect(
      newIp: _ipControler.text.trim(),
      newPorta: int.tryParse(_portaControler.text.trim()) ?? 1883,
      newUsuario: _usuarioControler.text.trim(),
      newSenha: _senhaControler.text.trim(),
      newCredenciais: _credenciaisAtivasNaTela,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (_brokerInfo.status == 'Conectado' && mounted) {
      showDialog(
        context: context,
        builder: (contextoDialogo) => AlertDialog(
          title: const Text('Sucesso!'),
          content: const Text('Conectado ao broker MQTT com sucesso.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(contextoDialogo);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DadosExperimentos()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _desconectarDoBroker() async {
    setState(() => _isLoading = true);
    await _brokerInfo.disconnect();
    if (mounted) {
      setState(() => _isLoading = false);
      if (_brokerInfo.status == 'Desconectado') {
        _mostrarDialogoSimples(
            'Desconectado', 'Você foi desconectado do broker.');
      }
    }
  }

  void _mostrarDialogoSimples(String titulo, String mensagem) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (contextoDialogo) => AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contextoDialogo).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  InputDecoration _decoracaoCampoTextoEstilizada(String rotulo,
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
    return ValueListenableBuilder<String>(
        valueListenable: _brokerInfo.statusNotifier,
        builder: (context, statusAtualBroker, child) {
          bool camposEstaoAtivos = statusAtualBroker != 'Conectado' &&
              statusAtualBroker != 'Conectando...' &&
              statusAtualBroker != 'Reconectando...';
          return PopScope(
            canPop: _podeDarPopNaTelaBroker,
            onPopInvoked: (bool didPop) async {
              if (didPop) return;

              String dialogTitle = 'Sair da Tela?';
              String dialogContent =
                  'Você tem dados não utilizados para conexão. Deseja descartá-los e sair?';
              String confirmActionText = 'Descartar e Sair';
              bool isConectado = statusAtualBroker == 'Conectado';

              if (isConectado) {
                dialogTitle = 'Desconectar?';
                dialogContent =
                    'Você está conectado ao broker. Deseja desconectar e sair desta tela?';
                confirmActionText = 'Desconectar e Sair';
              }

              final resultado = await showDialog<String>(
                context: context,
                barrierDismissible: false,
                builder: (contextoDialogo) => AlertDialog(
                  title: Text(dialogTitle),
                  content: Text(dialogContent),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(contextoDialogo, 'cancelar'),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(contextoDialogo, 'confirmar_sair'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isConectado ? _corDestaqueVermelho : _corPrimaria,
                          foregroundColor: _corTextoBotaoBranco),
                      child: Text(confirmActionText),
                    ),
                  ],
                ),
              );

              if (mounted && resultado == 'confirmar_sair') {
                if (isConectado) {
                  await _desconectarDoBroker();
                }
                if (mounted) {
                  setState(() {
                    _podeDarPopNaTelaBroker = true;
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
                title: const Text('Informações do Broker',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                centerTitle: true,
                backgroundColor: _corPrimaria,
                elevation: 2,
              ),
              drawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: _corPrimaria),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Broker MQTT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(children: [
                            Icon(
                                statusAtualBroker == 'Conectado'
                                    ? Icons.cloud_done
                                    : statusAtualBroker == 'Conectando...' ||
                                            statusAtualBroker ==
                                                'Reconectando...'
                                        ? Icons.cloud_sync
                                        : Icons.cloud_off,
                                color: Colors.white,
                                size: 20),
                            const SizedBox(width: 8),
                            Text('Status: $statusAtualBroker',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ]),
                          if (statusAtualBroker == 'Conectado') ...[
                            const SizedBox(height: 5),
                            Text('IP: ${_brokerInfo.ip}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ]
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.home_outlined, color: _corPrimaria),
                      title: const Text('Tela Inicial'),
                      onTap: () {
                        Navigator.pop(context);

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const StartScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (statusAtualBroker == 'Conectado')
                            Card(
                              elevation: 2,
                              color: Colors.green.shade50,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.4,
                                      height: 100,
                                      child:
                                          Lottie.asset('assets/TudoCerto.json'),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Conectado ao Broker!',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _ipControler,
                                    decoration: _decoracaoCampoTextoEstilizada(
                                        'Endereço IP do Broker',
                                        iconePrefixo: Icons.router_outlined),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: false),
                                    inputFormatters: [
                                      IpAddressInputFormatter(),
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                    enabled: camposEstaoAtivos,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _portaControler,
                                    decoration: _decoracaoCampoTextoEstilizada(
                                        'Porta do Broker',
                                        iconePrefixo: Icons.lan_outlined),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(5),
                                    ],
                                    enabled: camposEstaoAtivos,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Autenticação:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: _corPrimaria)),
                                      Switch(
                                        value: _credenciaisAtivasNaTela,
                                        onChanged: camposEstaoAtivos
                                            ? (value) {
                                                setState(() {
                                                  _credenciaisAtivasNaTela =
                                                      value;
                                                  _atualizarEstadoPodeDarPop();
                                                });
                                              }
                                            : null,
                                        activeColor: _corPrimaria,
                                      ),
                                    ],
                                  ),
                                  if (_credenciaisAtivasNaTela) ...[
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      controller: _usuarioControler,
                                      decoration:
                                          _decoracaoCampoTextoEstilizada(
                                              'Usuário',
                                              iconePrefixo:
                                                  Icons.person_outline),
                                      enabled: camposEstaoAtivos,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _senhaControler,
                                      decoration:
                                          _decoracaoCampoTextoEstilizada(
                                              'Senha',
                                              iconePrefixo: Icons.lock_outline),
                                      obscureText: true,
                                      enabled: camposEstaoAtivos,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 5,
                            offset: const Offset(0, -2)),
                      ],
                    ),
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _corPrimaria)))
                        : ElevatedButton.icon(
                            icon: Icon(
                              statusAtualBroker == 'Conectado'
                                  ? Icons.cloud_off_outlined
                                  : Icons.cloud_upload_outlined,
                            ),
                            onPressed: () {
                              if (statusAtualBroker == 'Conectado') {
                                _desconectarDoBroker();
                              } else {
                                _conectarAoBroker();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: statusAtualBroker == 'Conectado'
                                  ? _corDestaqueVermelho
                                  : _corDestaqueVerde,
                              foregroundColor: _corTextoBotaoBranco,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              elevation: 2,
                            ),
                            label: Text(
                              statusAtualBroker == 'Conectado'
                                  ? 'Desconectar'
                                  : (statusAtualBroker == 'Conectando...' ||
                                          statusAtualBroker == 'Reconectando...'
                                      ? 'Conectando...'
                                      : 'Conectar ao Broker'),
                            ),
                          ),
                  ),
                ],
              ),
              bottomNavigationBar: _construirBarraNavegacaoInferior(),
            ),
          );
        });
  }

  Widget _buildNavBarItem(IconData icon, String label, VoidCallback onPressed,
      {bool isActive = false}) {
    final Color iconColor =
        isActive ? Colors.white : Colors.white.withOpacity(0.7);
    return IconButton(
      icon: Icon(icon, color: iconColor, size: isActive ? 28 : 24),
      tooltip: label,
      onPressed: onPressed,
    );
  }

  Widget _construirBarraNavegacaoInferior() {
    return Container(
      height: 60,
      decoration: BoxDecoration(color: _corPrimaria, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -1))
      ]),
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
          _buildNavBarItem(Icons.cloud, 'Broker', () {}, isActive: true),
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

  void _verificarAlteracoesAntesDeNavegarParaOutraTela(
      VoidCallback acaoNavegar) async {
    bool temAlteracoesInputs = _brokerInfo.hasUnsavedChanges(
        _ipControler,
        _portaControler,
        _usuarioControler,
        _senhaControler,
        _credenciaisAtivasNaTela);

    if (_brokerInfo.status == 'Conectado') {
      final resultado = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (contextoDialogo) => AlertDialog(
          title: const Text('Desconectar?'),
          content: const Text(
              'Você está conectado ao broker. Deseja desconectar antes de sair desta tela?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(contextoDialogo, 'cancelar'),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(contextoDialogo, 'desconectar_e_navegar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _corDestaqueVermelho,
                  foregroundColor: _corTextoBotaoBranco),
              child: const Text('Desconectar e Navegar'),
            ),
          ],
        ),
      );
      if (resultado == 'desconectar_e_navegar') {
        await _desconectarDoBroker();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) acaoNavegar();
        });
      }
    } else if (temAlteracoesInputs) {
      final resultado = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (contextoDialogo) => AlertDialog(
          title: const Text('Dados Não Utilizados'),
          content: const Text(
              'Você alterou os dados de conexão. Deseja descartá-los e prosseguir?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(contextoDialogo, 'cancelar'),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(contextoDialogo, 'descartar_e_navegar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _corPrimaria,
                  foregroundColor: _corTextoBotaoBranco),
              child: const Text('Descartar e Prosseguir'),
            ),
          ],
        ),
      );
      if (resultado == 'descartar_e_navegar') {
        _carregarDadosBrokerNosControladores();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) acaoNavegar();
        });
      }
    } else {
      acaoNavegar();
    }
  }
}
