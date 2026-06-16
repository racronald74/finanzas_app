import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

class CustomButton extends StatelessWidget {
  // Texto que aparecerá en el botón
  final String text;

  // Acción al presionar
  final VoidCallback? onPressed;

  const CustomButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,

      height: 50,

      child: ElevatedButton(
        onPressed: onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,

          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        child: Text(text),
      ),
    );
  }
}
