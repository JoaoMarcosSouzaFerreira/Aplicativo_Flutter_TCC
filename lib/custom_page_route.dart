import 'package:flutter/material.dart';

// Esta classe cria uma rota com uma transição de Fade (esmaecimento).
// Usaremos ela no lugar do MaterialPageRoute padrão.
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          // Duração da animação de transição
          transitionDuration: const Duration(milliseconds: 350),
        );
}