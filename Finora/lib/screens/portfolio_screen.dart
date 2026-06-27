import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../portfolio_manager.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String _selectedTimeframe = '1W';
  String _selectedFundingSource = 'Bank Account';

  // Helper method that outputs custom plotting feeds mixed with live calculations
  List<FlSpot> _getDynamicChartSpots() {
    double currentTotal = portfolioManager.totalPortfolioValue;

    // Smoothly scale chart baseline based on your actual holding balance data sets
    switch (_selectedTimeframe) {
      case '1M':
        return [
          FlSpot(0, currentTotal * 0.90),
          FlSpot(1, currentTotal * 0.94),
          FlSpot(2, currentTotal * 0.92),
          FlSpot(3, currentTotal * 0.97),
          FlSpot(4, currentTotal * 0.96),
          FlSpot(5, currentTotal),
        ];
      case '1Y':
        return [
          FlSpot(0, currentTotal * 0.75),
          FlSpot(1, currentTotal * 0.82),
          FlSpot(2, currentTotal * 0.80),
          FlSpot(3, currentTotal * 0.91),
          FlSpot(4, currentTotal * 0.93),
          FlSpot(5, currentTotal),
        ];
      case '1W':
      default:
        return [
          FlSpot(0, currentTotal * 0.96),
          FlSpot(1, currentTotal * 0.98),
          FlSpot(2, currentTotal * 0.95),
          FlSpot(3, currentTotal * 0.99),
          FlSpot(4, currentTotal * 0.97),
          FlSpot(5, currentTotal * 0.99),
          FlSpot(6, currentTotal),
        ];
    }
  }

  // Interactive Bottom Drawer Wallet funding sheet implementation
  void _openWalletFundingSheet() {
    final TextEditingController amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131D31),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Deposit Fiat Capital', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Transfer funds into your internal trading wallet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              const Divider(color: Color(0xFF22314F), height: 24),

              const Text('Select Payment Method', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedFundingSource,
                dropdownColor: const Color(0xFF131D31),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                items: ['Bank Account', 'PayPal', 'Credit Card'].map((src) {
                  return DropdownMenuItem(value: src, child: Text(src));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => _selectedFundingSource = val);
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount to Deposit (€)',
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22314F))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF14B8A6))),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final double? amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    portfolioManager.addFunds(amount);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF10B981),
                        content: Text('Successfully deposited €${amount.toStringAsFixed(2)} via $_selectedFundingSource.'),
                      ),
                    );
                  }
                },
                child: const Text('Complete Funding', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: portfolioManager,
      builder: (context, child) {
        final bool isPnLPositive = portfolioManager.totalPnL >= 0;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF131D31),
            elevation: 0,
            title: const Text('Your Portfolio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      },
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
              _buildMetricItem('Total Portfolio Value', '€${portfolioManager.totalPortfolioValue.toStringAsFixed(2)}', Colors.white),
              _buildMetricItem(
                  "Total Growth Return",
                  "${isPnLPositive ? '+' : ''}€${portfolioManager.totalPnL.toStringAsFixed(2)}",
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
              GestureDetector(
                onTap: _openWalletFundingSheet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Buying Power', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.add_circle_outline, color: Color(0xFF38BDF8), size: 14)
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('€${portfolioManager.buyingPower.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              _buildMetricItem('Total Invested Basis', '€${portfolioManager.totalInvested.toStringAsFixed(2)}', Colors.white70),
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
    final activeSpots = _getDynamicChartSpots();

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

          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => const Color(0xFF1E293B),
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
                    color: const Color(0xFF14B8A6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
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
    final holdings = portfolioManager.holdings;

    if (holdings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF22314F)),
        ),
        child: const Text(
          'No active stock allocations yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: holdings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = holdings[index];
        final double currentVal = item.shares * item.currentPrice;
        final double profitLoss = currentVal - (item.shares * item.avgCost);
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
                  Text(item.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('${item.shares.toStringAsFixed(1)} shares', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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
    final transactions = portfolioManager.transactions;

    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF22314F)),
        ),
        child: const Text(
          'No transaction logs registered under this profile.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF22314F)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(color: Color(0xFF22314F), height: 1),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isBuy = tx.type == 'BUY';

          return ListTile(
            dense: true,
            leading: Icon(
              isBuy ? Icons.arrow_downward : Icons.arrow_upward,
              color: isBuy ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
              size: 18,
            ),
            title: Text('${tx.type} ${tx.symbol}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(tx.date, style: const TextStyle(color: Color(0xFF64748B))),
            trailing: Text(
              '${tx.shares.toStringAsFixed(1)} @ €${tx.price.toStringAsFixed(2)}',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
          );
        },
      ),
    );
  }
}