import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/news_screen.dart'; // Handles the market/news/trending layout tracking
import 'screens/portfolio_screen.dart';
import 'screens/premium_screen.dart';

class NavigationController extends StatefulWidget {
  const NavigationController({super.key});

  @override
  State<NavigationController> createState() => _NavigationControllerState();
}

class _NavigationControllerState extends State<NavigationController> {
  int _currentIndex = 0;

  // Fully updated screen layout sequence mapping your 4 core viewports perfectly
  final List<Widget> _screens = [
    const HomeScreen(),        // Tab 0: Dashboard metrics & highlights
    const WatchlistScreen(),        // Tab 1: Fixed component reference to match import for Markets/Trending
    const PortfolioScreen(),   // Tab 2: Your premium, calculations-driven holding center
    const PremiumScreen(),     // Tab 3: Dedicated upsell/core configuration screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Finora Deep Slate background base
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: const Color(0xFF131D31), // Enforces uniform background coloration across updates
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF131D31), // Midnight Blue Card Frame
          selectedItemColor: const Color(0xFF14B8A6), // Turquoise Finora Brand Accent
          unselectedItemColor: const Color(0xFF64748B), // Slate Muted Gray
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up),
              label: 'Markets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline),
              activeIcon: Icon(Icons.pie_chart),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              activeIcon: Icon(Icons.workspace_premium),
              label: 'Premium',
            ),
          ],
        ),
      ),
    );
  }
}