import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // ADDED: High-performance financial graphing package

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String _selectedTimeframe = '1W';

  // Real-world dummy datasets optimized for premium data plotting curves
  final Map<String, List<FlSpot>> _chartDataPoints = {
    '1W': [
      const FlSpot(0, 14200.0),
      const FlSpot(1, 14350.5),
      const FlSpot(2, 14110.0),
      const FlSpot(3, 14490.2),
      const FlSpot(4, 14620.0),
      const FlSpot(5, 14550.8),
      const FlSpot(6, 14812.4),
    ],
    '1M': [
      const FlSpot(0, 13100.0),
      const FlSpot(1, 13400.0),
      const FlSpot(2, 13250.0),
      const FlSpot(3, 13900.0),
      const FlSpot(4, 14200.0),
      const FlSpot(5, 14812.4),
    ],
    '1Y': [
      const FlSpot(0, 10200.0),
      const FlSpot(1, 11500.0),
      const FlSpot(2, 11100.0),
      const FlSpot(3, 12800.0),
      const FlSpot(4, 13900.0),
      const FlSpot(5, 14812.4),
    ],
  };

  final List<Map<String, dynamic>> _holdings = [
    {
      'symbol': 'AAPL',
      'name': 'Apple Inc.',
      'shares': 12.5,
      'avgCost': 175.20,
      'currentPrice': 189.45,
    },
    {
      'symbol': 'TSLA',
      'name': 'Tesla Motor Co.',
      'shares': 8.0,
      'avgCost': 210.50,
      'currentPrice': 177.90,
    },
    {
      'symbol': 'NVDA',
      'name': 'NVIDIA Corp.',
      'shares': 15.0,
      'avgCost': 450.00,
      'currentPrice': 875.12,
    },
  ];

  final List<Map<String, dynamic>> _transactions = [
    {'type': 'BUY', 'symbol': 'NVDA', 'shares': 5, 'price': 480.25, 'date': 'June 22, 2026'},
    {'type': 'BUY', 'symbol': 'AAPL', 'shares': 2.5, 'price': 178.10, 'date': 'June 18, 2026'},
    {'type': 'SELL', 'symbol': 'TSLA', 'shares': 3.0, 'price': 195.00, 'date': 'June 10, 2026'},
  ];

  final double _buyingPower = 2450.75;

  double get _totalValue {
    double stockValue = _holdings.fold(0.0, (sum, item) => sum + (item['shares'] * item['currentPrice']));
    return stockValue + _buyingPower;
  }

  double get _totalInvested {
    return _holdings.fold(0.0, (sum, item) => sum + (item['shares'] * item['avgCost']));
  }

  double get _totalPnL {
    double currentStockValue = _holdings.fold(0.0, (sum, item) => sum + (item['shares'] * item['currentPrice']));
    return currentStockValue - _totalInvested;
  }

  @override
  Widget build(BuildContext context) {
    final bool isPnLPositive = _totalPnL >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131D31),
        elevation: 0,
        title: const Text('Finora Portfolio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderMetrics(isPnLPositive),
            const SizedBox(height: 20),
            _buildPerformanceChartCard(),
            const SizedBox(height: 24),
            const Text(
              'Your Holdings',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildHoldingsSection(),
            const SizedBox(height: 24),
            const Text(
              'Recent Transactions',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTransactionHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetrics(bool isPnLPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22314F)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('Total Portfolio Value', '€${_totalValue.toStringAsFixed(2)}', Colors.white),
              _buildMetricItem(
                  "Today's P/L",
                  "${isPnLPositive ? '+' : ''}€${_totalPnL.toStringAsFixed(2)}",
                  isPnLPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(color: Color(0xFF22314F), thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('Buying Power', '€${_buyingPower.toStringAsFixed(2)}', const Color(0xFF38BDF8)),
              _buildMetricItem('Total Invested', '€${_totalInvested.toStringAsFixed(2)}', Colors.white70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPerformanceChartCard() {
    final activeSpots = _chartDataPoints[_selectedTimeframe] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22314F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Performance History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: ['1W', '1M', '1Y'].map((timeframe) {
                  final isSelected = _selectedTimeframe == timeframe;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTimeframe = timeframe),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF14B8A6) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF22314F)),
                      ),
                      child: Text(
                        timeframe,
                        style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
          const SizedBox(height: 24),

          // DYNAMIC FL_CHART COMPONENT ENGINE
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false), // Clean premium look without grid noise
                titlesData: const FlTitlesData(show: false), // Minimalist stock-ticker aesthetic
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: const Color(0xFF1E293B),
                    tooltipBorder: const BorderSide(color: Color(0xFF14B8A6), width: 1),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        return LineTooltipItem(
                          '€${barSpot.y.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: activeSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF14B8A6), // Finora Brand Teal Line
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false), // Avoid cluttering the line track points
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF14B8A6).withValues(alpha:0.35),
                          const Color(0xFF14B8A6).withValues(alpha:0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsSection() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _holdings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _holdings[index];
        final double currentVal = item['shares'] * item['currentPrice'];
        final double profitLoss = currentVal - (item['shares'] * item['avgCost']);
        final bool isPositive = profitLoss >= 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF131D31),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF22314F)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['symbol'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('${item['shares']} shares', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('€${currentVal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${isPositive ? '+' : ''}€${profitLoss.toStringAsFixed(2)}',
                    style: TextStyle(color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF22314F)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFF22314F), height: 1),
        itemBuilder: (context, index) {
          final tx = _transactions[index];
          final isBuy = tx['type'] == 'BUY';

          return ListTile(
            dense: true,
            leading: Icon(
              isBuy ? Icons.arrow_downward : Icons.arrow_upward,
              color: isBuy ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
              size: 18,
            ),
            title: Text('${tx['type']} ${tx['symbol']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(tx['date'], style: const TextStyle(color: Color(0xFF64748B))),
            trailing: Text(
              '${tx['shares']} shares @ €${tx['price']}',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
          );
        },
      ),
    );
  }
}