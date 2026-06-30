import 'package:flutter/material.dart';

/// Encabezado utilizado por la pantalla Más.
class MoreHeader extends StatelessWidget {
  final String title;
  final String userName;

  const MoreHeader({super.key, required this.title, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          color: const Color(0xFF3F6DB5),

          padding: const EdgeInsets.only(left: 24, right: 24, top: 50),

          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        Positioned(
          right: 24,
          top: 45,
          child: CircleAvatar(
            radius: 34,
            backgroundColor: Colors.orange.shade300,
            child: const Icon(Icons.wallet, size: 36, color: Colors.brown),
          ),
        ),

        Positioned(
          left: 16,
          right: 16,
          bottom: -55,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $userName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Explora más herramientas de tu gestión financiera.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
