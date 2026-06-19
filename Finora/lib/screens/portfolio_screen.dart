import 'package:flutter/material.dart';
import '../main.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppLogoTitle(title: 'Asset Portfolio')),
      body: const Center(
        child: Text('Track assets, costs basis distributions & net worth evolution.', style: TextStyle(color: Color(0xFFCBD5E1))),
      ),
    );
  }
}