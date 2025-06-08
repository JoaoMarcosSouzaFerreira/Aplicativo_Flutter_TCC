// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'broker.dart';
import 'dadosexperimento.dart';
import 'dados_integrantes.dart';

class Experimento extends StatefulWidget {
  const Experimento({super.key});

  @override
  State<Experimento> createState() => _ExperimentoState();
}

class _ExperimentoState extends State<Experimento> {
  final BrokerInfo _brokerInfo = BrokerInfo.instance;
  final List<Map<String, String>> _tableData = [];
  StreamSubscription? _mqttSubscription;

  // --- Variáveis de Estado da UI ---
  String _wifiStatus = 'Verificando...';
  String _brokerStatusESP = 'Verificando...';
  String _experimentoStatus = 'Parado';
  double _nivelAtual = 0.0;

  final double _maxNivelTanque = 17.0; // Altura máxima da coluna de água (37cm - 20cm)

  final Map<String, Map<String, String?>> _linhasDeDadosPendentes = {};
  String? _ultimoTempoRecebido;

  // --- Estilos ---
  final Color _corPrimaria = const Color.fromRGBO(19, 85, 156, 1);
  final Color _corTextoBotaoBranco = Colors.white;
  final Color _corDestaqueVerde = const Color.fromARGB(255, 30, 180, 35);
  final Color _corDestaqueVermelho = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    if (_brokerInfo.status == 'Conectado' && _brokerInfo.client != null) {
      _setupMqttListeners();
    }
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    super.dispose();
  }

  void _setupMqttListeners() {
    if (_brokerInfo.client == null ||
        _brokerInfo.client!.connectionStatus!.state != MqttConnectionState.connected) {
      print("Cliente MQTT não conectado. Listeners não serão configurados.");
      return;
    }

    print("Configurando listeners MQTT para a tela de Experimento...");
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
      _brokerInfo.client!.subscribe(topic, qos);
    });

    _mqttSubscription = _brokerInfo.client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      if (!mounted) return;
      final msg = c[0]; // Processa uma mensagem por vez para evitar sobrecarga de UI
      final payload = msg.payload as MqttPublishMessage;
      final topic = msg.topic;
      final message = MqttPublishPayload.bytesToStringAsString(payload.payload.message);

      setState(() {
        if (topic == 'estadoESPWifi') _wifiStatus = message;
        if (topic == 'estadoESPBroker') _brokerStatusESP = message;
        if (topic == 'estadoExperimento') _experimentoStatus = message;
        // A variável 'nivel' agora representa a ALTURA DA COLUNA DE ÁGUA
        if (topic == 'nivel') _nivelAtual = double.tryParse(message) ?? _nivelAtual;
        
        if (['tempo', 'nivel', 'tensao', 'estimado'].contains(topic)) {
          _handleDataUpdate(topic, message);
        }
      });
    });
  }

  void _handleDataUpdate(String type, String message) {
     try {
       final String valorFormatado = double.parse(message.replaceAll(',', '.')).toStringAsFixed(2);
       if (type == 'tempo') {
         _ultimoTempoRecebido = valorFormatado;
         _linhasDeDadosPendentes.putIfAbsent(_ultimoTempoRecebido!, () => {'tempo': _ultimoTempoRecebido});
       } else if (_ultimoTempoRecebido != null && _linhasDeDadosPendentes.containsKey(_ultimoTempoRecebido)) {
         _linhasDeDadosPendentes[_ultimoTempoRecebido!]?[type] = valorFormatado;
       }
       if (_ultimoTempoRecebido != null && _linhasDeDadosPendentes[_ultimoTempoRecebido!]?.length == 4) {
         _tableData.add(Map.from(_linhasDeDadosPendentes[_ultimoTempoRecebido!]!));
         _linhasDeDadosPendentes.remove(_ultimoTempoRecebido);
         _ultimoTempoRecebido = null;
       }
     } catch (e) {
       print('Erro ao processar dado MQTT ($type: $message): $e');
     }
  }

  void _iniciarExperimento() {
    if (_brokerInfo.status == 'Conectado') {
      _brokerInfo.publish('encerraExperimento', 'START');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comando START enviado!'), backgroundColor: Colors.blueAccent),
      );
    } else {
      _mostrarDialogoErro('App não conectado ao broker.');
    }
  }

  void _pararExperimento() {
    if (_brokerInfo.status == 'Conectado') {
      _brokerInfo.publish('encerraExperimento', 'STOP');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Comando STOP enviado!'), backgroundColor: _corDestaqueVermelho),
      );
    } else {
      _mostrarDialogoErro('App não conectado ao broker.');
    }
  }

  // --- Widgets de Construção da UI ---

  Widget _construirDisplayNivel() {
    double nivelPercentual = (_nivelAtual / _maxNivelTanque).clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Animação do Tanque
            Container(
              width: 60,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: 120 * nivelPercentual,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Texto do Nível
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Altura da Coluna",
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${_nivelAtual.toStringAsFixed(2)} cm",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _corPrimaria,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotoesDeControle() {
    bool isRunning = _experimentoStatus.toLowerCase() == 'em andamento';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Iniciar'),
            onPressed: !isRunning && _brokerInfo.status == 'Conectado' ? _iniciarExperimento : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _corDestaqueVerde,
              foregroundColor: _corTextoBotaoBranco,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Parar'),
            onPressed: isRunning && _brokerInfo.status == 'Conectado' ? _pararExperimento : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _corDestaqueVermelho,
              foregroundColor: _corTextoBotaoBranco,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
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
            Text("Status da Conexão e Experimento", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _corPrimaria)),
            const SizedBox(height: 12),
            _construirLinhaStatus('WiFi ESP:', _wifiStatus, _getColorForStatus(_wifiStatus)),
            const Divider(height: 16),
            _construirLinhaStatus('Broker ESP:', _brokerStatusESP, _getColorForStatus(_brokerStatusESP)),
            const Divider(height: 16),
            _construirLinhaStatus('App > Broker:', _brokerInfo.status, _getColorForStatus(_brokerInfo.status)),
            const Divider(height: 16),
            _construirLinhaStatus('Experimento:', _experimentoStatus, _getColorForStatus(_experimentoStatus, isExperiment: true)),
          ],
        ),
      ),
    );
  }

  Color _getColorForStatus(String status, {bool isExperiment = false}) {
    String s = status.toLowerCase();
    if (s == 'conectado') return Colors.green.shade700;
    if (isExperiment && s == 'em andamento') return Colors.blue.shade700;
    if (s.contains('conectando') || s.contains('verificando')) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Widget _construirLinhaStatus(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: valueColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Text(value.isNotEmpty ? value : 'N/A', style: TextStyle(color: valueColor, fontWeight: FontWeight.w600)),
        ),
      ],
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
            Text("Dados Coletados", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _corPrimaria)),
            const SizedBox(height: 10),
            _tableData.isEmpty
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Aguardando dados...", style: TextStyle(fontSize: 15, color: Colors.grey)),
                  ))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateColor.resolveWith((states) => _corPrimaria.withOpacity(0.1)),
                      columns: const [
                        DataColumn(label: Text('Tempo(s)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Altura(cm)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Controle(u)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Estimado(x̂)', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _tableData.map((data) => DataRow(cells: [
                              DataCell(Text(data['tempo'] ?? '-')),
                              DataCell(Text(data['nivel'] ?? '-')),
                              DataCell(Text(data['tensao'] ?? '-')),
                              DataCell(Text(data['estimado'] ?? '-')),
                            ])).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoErro(String mensagem) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(Icons.error_outline, color: Colors.red.shade700), const SizedBox(width: 10), const Text('Erro')]),
        content: Text(mensagem),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: _corPrimaria, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Controle do Experimento', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        backgroundColor: _corPrimaria,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _construirDisplayNivel(),
            const SizedBox(height: 20),
            _construirBotoesDeControle(),
            const SizedBox(height: 20),
            _construirStatusContainer(),
            const SizedBox(height: 20),
            _construirTabelaDeDados(),
          ],
        ),
      ),
      bottomNavigationBar: _construirBarraNavegacaoInferior(),
    );
  }

  Widget _construirBarraNavegacaoInferior() {
    return Container(
      height: 60,
      decoration: BoxDecoration(color: _corPrimaria, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, -1))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(Icons.group_outlined, 'Integrantes', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const IntegrantesScreen()))),
          _buildNavBarItem(Icons.cloud_outlined, 'Broker', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ConectaBroker()))),
          _buildNavBarItem(Icons.assignment_outlined, 'Dados Exp.', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DadosExperimentos()))),
          _buildNavBarItem(Icons.science, 'Experimento', () {}, isActive: true),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(IconData icone, String rotulo, VoidCallback aoPressionar, {bool isActive = false}) {
    return IconButton(
      icon: Icon(icone, color: isActive ? Colors.white : Colors.white.withOpacity(0.7), size: isActive ? 28 : 24),
      tooltip: rotulo,
      onPressed: aoPressionar,
    );
  }
}
