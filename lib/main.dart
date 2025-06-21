import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dados_integrantes.dart'; // Certifique-se que este arquivo existe no seu projeto
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ===== TEMA CLARO (MONOCROMÁTICO CINZA) =====
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF212121), // Cinza-escuro como base
      brightness: Brightness.light,
      primary: const Color(0xFF212121), // Usado para botões principais, ícones e textos
      onPrimary: Colors.white,
      secondary: const Color(0xFF2E7D32), // Verde para acento de sucesso
      onSecondary: Colors.white,
      error: const Color(0xFFD32F2F), // Vermelho para acento de erro
      onError: Colors.white,
      surface: Colors.white, // Cards e diálogos serão brancos puros
      onSurface: const Color(0xFF212121),
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: Colors.grey.shade100, // Fundo principal sutilmente cinza
      appBarTheme: AppBarTheme(
        // AppBar branca para um visual super clean
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightColorScheme.onSurface,
        ),
        centerTitle: true,
      ),
      // CORREÇÃO: Usado CardThemeData em vez de CardTheme
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: lightColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.grey.withOpacity(0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: lightColorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: lightColorScheme.primary, // Botão principal cinza-escuro
          foregroundColor: lightColorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          elevation: 2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Colors.grey.shade200,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lightColorScheme.primary);
          }
          return TextStyle(fontSize: 12, color: Colors.grey.shade600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected) ? lightColorScheme.primary : Colors.grey.shade600;
          return IconThemeData(color: color, size: 24);
        }),
      ),
      // CORREÇÃO: Usado DialogThemeData em vez de DialogTheme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: lightColorScheme.surface,
        elevation: 5,
      ),
    );

    // ===== TEMA ESCURO (MONOCROMÁTICO CINZA) =====
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.white, // Base para gerar tons claros
      brightness: Brightness.dark,
      primary: Colors.white, // Elementos interativos principais serão brancos
      onPrimary: Colors.black,
      secondary: const Color(0xFF66BB6A), // Verde mais claro para contraste
      onSecondary: Colors.black,
      error: const Color(0xFFEF9A9A), // Vermelho mais claro para contraste
      onError: Colors.black,
      surface: const Color(0xFF1E1E1E), // Superfície dos cards um pouco mais clara
      onSurface: Colors.white.withOpacity(0.9),
    );

    final darkTheme = ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: const Color(0xFF121212), // Fundo padrão do Material Design Dark
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.surface,
          foregroundColor: darkColorScheme.onSurface,
          elevation: 1,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkColorScheme.onSurface,
          ),
          centerTitle: true,
        ),
        // CORREÇÃO: Usado CardThemeData em vez de CardTheme
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: darkColorScheme.surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          filled: true,
          fillColor: darkColorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: darkColorScheme.primary,
            foregroundColor: darkColorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            elevation: 2,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkColorScheme.surface,
          indicatorColor: Colors.grey.shade800,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkColorScheme.primary);
            }
            return TextStyle(fontSize: 12, color: Colors.grey.shade400);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final color = states.contains(WidgetState.selected) ? darkColorScheme.primary : Colors.grey.shade400;
            return IconThemeData(color: color, size: 24);
          }),
        ),
        // CORREÇÃO: Usado DialogThemeData em vez de DialogTheme
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: darkColorScheme.surface,
          elevation: 5,
        ),
    );


    return MaterialApp(
      // Configuração para usar os temas
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system, // Usa o tema do sistema (claro ou escuro)

      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


// O Widget StartScreen se adaptará automaticamente.
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
    "Calibrando bomba de água...",
    "Limpando cache do ESP32...",
    "Apontando antena Wi-Fi para o lado certo...",
    "Verificando se o MATLAB ainda está aberto...",
    "Revendo polos e zeros do sistema...",
    "Contando ovelhas no espaço de estados...",
    "Enviando sinais de fumaça via MQTT...",
    "Compilando com fé...",
    "Calibrando sensor de distância sem régua...",
    "Alinhando os vetores próprios..."
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

    _timerMensagem =
        Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (mounted) {
        setState(() {
          _indiceMensagemAtual =
              (_indiceMensagemAtual + 1) % _mensagensCarregamento.length;
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
    final theme = Theme.of(context);
    
    // Para manter a consistência do splash, vamos deixá-lo sempre escuro
    final splashColor = const Color(0xFF212121);
    final onSplashColor = Colors.white;

    return Scaffold(
      backgroundColor: splashColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/LogoFEMEC.JPG', width: 120, height: 80),
                  Image.asset('assets/LogoUFU2.PNG', width: 80, height: 80),
                ],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Text('Laboratório de Controle Linear',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            color: onSplashColor,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text('Experimento 7: Espaço de Estados',
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: onSplashColor.withOpacity(0.9)),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 40),
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(150),
                      ),
                      child: LottieBuilder.asset(
                        'assets/Tanque.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 40),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        _mensagensCarregamento[_indiceMensagemAtual],
                        key: ValueKey<int>(_indiceMensagemAtual),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onSplashColor.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'v 2.1.4.1',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: onSplashColor.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

