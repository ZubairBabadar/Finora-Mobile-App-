import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Fixed library namespace import

class Transaction {
  final String type;
  final String symbol;
  final double shares;
  final double price;
  final String date;

  Transaction({
    required this.type,
    required this.symbol,
    required this.shares,
    required this.price,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'symbol': symbol,
    'shares': shares,
    'price': price,
    'date': date,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    type: map['type'] ?? 'BUY',
    symbol: map['symbol'] ?? '',
    shares: (map['shares'] ?? 0.0).toDouble(),
    price: (map['price'] ?? 0.0).toDouble(),
    date: map['date'] ?? '',
  );
}

class Holding {
  final String symbol;
  final String name;
  double shares;
  double avgCost;
  double currentPrice;

  Holding({
    required this.symbol,
    required this.name,
    required this.shares,
    required this.avgCost,
    required this.currentPrice,
  });

  Map<String, dynamic> toMap() => {
    'symbol': symbol,
    'name': name,
    'shares': shares,
    'avgCost': avgCost,
    'currentPrice': currentPrice,
  };

  factory Holding.fromMap(Map<String, dynamic> map) => Holding(
    symbol: map['symbol'] ?? '',
    name: map['name'] ?? '',
    shares: (map['shares'] ?? 0.0).toDouble(),
    avgCost: (map['avgCost'] ?? 0.0).toDouble(),
    currentPrice: (map['currentPrice'] ?? 0.0).toDouble(),
  );
}

class PortfolioManager extends ChangeNotifier {
  double _buyingPower = 0.00; // FIXED: Initialized default starting wallet balance to exactly 0.00
  List<Holding> _holdings = [];
  List<Transaction> _transactions = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PortfolioManager() {
    // Automatically listen to auth state to load proper data streams dynamically
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        loadUserDataFromCloud();
      } else {
        _resetLocalState();
      }
    });
  }

  // Getters
  double get buyingPower => _buyingPower;
  List<Holding> get holdings => _holdings;
  List<Transaction> get transactions => _transactions;

  // FIXED: Renamed inner parameter variable names from 'sum' to 'total' to avoid visible type collision warnings
  double get totalInvested => _holdings.fold(0.0, (total, item) => total + (item.shares * item.avgCost));
  double get totalStockValue => _holdings.fold(0.0, (total, item) => total + (item.shares * item.currentPrice));
  double get totalPortfolioValue => totalStockValue + _buyingPower;
  double get totalPnL => totalStockValue - totalInvested;

  void _resetLocalState() {
    _buyingPower = 0.00; // FIXED: Set fallback allocation state to exactly 0.00 on logout
    _holdings = [];
    _transactions = [];
    notifyListeners();
  }

  // Cloud Firestore Persistence Layer Pipelines
  Future<void> loadUserDataFromCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).collection('portfolio').doc('data').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _buyingPower = (data['buyingPower'] ?? 0.00).toDouble(); // FIXED: Decoupled 5000.00 cloud fallback assignment

        if (data['holdings'] != null) {
          _holdings = (data['holdings'] as List).map((h) => Holding.fromMap(h)).toList();
        }
        if (data['transactions'] != null) {
          _transactions = (data['transactions'] as List).map((t) => Transaction.fromMap(t)).toList();
        }
        notifyListeners();
      } else {
        // FIXED: Explicitly initialize new database profiles with 0.00 capital values instantly
        _buyingPower = 0.00;
        _holdings = [];
        _transactions = [];
        notifyListeners();
        saveUserDataToCloud();
      }
    } catch (e) {
      debugPrint("Error fetching cloud portfolio values: $e");
    }
  }

  Future<void> saveUserDataToCloud() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('portfolio').doc('data').set({
        'buyingPower': _buyingPower,
        'holdings': _holdings.map((h) => h.toMap()).toList(),
        'transactions': _transactions.map((t) => t.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Cloud storage engine transaction failure: $e");
    }
  }

  // Core Wallet Funding
  void addFunds(double amount) {
    _buyingPower += amount;
    notifyListeners();
    saveUserDataToCloud();
  }

  // Global Execution Engine
  bool executeTrade({
    required String type,
    required String symbol,
    required String companyName,
    required double shares,
    required double currentPrice,
    required BuildContext context,
  }) {
    final double totalCost = shares * currentPrice;

    if (type == 'BUY') {
      if (totalCost > _buyingPower) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Transaction Failed: Insufficient funds! Need €${totalCost.toStringAsFixed(2)}, but you only have €${_buyingPower.toStringAsFixed(2)}.'),
          ),
        );
        return false;
      }

      _buyingPower -= totalCost;

      final index = _holdings.indexWhere((h) => h.symbol == symbol);
      if (index >= 0) {
        double existingShares = _holdings[index].shares;
        double existingAvgCost = _holdings[index].avgCost;

        _holdings[index].shares = existingShares + shares;
        _holdings[index].avgCost = ((existingShares * existingAvgCost) + totalCost) / (existingShares + shares);
      } else {
        _holdings.add(Holding(
          symbol: symbol,
          name: companyName,
          shares: shares,
          avgCost: currentPrice,
          currentPrice: currentPrice,
        ));
      }
    } else {
      final index = _holdings.indexWhere((h) => h.symbol == symbol);
      if (index == -1 || _holdings[index].shares < shares) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFEF4444),
            content: Text('Transaction Failed: You do not own enough shares to sell.'),
          ),
        );
        return false;
      }

      _buyingPower += totalCost;
      _holdings[index].shares -= shares;

      if (_holdings[index].shares == 0) {
        _holdings.removeAt(index);
      }
    }

    _transactions.insert(0, Transaction(
      type: type,
      symbol: symbol,
      shares: shares,
      price: currentPrice,
      date: DateFormat('MMMM dd, yyyy').format(DateTime.now()),
    ));

    notifyListeners();
    saveUserDataToCloud();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text('Successfully executed order: $type $shares shares of $symbol.'),
      ),
    );
    return true;
  }
}

// Global shared state initialization reference
final portfolioManager = PortfolioManager();