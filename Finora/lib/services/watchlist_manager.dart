import 'package:flutter/material.dart';

class WatchlistManager {
  // Safe baseline defaults so the news/watchlist page isn't blank on first boot
  static final Set<String> selectedSymbols = {'AAPL', 'NVDA'};

  static void toggleWatchlist(String symbol, BuildContext context) {
    if (selectedSymbols.contains(symbol)) {
      selectedSymbols.remove(symbol);
      _showToast(context, '$symbol removed from Watchlist');
    } else {
      selectedSymbols.add(symbol);
      _showToast(context, '$symbol added to Watchlist Hub!');
    }
  }

  static void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF14B8A6),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}