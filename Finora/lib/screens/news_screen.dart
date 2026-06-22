import 'package:flutter/material.dart';
import '../main.dart';
import '../services/twelve_data_service.dart';
import '../services/watchlist_manager.dart';
import '../widgets/app_logo.dart';

class MarketNewsScreen extends StatefulWidget {
  const MarketNewsScreen({super.key});

  @override
  State<MarketNewsScreen> createState() => _MarketNewsScreenState();
}

class _MarketNewsScreenState extends State<MarketNewsScreen> {
  final FinnhubService _finnhubService = FinnhubService();
  final Map<String, Map<String, dynamic>> _liveData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWatchlistMetrics();
  }

  Future<void> _loadWatchlistMetrics() async {
    setState(() => _isLoading = true);
    for (String symbol in WatchlistManager.selectedSymbols) {
      final quote = await _finnhubService.fetchLiveQuote(symbol);
      final double currentPrice = double.parse((quote['c'] ?? 150.0).toString());
      final double dp = double.parse((quote['dp'] ?? 0.0).toString());

      _liveData[symbol] = {
        'price': currentPrice,
        'change': '${dp >= 0 ? "+" : ""}${dp.toStringAsFixed(2)}%',
        'isBullish': dp >= 0
      };
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final activeSymbols = WatchlistManager.selectedSymbols.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Watchlist & News'),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF14B8A6)), onPressed: _loadWatchlistMetrics)],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WATCHLIST SECTION
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text("My Watchlist", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            if (activeSymbols.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Your watchlist is empty. Star items on the home screen to track them!", style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: activeSymbols.length,
                itemBuilder: (context, index) {
                  final symbol = activeSymbols[index];
                  final data = _liveData[symbol] ?? {'price': 0.0, 'change': '0.00%', 'isBullish': true};

                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(FinoraApp.formatPrice(data['price']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(data['change'], style: TextStyle(color: data['isBullish'] ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            // TRENDING NEWS SECTION
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text("Trending News", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            _buildNewsCard('Tech Surge Alert', 'NVIDIA and Microsoft shares hit record highs following heavy enterprise cloud infrastructure deployments worldwide.', '10m ago'),
            _buildNewsCard('Federal Rate Policy Update', 'Central reserve parameters indicate prolonged stabilization holding pattern structural updates.', '42m ago'),
            _buildNewsCard('Global Logistics', 'Supply chain efficiency rises as major ports automate tracking operations.', '2h ago'),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(String title, String description, String time) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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