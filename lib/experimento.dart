// ignore_for_file: use_build_context_synchronously, deprecated_member_use, avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'broker.dart';
import 'dadosexperimento.dart';
import 'dados_integrantes.dart';
import 'custom_page_route.dart'; // NOVO: Importando a rota de transição

class Experimento extends StatefulWidget {
  const Experimento({super.key});

  @override
  State<Experimento> createState() => _ExperimentoState();
}

class _ExperimentoState extends State<Experimento> {
  // A lógica interna do State permanece a mesma
  final BrokerInfo _brokerInfo = BrokerInfo.instance;
  final List<Map<String, String>> _tableData = [];
  StreamSubscription? _mqttSubscription;
  String _wifiStatus = 'Verificando...';
  String _brokerStatusESP = 'Verificando...';
  String _experimentoStatus = 'Parado';
  double _nivelAtual = 0.0;
  final double _maxNivelTanque = 17.0;
  final Map<String, Map<String, String?>> _linhasDeDadosPendentes = {};
  String? _ultimoTempoRecebido;

  @override
  void initState() {
    super.initState();
    _brokerInfo.statusNotifier.addListener(_onBrokerStatusChanged);
    _setupMqttListeners();
  }

  void _onBrokerStatusChanged() {
    if (mounted) {
      setState(() {});
      if (_brokerInfo.status == 'Conectado' && (_mqttSubscription == null || _mqttSubscription!.isPaused)) { _setupMqttListeners(); }
    }
  }

  @override
  void dispose() {
    _mqttSubscription?.cancel();
    _brokerInfo.statusNotifier.removeListener(_onBrokerStatusChanged);
    super.dispose();
  }

  void _setupMqttListeners() {
    if (_brokerInfo.client == null || _brokerInfo.client!.connectionStatus!.state != MqttConnectionState.connected) { print("Cliente MQTT não conectado. Listeners não serão configurados."); return; }
    _mqttSubscription?.cancel();
    print("Configurando listeners MQTT para a tela de Experimento...");
    final topicsToSubscribe = { 'estadoESPWifi': MqttQos.atMostOnce, 'estadoESPBroker': MqttQos.atMostOnce, 'estadoExperimento': MqttQos.atMostOnce, 'tempo': MqttQos.atMostOnce, 'nivel': MqttQos.atMostOnce, 'tensao': MqttQos.atMostOnce, 'estimado': MqttQos.atMostOnce,};
    topicsToSubscribe.forEach((topic, qos) { _brokerInfo.client!.subscribe(topic, qos); });
    _mqttSubscription = _brokerInfo.client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      if (!mounted) return;
      final msg = c[0];
      final payload = msg.payload as MqttPublishMessage;
      final topic = msg.topic;
      final message = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
      setState(() {
        if (topic == 'estadoESPWifi') _wifiStatus = message;
        if (topic == 'estadoESPBroker') _brokerStatusESP = message;
        if (topic == 'estadoExperimento') _experimentoStatus = message;
        if (topic == 'nivel') _nivelAtual = double.tryParse(message) ?? _nivelAtual;
        if (['tempo', 'nivel', 'tensao', 'estimado'].contains(topic)) { _handleDataUpdate(topic, message); }
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
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Comando START enviado!'), backgroundColor: Colors.blueAccent),);
    } else {
      _mostrarDialogoErro('App não conectado ao broker.');
    }
  }

  void _pararExperimento() {
    if (_brokerInfo.status == 'Conectado') {
      _brokerInfo.publish('encerraExperimento', 'STOP');
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: const Text('Comando STOP enviado!'), backgroundColor: Theme.of(context).colorScheme.error),);
    } else {
      _mostrarDialogoErro('App não conectado ao broker.');
    }
  }

  Widget _construirDisplayNivel() {
    final theme = Theme.of(context);
    double nivelPercentual = (_nivelAtual / _maxNivelTanque).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 70, height: 140, decoration: BoxDecoration( color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.only( topLeft: Radius.circular(8), topRight: Radius.circular(8),), border: Border.all(color: Colors.grey.shade400, width: 2),),
              clipBehavior: Clip.antiAlias,
              child: Align( alignment: Alignment.bottomCenter, child: AnimatedContainer( duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic, width: double.infinity, height: 140 * nivelPercentual, color: Colors.blue.shade300,),),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text("Altura da Coluna de Água", style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700)), const SizedBox(height: 8), Text("${_nivelAtual.toStringAsFixed(2)} cm", style: theme.textTheme.displaySmall?.copyWith( fontWeight: FontWeight.bold, color: theme.colorScheme.primary, ),),],),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBotoesDeControle() {
    final theme = Theme.of(context);
    bool isRunning = _experimentoStatus.toLowerCase() == 'em andamento';

    return Row(
      children: [
        Expanded( child: ElevatedButton.icon( icon: const Icon(Icons.play_arrow_rounded), label: const Text('Iniciar'), onPressed: !isRunning && _brokerInfo.status == 'Conectado' ? _iniciarExperimento : null, style: ElevatedButton.styleFrom( backgroundColor: theme.colorScheme.secondary, foregroundColor: theme.colorScheme.onSecondary),),), // ESTILO: Botão de sucesso (verde)
        const SizedBox(width: 16),
        Expanded( child: ElevatedButton.icon( icon: const Icon(Icons.stop_rounded), label: const Text('Parar'), onPressed: isRunning && _brokerInfo.status == 'Conectado' ? _pararExperimento : null, style: ElevatedButton.styleFrom( backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),),), // ESTILO: Botão de erro (vermelho)
      ],
    );
  }

  Widget _construirStatusContainer() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status da Conexão e Experimento", style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _construirLinhaStatus('WiFi ESP:', _wifiStatus, _getColorForStatus(_wifiStatus, theme)),
            const Divider(height: 16, thickness: 0.5),
            _construirLinhaStatus('Broker ESP:', _brokerStatusESP, _getColorForStatus(_brokerStatusESP, theme)),
            const Divider(height: 16, thickness: 0.5),
            _construirLinhaStatus('App > Broker:', _brokerInfo.status, _getColorForStatus(_brokerInfo.status, theme)),
            const Divider(height: 16, thickness: 0.5),
            _construirLinhaStatus('Experimento:', _experimentoStatus, _getColorForStatus(_experimentoStatus, theme, isExperiment: true)),
          ],
        ),
      ),
    );
  }

  Color _getColorForStatus(String status, ThemeData theme, {bool isExperiment = false}) {
    String s = status.toLowerCase();
    if (s == 'conectado') return theme.colorScheme.secondary;
    if (isExperiment && s == 'em andamento') return Colors.blue.shade700;
    if (s.contains('conectando') || s.contains('verificando')) return Colors.orange.shade700;
    return theme.colorScheme.error;
  }

  Widget _construirLinhaStatus(String label, String value, Color valueColor) {
    return Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text(label, style: Theme.of(context).textTheme.bodyLarge), Container( padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration( color: valueColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)), child: Text(value.isNotEmpty ? value : 'N/A', style: TextStyle(color: valueColor, fontWeight: FontWeight.bold)),), ],
    );
  }
  
  Widget _construirTabelaDeDados() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dados Coletados", style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            _tableData.isEmpty
                ? const Center( child: Padding( padding: EdgeInsets.symmetric(vertical: 32.0), child: Column( children: [ Icon(Icons.hourglass_empty, size: 40, color: Colors.grey), SizedBox(height: 8), Text("Aguardando dados...", style: TextStyle(fontSize: 15, color: Colors.grey)), ],),))
                : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.resolveWith((states) => theme.colorScheme.primary.withOpacity(0.1)),
                        columns: const [ DataColumn(label: Text('Tempo(s)')), DataColumn(label: Text('Altura(cm)')), DataColumn(label: Text('Controle(u)')), DataColumn(label: Text('Estimado(x̂)')),],
                        rows: _tableData.map((data) => DataRow(cells: [ DataCell(Text(data['tempo'] ?? '-')), DataCell(Text(data['nivel'] ?? '-')), DataCell(Text(data['tensao'] ?? '-')), DataCell(Text(data['estimado'] ?? '-')), ])).toList(),
                      ),
                    ),
                ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoErro(String mensagem) {
    if (!mounted) return;
    showDialog( context: context, builder: (context) => AlertDialog( title: Row(children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error), const SizedBox(width: 10), const Text('Erro')]), content: Text(mensagem), actions: [ TextButton( onPressed: () => Navigator.pop(context), child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),), ],),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( automaticallyImplyLeading: false, title: const Text('Controle do Experimento'),),
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
    return NavigationBar(
      selectedIndex: 3,
      onDestinationSelected: (index) {
        switch (index) {
          case 0: Navigator.pushReplacement(context, FadePageRoute(child: const IntegrantesScreen())); break; // NOVO: Usando FadePageRoute
          case 1: Navigator.pushReplacement(context, FadePageRoute(child: const ConectaBroker())); break; // NOVO: Usando FadePageRoute
          case 2: Navigator.pushReplacement(context, FadePageRoute(child: const DadosExperimentos())); break; // NOVO: Usando FadePageRoute
          case 3: break;
        }
      },
      destinations: const [
        NavigationDestination( selectedIcon: Icon(Icons.group), icon: Icon(Icons.group_outlined), label: 'Integrantes',),
        NavigationDestination( selectedIcon: Icon(Icons.cloud), icon: Icon(Icons.cloud_outlined), label: 'Broker',),
        NavigationDestination( selectedIcon: Icon(Icons.assignment), icon: Icon(Icons.assignment_outlined), label: 'Dados Exp.',),
        NavigationDestination( selectedIcon: Icon(Icons.science), icon: Icon(Icons.science_outlined), label: 'Experimento',),
      ],
    );
  }
}