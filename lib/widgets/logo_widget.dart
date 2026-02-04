import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Un widget reutilizable que muestra el logo principal "Face IA".
// Este widget está diseñado para ser usado en las pantallas de
// autenticación y en cualquier otro lugar donde se necesite el logo.
// No incluye padding, para que la pantalla que lo usa
// pueda controlar el espaciado.
class LogoWidget extends StatelessWidget {
  static const Color _accentColor = Color(0xFF1579AF);
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // El widget en sí es solo el RichText.
    // La pantalla que lo llama debe agregar el padding/SizedBox.
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'Barber',
        style: GoogleFonts.leagueSpartan(
          fontSize: 78,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        children: <TextSpan>[
          TextSpan(
            text: 'IA',
            style: GoogleFonts.leagueSpartan(
              fontSize: 78,
              fontWeight: FontWeight.w700,
              color: _accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
