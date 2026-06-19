import 'package:flutter/material.dart';
import '../main.dart';

class StockDetailScreen extends StatelessWidget {
  const StockDetailScreen({super.key});

  void _showTradeConfirmation(BuildContext context, String action, String symbol, String finalPriceString) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131D31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF22314F))),
        title: Text('$action Order Executed', style: TextStyle(color: action == 'BUY' ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
        content: Text('Successfully processed transaction parameters for 1 share of $symbol at localized market price of $finalPriceString.', style: const TextStyle(color: Color(0xFFCBD5E1))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Confirm', style: TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> stockData = (ModalRoute.of(context)!.settings.arguments ?? {
      'symbol': 'AAPL',
      'name': 'Apple Inc.',
      'usdPrice': 188.38,
      'change': '-7.29%',
      'isBullish': false
    }) as Map<String, dynamic>;

    final bool isBullish = stockData['isBullish'] as bool;
    final Color trendColor = isBullish ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    // Calculates the absolute live display metric value using our global rule function
    String localizedPrice = FinoraApp.formatPrice(stockData['usdPrice'] as double);

    return Scaffold(
      appBar: AppBar(title: AppLogoTitle(title: '${stockData['symbol']} Analysis Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stockData['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(localizedPrice, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: trendColor)),
                  ],
                ),
                Icon(isBullish ? Icons.trending_up : Icons.trending_down, color: trendColor, size: 48),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF131D31), border: Border.all(color: const Color(0xFF22314F)), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('[ Real-time Live Line Chart Visualization ]', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => _showTradeConfirmation(context, 'BUY', stockData['symbol'], localizedPrice),
                    child: const Text('BUY / ACQUIRE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => _showTradeConfirmation(context, 'SELL', stockData['symbol'], localizedPrice),
                    child: const Text('SELL / LIQUIDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}