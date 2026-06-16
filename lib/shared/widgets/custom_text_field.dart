import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  // Controlador del campo
  final TextEditingController controller;

  // Texto de ayuda
  final String label;

  // Ocultar texto (contraseñas)
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,

      obscureText: obscureText,

      decoration: InputDecoration(labelText: label),
    );
  }
}
