import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dados_integrantes.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const StartScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(19, 85, 156, 1),
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int _indiceMensagemAtual = 0;
  Timer? _timerNavegacao;
  Timer? _timerMensagem;

  final List<String> _mensagensCarregamento = [
    "Calibrando bomba de água",
    "Limpando cache do ESP32",
    "Apontando antena Wi-Fi para o lado certo",
    "Verificando se o MATLAB ainda está aberto",
    "Revendo polos e zeros do sistema",
    "Contando ovelhas no espaço de estados",
    "Enviando sinais de fumaça via MQTT",
    "Compilando com fé",
    "Calibrando sensor de distância sem régua",
    "Alinhando os vetores próprios"
  ];

  @override
  void initState() {
    super.initState();
    _timerNavegacao = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const IntegrantesScreen()),
        );
      }
    });

    _timerMensagem = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted) {
        setState(() {
          _indiceMensagemAtual = (_indiceMensagemAtual +1) % _mensagensCarregamento.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    
    _timerNavegacao?.cancel();
    _timerMensagem?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(19, 85, 156, 1),
      body: Stack( 
        children: [      
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Image.asset('assets/LogoFEMEC.JPG', width: 120, height: 80),
                  const Spacer(flex: 150,),
                  Image.asset('assets/LogoUFU2.PNG', width: 80,height: 80),
                ],
              ),
              const SizedBox(height: 60),
              const Text(
                'Laboratório de Controle Linear',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Text(
                'Experimento 7',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                )
              ),
              const SizedBox(height: 30),
              const Text(
                'Espaço de Estados',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
                )
              ),
              const SizedBox(height: 60),
              Container(
                width: 250,
                height: 250,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LottieBuilder.asset(
                  'assets/Tanque.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  _mensagensCarregamento[_indiceMensagemAtual],
                  key: ValueKey<int>(_indiceMensagemAtual),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: Padding(padding: const EdgeInsets.all(16.0),
        child: Text(
          'v 2.1.4.1',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        ),
        ),
        ],
      ),
    );
  }
}
