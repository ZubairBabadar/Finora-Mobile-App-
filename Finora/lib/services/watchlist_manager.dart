import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'finnhub_service.dart';

class WatchlistManager {
  // In-memory runtime cache for quick UI lookup checks
  static final Set<String> selectedSymbols = {};

  // Central memory store for live prices
  static final Map<String, Map<String, dynamic>> cachedPrices = {};
  static bool isFetchingPrices = false;

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FinnhubService _finnhubService = FinnhubService();

  /// Loads saved symbols from Firestore on startup
  static Future<void> initializeWatchlist() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      selectedSymbols.clear();
      cachedPrices.clear();
      return;
    }

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('watchlist')) {
          List<dynamic> savedList = data['watchlist'] ?? [];
          selectedSymbols.clear();

          for (var e in savedList) {
            String sym = e.toString().toUpperCase();
            selectedSymbols.add(sym);
            if (!cachedPrices.containsKey(sym)) {
              cachedPrices[sym] = {'price': 0.0, 'dp': 0.0};
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error initializing watchlist: $e");
    }
  }

  /// High-performance concurrent pricing fetcher
  static Future<void> fetchWatchlistPrices() async {
    if (selectedSymbols.isEmpty || isFetchingPrices) return;

    isFetchingPrices = true;

    final tasks = selectedSymbols.map((symbol) async {
      try {
        final quote = await _finnhubService.fetchLiveQuote(symbol);
        if (quote.containsKey('c') && quote['c'] != null && quote['c'] != 0) {
          cachedPrices[symbol] = {
            'price': double.parse(quote['c'].toString()),
            'dp': double.parse((quote['dp'] ?? 0.0).toString()),
          };
        }
      } catch (e) {
        debugPrint("Failed to fetch concurrent live metric for $symbol: $e");
      }
    });

    await Future.wait(tasks);
    isFetchingPrices = false;
  }

  /// Toggles saving or deleting the ticker with instant local return completion
  static Future<bool> toggleWatchlist(String symbol, BuildContext context) async {
    final User? user = _auth.currentUser;
    final cleanSymbol = symbol.trim().toUpperCase();

    if (user == null) {
      _showToast(context, 'Authentication required!', isError: true);
      return false;
    }

    final DocumentReference userDoc = _firestore.collection('users').doc(user.uid);

    if (selectedSymbols.contains(cleanSymbol)) {
      selectedSymbols.remove(cleanSymbol);
      cachedPrices.remove(cleanSymbol);
      _showToast(context, '$cleanSymbol removed from Watchlist');

      try {
        await userDoc.update({
          'watchlist': FieldValue.arrayRemove([cleanSymbol])
        });
      } catch (_) {}
      return false; // Returns current state: Not starred
    } else {
      selectedSymbols.add(cleanSymbol);
      cachedPrices[cleanSymbol] = {'price': 0.0, 'dp': 0.0};
      _showToast(context, '$cleanSymbol added to Watchlist!');

      try {
        await userDoc.set({
          'watchlist': FieldValue.arrayUnion([cleanSymbol])
        }, SetOptions(merge: true));

        // Background fetch the single asset real quick
        final quote = await _finnhubService.fetchLiveQuote(cleanSymbol);
        if (quote.containsKey('c') && quote['c'] != null) {
          cachedPrices[cleanSymbol] = {
            'price': double.parse(quote['c'].toString()),
            'dp': double.parse((quote['dp'] ?? 0.0).toString()),
          };
        }
      } catch (_) {}
      return true; // Returns current state: Starred
    }
  }

  static void _showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF14B8A6),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}