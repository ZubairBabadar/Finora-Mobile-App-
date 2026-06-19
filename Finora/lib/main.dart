import 'package:flutter/material.dart';
import 'navigation_controller.dart';
import 'screens/account_screen.dart';
import 'screens/detail_screen.dart';

void main() {
  runApp(const FinoraApp());
}

class FinoraApp extends StatefulWidget {
  const FinoraApp({super.key});

  // Global app state tracking variables
  static String globalCurrency = "USD (\$)";
  static String globalCountryFilter = "United States";

  // Helper method to dynamically convert raw USD price data to other currency regions
  static String formatPrice(double baseUsdPrice) {
    double conversionRate = 1.0;
    String symbol = '\$';

    if (globalCurrency.contains('EUR')) {
      conversionRate = 0.92; // Standard fixed conversion matrix matching 2026 specs
      symbol = '€';
    } else if (globalCurrency.contains('GBP')) {
      conversionRate = 0.78;
      symbol = '£';
    }

    double finalPrice = baseUsdPrice * conversionRate;
    return '$symbol${finalPrice.toStringAsFixed(2)}';
  }

  @override
  State<FinoraApp> createState() => _FinoraAppState();
}

class _FinoraAppState extends State<FinoraApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131D31),
          elevation: 0,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AccountScreen(),
        '/home': (context) => const NavigationController(),
        '/stock-detail': (context) => const StockDetailScreen(),
      },
    );
  }
}

class AppLogoTitle extends StatelessWidget {
  final String title;
  const AppLogoTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white));
  }
}