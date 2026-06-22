import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../widgets/app_logo.dart';
import '../main.dart';
import '../services/twelve_data_service.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  final FinnhubService _finnhubService = FinnhubService();
  List<double> _chartPoints = [150.0, 152.0, 151.0, 155.0, 154.0, 158.0];
  bool _isLoadingGraph = true;
  double _currentLivePrice = 0.0;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final Map<String, dynamic> stockData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _currentLivePrice = stockData['usdPrice'] as double;
      _loadLiveChartAndData(stockData['symbol']);
      _isInit = false;
    }
  }

  Future<void> _loadLiveChartAndData(String symbol) async {
    final List<double> points = await _finnhubService.fetchChartCoordinates(symbol);
    final quote = await _finnhubService.fetchLiveQuote(symbol);

    if (mounted) {
      setState(() {
        if (points.isNotEmpty) _chartPoints = points;
        if (quote.containsKey('c') && quote['c'] != 0) {
          _currentLivePrice = double.parse(quote['c'].toString());
        }
        _isLoadingGraph = false;
      });
    }
  }

  // --- STATISTICAL HELPERS ---
  double get _minPrice => _chartPoints.reduce(min);
  double get _maxPrice => _chartPoints.reduce(max);
  double get _avgPrice => _chartPoints.reduce((a, b) => a + b) / _chartPoints.length;

  // --- DYNAMIC TIME RELATIVE UTILITY PARSER ---
  String _convertTimestampToRelative(int unixSeconds) {
    final articleTime = DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);
    final difference = DateTime.now().difference(articleTime);

    if (difference.inDays > 0) return "${difference.inDays}d ago";
    if (difference.inHours > 0) return "${difference.inHours}h ago";
    if (difference.inMinutes > 0) return "${difference.inMinutes}m ago";
    return "Just now";
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> stockData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final bool isBullish = stockData['isBullish'] as bool;
    final Color trendColor = isBullish ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    // Unpack live company trending news array passed downstream via routing setups
    final List<dynamic> newsItems = stockData['newsList'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: AppLogoTitle(title: '${stockData['symbol']} Index')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADING PRICE AND OVERVIEW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stockData['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                        FinoraApp.formatPrice(_currentLivePrice),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: trendColor)
                    ),
                  ],
                ),
                Icon(isBullish ? Icons.trending_up : Icons.trending_down, color: trendColor, size: 44),
              ],
            ),
            const SizedBox(height: 24),

            // DYNAMIC INFORMATIVE FINANCIAL CHART
            const Text("Historical Interval Trends (Past 24H)", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Container(
              height: 260,
              width: double.infinity,
              padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10, left: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  border: Border.all(color: const Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(16)
              ),
              child: _isLoadingGraph
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)))
                  : LineChart(
                LineChartData(
                  minY: _minPrice - (_minPrice * 0.02),
                  maxY: _maxPrice + (_maxPrice * 0.02),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: ((_maxPrice - _minPrice) / 3).clamp(0.1, double.infinity),
                    getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF334155), strokeWidth: 1, dashArray: [5, 5]),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          const times = ['9AM', '11AM', '1PM', '3PM', '5PM', 'Close'];
                          if (value.toInt() >= 0 && value.toInt() < times.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Text(times[value.toInt()], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text('\$${value.toInt()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: const Color(0xFF0F172A),
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((barSpot) {
                          return LineTooltipItem(
                            FinoraApp.formatPrice(barSpot.y),
                            const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartPoints.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value)).toList(),
                      isCurved: true,
                      color: trendColor,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: trendColor.withAlpha(30)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // METRICS ROW
            if (!_isLoadingGraph)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol('24H Low', FinoraApp.formatPrice(_minPrice)),
                    _buildMetricCol('24H High', FinoraApp.formatPrice(_maxPrice)),
                    _buildMetricCol('Avg Vol', FinoraApp.formatPrice(_avgPrice)),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // INTERACTIVE SIMULATOR TILES
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {},
                    child: const Text('BUY IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {},
                    child: const Text('LIQUIDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- NEW: LIVE TRENDING NEWS SUBSECTION ---
            Text(
              "Trending Live News: ${stockData['symbol']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            if (newsItems.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  "No immediate news articles fetched for this asset class over the past week.",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Disables conflict with outer singlechildscrollview
                itemCount: newsItems.length > 5 ? 5 : newsItems.length, // Cap it to top 5 articles max for cleanliness
                itemBuilder: (context, index) {
                  final item = newsItems[index];
                  final int timestamp = item['datetime'] ?? 0;
                  final String headline = item['headline'] ?? '';
                  final String source = item['source'] ?? 'Market Feed';
                  final String imageUrl = item['image'] ?? '';

                  if (headline.isEmpty) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display article image thumbnail if available
                        if (imageUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => Container(
                                width: 70,
                                height: 70,
                                color: const Color(0xFF334155),
                                child: const Icon(Icons.newspaper, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                headline,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    source.toUpperCase(),
                                    style: const TextStyle(color: Color(0xFF14B8A6), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _convertTimestampToRelative(timestamp),
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}