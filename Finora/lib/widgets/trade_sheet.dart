import 'package:flutter/material.dart';
import '../portfolio_manager.dart';

class TradeSheet extends StatefulWidget {
  final String symbol;
  final String companyName;
  final double currentPrice;
  final String tradeType; // 'BUY' or 'LIQUIDATE'

  const TradeSheet({
    super.key,
    required this.symbol,
    required this.companyName,
    required this.currentPrice,
    required this.tradeType,
  });

  @override
  State<TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<TradeSheet> {
  final TextEditingController _sharesController = TextEditingController();
  double _calculatedTotal = 0.0;
  double _ownedShares = 0.0;

  @override
  void initState() {
    super.initState();
    // Look up if the user already owns shares of this stock
    final existingHolding = portfolioManager.holdings.firstWhere(
          (h) => h.symbol == widget.symbol,
      orElse: () => Holding(symbol: widget.symbol, name: widget.companyName, shares: 0, avgCost: 0, currentPrice: widget.currentPrice),
    );
    _ownedShares = existingHolding.shares;

    // If liquidating, pre-fill with the maximum available shares automatically
    if (widget.tradeType == 'LIQUIDATE') {
      _sharesController.text = _ownedShares.toStringAsFixed(2);
      _calculatedTotal = _ownedShares * widget.currentPrice;
    }

    _sharesController.addListener(_updateTotal);
  }

  void _updateTotal() {
    final double? shares = double.tryParse(_sharesController.text);
    setState(() {
      _calculatedTotal = (shares ?? 0.0) * widget.currentPrice;
    });
  }

  @override
  void dispose() {
    _sharesController.removeListener(_updateTotal);
    _sharesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.tradeType == 'BUY';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBuy ? 'Buy ${widget.symbol}' : 'Liquidate ${widget.symbol}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '€${widget.currentPrice.toStringAsFixed(2)} / share',
                style: const TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isBuy
                ? 'Available Buying Power: €${portfolioManager.buyingPower.toStringAsFixed(2)}'
                : 'Your Position: ${_ownedShares.toStringAsFixed(2)} shares available',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const Divider(color: Color(0xFF22314F), height: 24),

          if (isBuy) ...[
            TextField(
              controller: _sharesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Number of Shares',
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22314F))),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF14B8A6))),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shares to Liquidate', style: TextStyle(color: Color(0xFF94A3B8))),
                  Text(_ownedShares.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Order Value:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
              Text(
                '€${_calculatedTotal.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBuy ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final double? shares = double.tryParse(_sharesController.text);
              if (shares == null || shares <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number of shares.')),
                );
                return;
              }

              // Route directly into your global PortfolioManager execution engine
              final bool success = portfolioManager.executeTrade(
                type: isBuy ? 'BUY' : 'SELL', // Liquidate passes 'SELL' to your engine logic
                symbol: widget.symbol,
                companyName: widget.companyName,
                shares: shares,
                currentPrice: widget.currentPrice,
                context: context,
              );

              if (success) {
                Navigator.pop(context); // Close the sheet upon successful transaction
              }
            },
            child: Text(
              isBuy ? 'Confirm Buy Order' : 'Confirm Liquidation',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}