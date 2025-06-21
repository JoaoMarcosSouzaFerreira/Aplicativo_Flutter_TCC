import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dados_integrantes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF212121),
      brightness: Brightness.light,
      primary: const Color(0xFF212121),
      onPrimary: Colors.white,
      secondary: const Color(0xFF2E7D32),
      onSecondary: Colors.white,
      error: const Color(0xFFD32F2F),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF212121),
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
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
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: lightColorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.grey,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: lightColorScheme.primary,
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
            return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: lightColorScheme.primary);
          }
          return TextStyle(fontSize: 12, color: Colors.grey.shade600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? lightColorScheme.primary
              : Colors.grey.shade600;
          return IconThemeData(color: color, size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: lightColorScheme.surface,
        elevation: 5,
      ),
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.white,
      brightness: Brightness.dark,
      primary: Colors.white,
      onPrimary: Colors.black,
      secondary: const Color(0xFF66BB6A),
      onSecondary: Colors.black,
      error: const Color(0xFFEF9A9A),
      onError: Colors.black,
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: darkColorScheme.primary);
          }
          return TextStyle(fontSize: 12, color: Colors.grey.shade400);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? darkColorScheme.primary
              : Colors.grey.shade400;
          return IconThemeData(color: color, size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: darkColorScheme.surface,
        elevation: 5,
      ),
    );

    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _elementsOpacity;
  late Animation<Offset> _cardPosition;

  late AnimationController _botaoPulseController;
  late Animation<double> _escalaBotaoAnimacao;

  late AnimationController _cardPulseController;
  late Animation<Offset> _cardPulseAnimation;

  @override
  void initState() {
    super.initState();

    _botaoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _escalaBotaoAnimacao = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _botaoPulseController, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {});
      });
    _botaoPulseController.repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _elementsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOut,
      ),
    );

    _cardPosition =
        Tween<Offset>(begin: const Offset(0, 400), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cardPulseAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -5.0)).animate(
      CurvedAnimation(parent: _cardPulseController, curve: Curves.easeInOut),
    );

    _entryController.addListener(() {
      setState(() {});
    });

    _cardPulseController.addListener(() {
      setState(() {});
    });

    _entryController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cardPulseController.repeat(reverse: true);
      }
    });

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _botaoPulseController.dispose();
    _cardPulseController.dispose();
    super.dispose();
  }

  void _navegarParaProximaTela() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const IntegrantesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          Opacity(
            opacity: _elementsOpacity.value,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.22),
                child: LottieBuilder.asset(
                  'assets/Tanque.json',
                  height: screenHeight * 0.4,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Opacity(
            opacity: _elementsOpacity.value,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 50.0, left: 24.0, right: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/LogoFEMEC.JPG', width: 110),
                  Image.asset('assets/LogoUFU2.PNG', height: 60),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: _cardPosition.value + _cardPulseAnimation.value,
              child: Container(
                height: screenHeight * 0.30,
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laboratório de',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const Text(
                      'Controle Linear',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Experimento 7:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const Text(
                      'Espaço de Estados',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'v 9.8.7.5',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade500),
                        ),
                        ScaleTransition(
                          scale: _escalaBotaoAnimacao,
                          child: FloatingActionButton(
                            onPressed: _navegarParaProximaTela,
                            backgroundColor: const Color(0xFF212121),
                            elevation: 5,
                            child: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
