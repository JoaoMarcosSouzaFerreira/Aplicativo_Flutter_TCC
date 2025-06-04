// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'broker.dart'; 
import 'dadosexperimento.dart'; 
import 'dados_integrantes.dart'; 
class Experimento extends StatefulWidget {
  const Experimento({super.key});

  @override
  State<Experimento> createState() => _ExperimentoState();
}

class _ExperimentoState extends State<Experimento> {
  final ExperimentoData _dadosExperimento = ExperimentoData();
  final BrokerInfo _brokerInfo = BrokerInfo.instance;

  final TextEditingController _referenciaController = TextEditingController();

  String _wifiStatus = 'N/A';
  String _brokerStatusESP = 'N/A';
  String _experimentoStatus = 'Parado';

  final List<Map<String, String>> _tableData = [];
  StreamSubscription? _mqttSubscription;

  bool _podeDarPopNaTela = true;
  bool _referenciaAlteradaNaoPublicada = false;

  Timer? _initialConnectionTimeoutTimer; 

  final Map<String, Map<String, String?>> _linhasDeDadosPendentes = {};
  String? _ultimoTempoRecebido;

  final Color _corPrimaria = const Color.fromRGBO(19, 85, 156, 1);
  final Color _corTextoBotaoBranco = Colors.white;
  final Color _corDestaqueVermelho = Colors.redAccent;
  final TextStyle _statusLabelStyle =
      const TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
  final TextStyle _statusValueStyle =
      const TextStyle(fontSize: 15, color: Colors.black87);

  late final TextStyle _infoDialogTitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: _corPrimaria);
  final TextStyle _infoDialogTextStyle =
      const TextStyle(fontSize: 16, color: Colors.black87);

  @override
  void initState() {
    super.initState();
    _carregarReferenciaInicial();
    _referenciaController.addListener(_onReferenciaChanged);

    _brokerInfo.statusNotifier.addListener(_lidarComMudancaDeStatusBrokerApp);
    _atualizarEstadoPodeDarPop();

    if (_brokerInfo.status == 'Conectado' && _brokerInfo.client != null) {
      _setupMqttListeners();
    } else {
      _wifiStatus = 'Verificando...';
      _brokerStatusESP =
          _brokerInfo.status == 'Desconectado' ? 'App Desconectado' : 'N/A';
      _attemptInitialBrokerConnectionWithTimeout(); 
    }
  }
  void _attemptInitialBrokerConnectionWithTimeout() {
    if (!mounted) return;
    print("Tela Experimento: Iniciando tentativa de conexão inicial com timeout de 10s.");
    _initialConnectionTimeoutTimer?.cancel(); 
    _initialConnectionTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_brokerInfo.status != 'Conectado') {
        print("Tela Experimento: Timeout de 10s para conexão inicial atingido.");
        if (mounted) { 
          _mostrarDialogoFalhaConexaoBroker();
          setState(() {
            _wifiStatus = 'Falha (Timeout)';
            _brokerStatusESP = 'App Desconectado (Timeout)';
            
          });
        }
      }
    });
  }
  void _mostrarDialogoFalhaConexaoBroker() {
    if (!mounted) return;
  
    _mqttSubscription?.cancel();
    _mqttSubscription = null;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (contextoDialogo) => AlertDialog(
        title: Row(children: [
          Icon(Icons.error_outline, color: _corDestaqueVermelho),
          const SizedBox(width: 10),
          const Text('Falha na Conexão')
        ]),
        content: const Text(
            'Não foi possível conectar ao broker MQTT em 10 segundos. Verifique as informações do broker e tente novamente, ou encerre o experimento.'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(contextoDialogo); 
              _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ConectaBroker()),
                );
              });
            },
            child: Text('Ir para Config. Broker', style: TextStyle(color: _corPrimaria)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(contextoDialogo); 
              _enviarComandoEncerramentoBroker(); 
              print("Encerrando experimento devido à falha de conexão com o broker.");
              if (mounted) {
                // Permite sair da tela
                setState(() { _podeDarPopNaTela = true; });
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.of(context).pop();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _corDestaqueVermelho,
              foregroundColor: _corTextoBotaoBranco,
            ),
            child: const Text('Encerrar Experimento'),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _referenciaController.removeListener(_onReferenciaChanged);
    _referenciaController.dispose();
    _brokerInfo.statusNotifier
        .removeListener(_lidarComMudancaDeStatusBrokerApp);
    _mqttSubscription?.cancel();
    _initialConnectionTimeoutTimer?.cancel();
    super.dispose();
  }

  void _carregarReferenciaInicial() {
    _referenciaController.text =
        _dadosExperimento.valoresAtuais['referencia'] ?? '';
    _referenciaAlteradaNaoPublicada = false;
    _atualizarEstadoPodeDarPop();
  }

  void _onReferenciaChanged() {
    if (!mounted) return;
    if (_referenciaController.text.trim() !=
        (_dadosExperimento.valoresAtuais['referencia'] ?? '')) {
      if (!_referenciaAlteradaNaoPublicada) {
        setState(() {
          _referenciaAlteradaNaoPublicada = true;
          _atualizarEstadoPodeDarPop();
        });
      }
    } else {
      if (_referenciaAlteradaNaoPublicada) {
        setState(() {
          _referenciaAlteradaNaoPublicada = false;
          _atualizarEstadoPodeDarPop();
        });
      }
    }
  }

  void _lidarComMudancaDeStatusBrokerApp() {
    if (mounted) {
      if (_brokerInfo.status == 'Conectado') {
        _initialConnectionTimeoutTimer?.cancel();
        print("Tela Experimento: Conexão com broker estabelecida via notifier.");
      }

      setState(() {
        _atualizarEstadoPodeDarPop();
        if (_brokerInfo.status == 'Conectado' && _brokerInfo.client != null) {
          if (_wifiStatus != 'Falha (Timeout)') {
          }
          _setupMqttListeners();
        } else {
          _mqttSubscription?.cancel();
          _mqttSubscription = null; 
          if (_wifiStatus != 'Falha (Timeout)') {
             _wifiStatus = 'N/A'; 
             _brokerStatusESP = _brokerInfo.status == 'Desconectado' ? 'App Desconectado' : 'N/A';
          }
          _experimentoStatus = 'Parado';
        }
      });
    }
  }

  void _atualizarEstadoPodeDarPop() {
    if (!mounted) return;
    bool novoPodeDarPop;
    if (_experimentoStatus.toLowerCase() == 'em andamento') {
      novoPodeDarPop = false;
    } else if (_referenciaAlteradaNaoPublicada) {
      novoPodeDarPop = false;
    } else {
      novoPodeDarPop = true;
    }

    if (_podeDarPopNaTela != novoPodeDarPop) {
      setState(() {
        _podeDarPopNaTela = novoPodeDarPop;
      });
    }
  }

  void _setupMqttListeners() {
    if (!mounted) return;
    _mqttSubscription?.cancel();

    if (_brokerInfo.client == null ||
        _brokerInfo.client!.connectionStatus!.state !=
            MqttConnectionState.connected) {
      print(
          "Tela Experimento: Cliente MQTT não conectado. Não é possível subscrever.");
      if (mounted) {
        if (_wifiStatus != 'Falha (Timeout)') {
            setState(() {
              _wifiStatus = 'Erro de Conexão';
              _brokerStatusESP = 'App Desconectado';
            });
        }
      }
      return;
    }

    print("Tela Experimento: Configurando listeners MQTT...");
    final topicsToSubscribe = {
      'estadoESPWifi': MqttQos.atMostOnce,
      'estadoESPBroker': MqttQos.atMostOnce,
      'estadoExperimento': MqttQos.atMostOnce,
      'tempo': MqttQos.atMostOnce,
      'nivel': MqttQos.atMostOnce,
      'tensao': MqttQos.atMostOnce,
      'estimado': MqttQos.atMostOnce,
    };

    topicsToSubscribe.forEach((topic, qos) {
      try {
        print("Tela Experimento: Subscrevendo ao tópico: $topic");
        _brokerInfo.client!.subscribe(topic, qos);
      } catch (e) {
        print("Tela Experimento: Erro ao subscrever ao tópico $topic: $e");
      }
    });

    _mqttSubscription = _brokerInfo.client!.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> c) {
      if (!mounted) return;
      for (final msg in c) {
        final payload = msg.payload as MqttPublishMessage;
        final topic = msg.topic;
        final message =
            MqttPublishPayload.bytesToStringAsString(payload.payload.message);

        if (mounted) {
          setState(() {
            if (topic == 'estadoESPWifi') {
              _wifiStatus = message;
            } else if (topic == 'estadoESPBroker') {
              _brokerStatusESP = message;
            } else if (topic == 'estadoExperimento') {
              _experimentoStatus = message;
              _atualizarEstadoPodeDarPop();
            } else if (['tempo', 'nivel', 'tensao', 'estimado']
                .contains(topic)) {
              _handleDataUpdate(topic, message);
            }
          });
        }
      }
    });
    print("Tela Experimento: Listeners MQTT configurados.");
  }

  void _handleDataUpdate(String type, String message) {
    if (!mounted) return;
    try {
      final String valorFormatado =
          double.parse(message.replaceAll(',', '.')).toStringAsFixed(1);

      if (type == 'tempo') {
        _ultimoTempoRecebido = valorFormatado;
        _linhasDeDadosPendentes.putIfAbsent(
            _ultimoTempoRecebido!,
            () => {
                  'tempo': _ultimoTempoRecebido,
                  'nivel': null,
                  'tensao': null,
                  'estimado': null,
                });
      } else if (_ultimoTempoRecebido != null &&
          _linhasDeDadosPendentes.containsKey(_ultimoTempoRecebido)) {
        _linhasDeDadosPendentes[_ultimoTempoRecebido!]?[type] = valorFormatado;
      }

      if (_ultimoTempoRecebido != null &&
          _linhasDeDadosPendentes.containsKey(_ultimoTempoRecebido)) {
        final linhaPendente = _linhasDeDadosPendentes[_ultimoTempoRecebido!]!;
        if (linhaPendente['tempo'] != null &&
            linhaPendente['nivel'] != null &&
            linhaPendente['tensao'] != null &&
            linhaPendente['estimado'] != null) {
          _tableData.add({
            'tempo': linhaPendente['tempo']!,
            'nivel': linhaPendente['nivel']!,
            'tensao': linhaPendente['tensao']!,
            'estimado': linhaPendente['estimado']!,
          });
          _linhasDeDadosPendentes.remove(_ultimoTempoRecebido);
          _ultimoTempoRecebido = null;

          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      print('Erro ao processar dado MQTT para tabela ($type: $message): $e');
    }
  }

  void _publicarReferencia() {
    if (!mounted) return;
    if (_referenciaController.text.trim().isEmpty) {
      _mostrarDialogoErro(
          context, 'O campo de referência não pode estar vazio.');
      return;
    }
    if (_brokerInfo.status != 'Conectado') {
      _mostrarDialogoErro(
          context, 'Não conectado ao Broker para publicar a referência.');
      return;
    }
    try {
      double valorDouble =
          double.parse(_referenciaController.text.trim().replaceAll(',', '.'));
      _brokerInfo.publish('referencia_app', valorDouble.toStringAsFixed(2));

      _dadosExperimento.atualizarValor(
          'referencia', _referenciaController.text.trim());
      _dadosExperimento.marcarComoEnviadoComSucesso();

      if (mounted) {
        setState(() {
          _referenciaAlteradaNaoPublicada = false;
          _atualizarEstadoPodeDarPop();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Referência (${valorDouble.toStringAsFixed(2)}) publicada com sucesso!'), // Atualiza a mensagem também
            backgroundColor: Colors.green),
      );
    } catch (e) {
      _mostrarDialogoErro(
          context, 'Valor de referência inválido. Insira um número válido.');
    }
  }

  void _confirmarEncerramentoExperimento() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Encerrar Experimento?'),
        content: const Text(
            'Deseja gerar um relatório em Excel com os dados coletados antes de sair da aplicação?'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(contextoDialogo);
              _sairSemRelatorio();
            },
            child: const Text('Sair sem Relatório'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(contextoDialogo);
              _gerarRelatorioESair();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _corPrimaria,
                foregroundColor: _corTextoBotaoBranco),
            child: const Text('Gerar Relatório e Sair'),
          ),
        ],
      ),
    );
  }

  void _enviarComandoEncerramentoBroker() {
    if (_brokerInfo.status == 'Conectado') {
      _brokerInfo.publish('encerraExperimento', 'ENCERRAR');
      print("Comando ENCERRAR enviado ao broker.");
    } else {
      print(
          "App não conectado ao broker. Não foi possível enviar comando ENCERRAR.");
    }
  }

  void _sairSemRelatorio() {
    _enviarComandoEncerramentoBroker();
    print("Saindo da aplicação sem relatório.");
    SystemNavigator.pop();
  }

  Future<void> _gerarRelatorioESair() async {
    if (!mounted) return;
    _enviarComandoEncerramentoBroker();
    print("Iniciando geração de relatório com os dados:");
    _tableData.forEach(print);

    var statusPermissao = await Permission.storage.request();
    if (Platform.isAndroid) {
      if (!statusPermissao.isGranted) {
        statusPermissao = await Permission.manageExternalStorage.request();
      }
    }

    if (statusPermissao.isGranted) {
      try {
        final excel = Excel.createExcel();
        final Sheet sheetObject = excel['DadosColetados'];

        sheetObject.appendRow(
            ['Tempo (s)', 'Nível (cm)', 'Tensão (V)', 'Nível Estimado (cm)']);

        for (var dataRow in _tableData) {
          sheetObject.appendRow([
            dataRow['tempo'] ?? '',
            dataRow['nivel'] ?? '',
            dataRow['tensao'] ?? '',
            dataRow['estimado'] ?? ''
          ]);
        }

        Directory? directory;
        if (Platform.isAndroid) {
          List<Directory>? dirs = await getExternalStorageDirectories(
              type: StorageDirectory.downloads);
          if (dirs != null && dirs.isNotEmpty) {
            directory = dirs.first;
          } else {
            directory = await getExternalStorageDirectory();
            if (directory != null) {
              String newPath = "${directory.path}/DownloadReports";
              directory = Directory(newPath);
            }
          }
        } else if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          final timestamp = DateTime.now()
              .toIso8601String()
              .replaceAll(':', '-')
              .replaceAll('.', '-');
          final filePath =
              '${directory.path}/Relatorio_Experimento_$timestamp.xlsx';

          print("Tentando salvar relatório em: $filePath");

          final fileBytes = excel.save();

          if (fileBytes != null) {
            File(filePath)
              ..createSync(recursive: true)
              ..writeAsBytesSync(fileBytes);

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Relatório salvo em: $filePath'),
              duration: const Duration(seconds: 7),
              action: SnackBarAction(
                label: 'ABRIR',
                onPressed: () {
                  OpenFilex.open(filePath);
                },
              ),
            ));
            await Future.delayed(const Duration(seconds: 3));
          } else {
            if (!mounted) return;
            _mostrarDialogoErro(
                context, 'Falha ao gerar os bytes do ficheiro Excel.');
          }
        } else {
          if (!mounted) return;
          _mostrarDialogoErro(context,
              'Não foi possível obter o diretório para salvar o ficheiro.');
        }
      } catch (e) {
        print("Erro ao gerar relatório Excel: $e");
        if (!mounted) return;
        _mostrarDialogoErro(
            context, 'Erro ao gerar relatório: ${e.toString()}');
      }
    } else {
      if (!mounted) return;
      _mostrarDialogoErro(context,
          'Permissão de armazenamento negada. Não é possível salvar o relatório.');
    }

    print("Saindo da aplicação após tentativa de gerar relatório.");
    SystemNavigator.pop();
  }

  void _mostrarDialogoErro(BuildContext context, String mensagem) {
    if (!mounted) return;
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

  void _mostrarDialogoInfoReferencia() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: Text('Informações sobre a Referência', style: _infoDialogTitleStyle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoText(
                'O que é a Referência de Nível?',
                isTitle: true,
              ),
              _buildInfoText(
                'A "Referência de Nível (cm)" é o valor desejado (setpoint) para o nível de água no tanque que o sistema de controle tentará alcançar e manter.',
              ),
              _buildInfoText(
                'Como funciona:',
                isTitle: true,
              ),
              _buildInfoText(
                '1. Você insere um valor numérico (ex: 10.5 cm).\n'
                '2. Ao publicar, este valor é enviado ao ESP32.\n'
                '3. O ESP32 utiliza essa referência em seu algoritmo de controle para ajustar a bomba ou válvulas.',
              ),
              _buildInfoText(
                'Exemplo de Formato:',
                isTitle: true,
              ),
              _buildEquationText('12.3 (para 12.3 cm)'),
              _buildInfoText(
                'Observações:',
                isTitle: true,
              ),
              _buildInfoText(
                '- Use ponto (.) como separador decimal.\n'
                '- O valor deve estar dentro dos limites operacionais do sistema (não especificado aqui, mas importante na prática).',
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo),
            child: Text('OK', style: TextStyle(color: _corPrimaria, fontWeight: FontWeight.bold)),
          ),
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

  Widget _construirStatusContainer() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status do Dispositivo e Experimento",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _corPrimaria)),
            const SizedBox(height: 12),
            _construirLinhaStatus(
                'WiFi ESP:',
                _wifiStatus,
                _wifiStatus.toLowerCase() == 'conectado'
                    ? Colors.green.shade700
                    : (_wifiStatus == 'Falha (Timeout)' ? Colors.red.shade700 : Colors.orange.shade700) // Ajuste para cor de timeout
                    ),
            const Divider(height: 16),
            _construirLinhaStatus(
                'Broker ESP:',
                _brokerStatusESP,
                 _brokerStatusESP.toLowerCase() == 'conectado'
                    ? Colors.green.shade700
                    : (_brokerStatusESP == 'App Desconectado (Timeout)' ? Colors.red.shade700 : Colors.orange.shade700) // Ajuste para cor de timeout
                    ),
            const Divider(height: 16),
            _construirLinhaStatus(
                'App ao Broker:',
                _brokerInfo.status,
                _brokerInfo.status == 'Conectado'
                    ? Colors.green.shade700
                    : (_brokerInfo.status == 'Conectando...' ||
                            _brokerInfo.status == 'Reconectando...'
                        ? Colors.orange.shade700
                        : Colors.red.shade700)),
            const Divider(height: 16),
            _construirLinhaStatus(
                'Experimento:',
                _experimentoStatus,
                _experimentoStatus.toLowerCase() == 'em andamento'
                    ? Colors.blue.shade700
                    : (_experimentoStatus.toLowerCase() == 'finalizado'
                        ? Colors.green.shade700
                        : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _construirLinhaStatus(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: _statusLabelStyle),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: valueColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Text(value.isNotEmpty ? value : 'N/A',
              style: _statusValueStyle.copyWith(
                  color: valueColor, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _construirCampoReferencia() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _referenciaController,
                decoration: _decoracaoCampoTextoEstilizada(
                  'Referência de Nível (cm)',
                  iconePrefixo: Icons.track_changes_outlined,
                  onInfoPressed: _mostrarDialogoInfoReferencia,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                  LengthLimitingTextInputFormatter(10)
                ],
                enabled: _brokerInfo.status == 'Conectado' &&
                    _experimentoStatus.toLowerCase() != 'finalizado',
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: (_brokerInfo.status == 'Conectado' &&
                      _referenciaController.text.isNotEmpty)
                  ? _publicarReferencia
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _corPrimaria,
                padding: const EdgeInsets.all(15),
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTabelaDeDados() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dados em Tempo Real",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _corPrimaria)),
            const SizedBox(height: 10),
            _tableData.isEmpty
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Aguardando dados do experimento...",
                        style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 25,
                      headingRowColor: MaterialStateColor.resolveWith(
                          (states) => _corPrimaria.withOpacity(0.1)),
                      columns: const [
                        DataColumn(
                            label: Text('Tempo(s)',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Nível(cm)',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Tensão(V)',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Estimado',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _tableData
                          .map((data) => DataRow(
                                cells: [
                                  DataCell(Text(data['tempo'] ?? '-')),
                                  DataCell(Text(data['nivel'] ?? '-')),
                                  DataCell(Text(data['tensao'] ?? '-')),
                                  DataCell(Text(data['estimado'] ?? '-')),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
          ],
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

        String dialogContent = 'Sair da tela do experimento?';
        if (_experimentoStatus.toLowerCase() == 'em andamento') {
          dialogContent =
              'O experimento está em andamento. Deseja realmente sair e interrompê-lo?';
        } else if (_referenciaAlteradaNaoPublicada) {
          dialogContent =
              'Você alterou a referência mas não publicou. Deseja descartar a alteração e sair?';
        }

        final resultado = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (contextoDialogo) => AlertDialog(
            title: const Text('Confirmar Saída'),
            content: Text(dialogContent),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(contextoDialogo, 'cancelar'),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(contextoDialogo, 'sair_mesmo_assim'),
                child: const Text('Sair Mesmo Assim'),
              ),
            ],
          ),
        );

        if (mounted && resultado == 'sair_mesmo_assim') {
          if (_experimentoStatus.toLowerCase() == 'em andamento') {
            _enviarComandoEncerramentoBroker();
          }
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
          title: const Text('Controle do Experimento',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _construirStatusContainer(),
                    const SizedBox(height: 16),
                    _construirCampoReferencia(),
                    const SizedBox(height: 16),
                    _construirTabelaDeDados(),
                    const SizedBox(height: 20),
                  ],
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
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Encerrar Experimento'),
                onPressed: (_brokerInfo.status == 'Conectado')
                    ? _confirmarEncerramentoExperimento
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brokerInfo.status == 'Conectado'
                      ? _corDestaqueVermelho
                      : Colors.grey.shade400,
                  foregroundColor: _corTextoBotaoBranco,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
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
          _buildNavBarItem(
            Icons.assignment_outlined,
            'Dados Exp.',
            () {
              _verificarAlteracoesAntesDeNavegarParaOutraTela(() {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DadosExperimentos()));
              });
            },
          ),
          _buildNavBarItem(Icons.science, 'Experimento', () {
           
          }, isActive: true),
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
    bool podeNavegarDireto = true;
    String tituloDialogo = '';
    String conteudoDialogo = '';
    String textoBotaoConfirmar = 'Sair Mesmo Assim';

    if (_experimentoStatus.toLowerCase() == 'em andamento') {
      podeNavegarDireto = false;
      tituloDialogo = 'Experimento em Andamento';
      conteudoDialogo =
          'O experimento está em andamento. Deseja realmente sair e interrompê-lo antes de navegar para outra tela?';
      textoBotaoConfirmar = 'Interromper e Sair';
    } else if (_referenciaAlteradaNaoPublicada) {
      podeNavegarDireto = false;
      tituloDialogo = 'Referência Não Publicada';
      conteudoDialogo =
          'Você alterou a referência mas não a publicou. Deseja descartar esta alteração e navegar?';
      textoBotaoConfirmar = 'Descartar e Sair';
    }

    if (podeNavegarDireto) {
      acaoNavegar();
      return;
    }

    final resultado = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (contextoDialogo) => AlertDialog(
        title: Text(tituloDialogo),
        content: Text(conteudoDialogo),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, 'cancelar'),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(contextoDialogo, 'confirmar_saida'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _corDestaqueVermelho,
                foregroundColor: _corTextoBotaoBranco),
            child: Text(textoBotaoConfirmar),
          ),
        ],
      ),
    );

    if (resultado == 'confirmar_saida') {
      if (_experimentoStatus.toLowerCase() == 'em andamento') {
        _enviarComandoEncerramentoBroker();
      }
      if (_referenciaAlteradaNaoPublicada) {
        _carregarReferenciaInicial();
      }
      acaoNavegar();
    }
  }
}