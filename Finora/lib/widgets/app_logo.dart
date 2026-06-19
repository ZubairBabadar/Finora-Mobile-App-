import 'package:flutter/material.dart';

class AppLogoTitle extends StatelessWidget {
  final String title;
  const AppLogoTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
    );
  }
}