import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/news_screen.dart'; // Fixed your import match naming context
import 'screens/portfolio_screen.dart';
import 'screens/premium_screen.dart';

class NavigationController extends StatefulWidget {
  const NavigationController({super.key});

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  int _currentIndex = 0;

  // Kept your 4 primary target windows intact
  final List<Widget> _screens = [
    const HomeScreen(),        // Tab 0
    const WatchlistScreen(),   // Tab 1
    const PortfolioScreen(),   // Tab 2
    const PremiumScreen(),     // Tab 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIXED: Swapped out raw array selector for IndexedStack to retain memory states perfectly!
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF131D31), // Midnight Blue
        selectedItemColor: const Color(0xFF14B8A6), // Turquoise Brand Color
        unselectedItemColor: const Color(0xFF64748B), // Slate Gray
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Markets'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'Premium & Core'),
        ],
      ),
    );
  }
}