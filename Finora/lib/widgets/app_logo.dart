import 'package:flutter/material.dart';

class AppLogoTitle extends StatelessWidget {
  final String title;
  const AppLogoTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Load the logo from the assets
        Image.asset(
          'Finora/assets/images/logo.png',
          height: 46, // Controlled height to fit nicely in the AppBar
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback icon if the image fails to load
            return const Icon(Icons.show_chart, color: Color(0xFF14B8A6));
          },
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
      ],
    );
  }
}