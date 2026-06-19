import 'package:flutter/material.dart';
import '../main.dart';

class MarketNewsScreen extends StatefulWidget {
  const MarketNewsScreen({super.key});

  @override
  State<MarketNewsScreen> createState() => _MarketNewsScreenState();
}

class _MarketNewsScreenState extends State<MarketNewsScreen> {
  // Mock API Database Matrix divided by structural geographical filters
  final Map<String, List<Map<String, dynamic>>> _regionalStocks = {
    'United States': [
      {'symbol': 'AAPL', 'name': 'Apple Inc.', 'usdPrice': 188.38, 'change': '-7.29%', 'isBullish': false},
      {'symbol': 'TSLA', 'name': 'Tesla Motors', 'usdPrice': 239.43, 'change': '+1.42%', 'isBullish': true},
      {'symbol': 'NVDA', 'name': 'NVIDIA Corp.', 'usdPrice': 875.12, 'change': '+4.85%', 'isBullish': true},
    ],
    'Germany': [
      {'symbol': 'SAP', 'name': 'SAP SE Systems', 'usdPrice': 194.20, 'change': '+1.12%', 'isBullish': true},
      {'symbol': 'BMW', 'name': 'Bayerische Motoren', 'usdPrice': 102.55, 'change': '-2.40%', 'isBullish': false},
      {'symbol': 'VOW3', 'name': 'Volkswagen Group', 'usdPrice': 118.90, 'change': '+0.65%', 'isBullish': true},
    ],
    'United Kingdom': [
      {'symbol': 'BARC', 'name': 'Barclays plc Index', 'usdPrice': 2.30, 'change': '+3.15%', 'isBullish': true},
      {'symbol': 'BP', 'name': 'BP Oil Infrastructure', 'usdPrice': 4.85, 'change': '-1.22%', 'isBullish': false},
    ],
    'Japan': [
      {'symbol': '7203', 'name': 'Toyota Motor Corp.', 'usdPrice': 24.10, 'change': '+0.88%', 'isBullish': true},
      {'symbol': '6758', 'name': 'Sony Group Corp.', 'usdPrice': 82.45, 'change': '-1.95%', 'isBullish': false},
    ],
  };

  // Live News placeholder for real-time endpoint integration
  // API Suggestion: Use 'https://newsapi.org/' or 'https://finnhub.io/' to populate these parameters dynamically later.
  final String _newsApiKeyPlaceholder = "YOUR_FINNHUB_API_KEY_HERE";

  void _openNewsArticleReader(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131D31),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.5, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2740), minimumSize: const Size(double.infinity, 44)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Mark as Read', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> activeStocks = _regionalStocks[FinoraApp.globalCountryFilter] ?? _regionalStocks['United States']!;

    return Scaffold(
      appBar: AppBar(title: const AppLogoTitle(title: 'Market Pulse')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // REGIONAL REGION SELECTION DROPDOWN MENU
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Geographical Sector:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              DropdownButton<String>(
                value: FinoraApp.globalCountryFilter,
                dropdownColor: const Color(0xFF131D31),
                items: _regionalStocks.keys.map((String country) {
                  return DropdownMenuItem<String>(value: country, child: Text(country));
                }).toList(),
                onChanged: (newCountry) {
                  setState(() {
                    if (newCountry != null) FinoraApp.globalCountryFilter = newCountry;
                  });
                },
              ),
            ],
          ),
          const Divider(color: Color(0xFF22314F), height: 24),

          const Text('Live Active Watchlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          // Generates dynamic stock rows that adapt to the conversion rate rules
          ...activeStocks.map((stock) {
            return GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/stock-detail', arguments: {
                'symbol': stock['symbol'],
                'name': stock['name'],
                'usdPrice': stock['usdPrice'],
                'change': stock['change'],
                'isBullish': stock['isBullish']
              }).then((_) => setState(() {})), // Refresh screen values on coming back
              child: StockListItem(
                symbol: stock['symbol'],
                name: stock['name'],
                formattedPrice: FinoraApp.formatPrice(stock['usdPrice']),
                change: stock['change'],
                isBullish: stock['isBullish'],
              ),
            );
          }),

          const SizedBox(height: 28),
          const Text('Trending Live Updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => _openNewsArticleReader('Tech Surge Alert', 'NVIDIA shares hit record highs following heavy enterprise chip orders worldwide. Analytical trackers predict structural breakout vectors targeting higher margins.'),
            child: const NewsCard(title: 'Tech Surge', description: 'NVIDIA shares hit record highs following heavy enterprise chip orders worldwide...', time: '10m ago'),
          ),
          GestureDetector(
            onTap: () => _openNewsArticleReader('Federal Rate Policy Update', 'Central reserve parameters indicate prolonged stabilization holding pattern structural updates to tackle historical localized market margins.'),
            child: const NewsCard(title: 'Federal Rate Policy', description: 'Central reserve parameters indicate prolonged stabilization holding pattern structural updates...', time: '42m ago'),
          ),
        ],
      ),
    );
  }
}

class StockListItem extends StatelessWidget {
  final String symbol;
  final String name;
  final String formattedPrice;
  final String change;
  final bool isBullish;

  const StockListItem({
    super.key,
    required this.symbol,
    required this.name,
    required this.formattedPrice,
    required this.change,
    required this.isBullish,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF131D31),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF22314F), width: 0.8), borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        title: Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(name, style: const TextStyle(color: Color(0xFF94A3B8))),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formattedPrice, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text(change, style: TextStyle(color: isBullish ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;

  const NewsCard({super.key, required this.title, required this.description, required this.time});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A2740),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                Text(time, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(height: 1.4, color: Color(0xFFCBD5E1), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}