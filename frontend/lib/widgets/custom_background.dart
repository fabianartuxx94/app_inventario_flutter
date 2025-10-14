import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomBackground extends StatelessWidget {
  const CustomBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Color base: azul profundo
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF001F5E), // Azul oscuro profundo
                Color(0xFF003C9E), // Azul intermedio
                Color(0xFF0056CC), // Azul brillante final
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Capas diagonales sutiles que simulan las franjas
        Positioned.fill(child: CustomPaint(painter: _DiagonalPatternPainter())),

        // Animación de luz suave
        Positioned.fill(
          child:
              Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Color(0x400057CC), // Azul brillante translúcido
                          Colors.transparent,
                        ],
                        stops: [0.0, 1.0],
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.05, duration: 10.seconds),
        ),
      ],
    );
  }
}

class _DiagonalPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0x1AFFFFFF), // líneas muy sutiles (translúcidas)
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    const stripeWidth = 80.0;
    for (double i = -size.height; i < size.width; i += stripeWidth * 2) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + stripeWidth, 0)
        ..lineTo(i + stripeWidth - size.height, size.height)
        ..lineTo(i - size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
