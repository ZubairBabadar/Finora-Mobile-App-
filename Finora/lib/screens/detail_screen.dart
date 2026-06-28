import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../widgets/app_logo.dart';
import '../main.dart';
import '../services/finnhub_service.dart';
import '../portfolio_manager.dart'; // REQUIRED: Import your portfolioManager pipeline
import '../widgets/trade_sheet.dart'; // REQUIRED: Link your trade verification layout panel

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

  // --- TIMEFRAME FILTERS ---
  String _selectedTimeframe = '1D';

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
    if (!mounted) return;
    setState(() => _isLoadingGraph = true);

    String resolution = '5';
    if (_selectedTimeframe == '1W') resolution = '60';
    if (_selectedTimeframe == '1M') resolution = 'D';

    final List<double> points = await _finnhubService.fetchChartCoordinates(symbol, resolution);
    final quote = await _finnhubService.fetchLiveQuote(symbol);

    if (mounted) {
      setState(() {
        if (points.isNotEmpty) {
          _chartPoints = points;
        } else {
          _chartPoints = _generateFallbackSpots(_currentLivePrice, _selectedTimeframe);
        }
        if (quote.containsKey('c') && quote['c'] != 0) {
          _currentLivePrice = double.parse(quote['c'].toString());
        }
        _isLoadingGraph = false;
      });
    }
  }

  List<double> _generateFallbackSpots(double basePrice, String timeframe) {
    final Random rand = Random();
    int size = timeframe == '1D' ? 6 : (timeframe == '1W' ? 7 : 12);
    List<double> fallback = [basePrice];
    for (int i = 1; i < size; i++) {
      double changePercent = (rand.nextDouble() * 0.04) - 0.018;
      fallback.add(fallback.last * (1 + changePercent));
    }
    return fallback;
  }

  // --- STATISTICAL HELPERS ---
  double get _minPrice => _chartPoints.isNotEmpty ? _chartPoints.reduce(min) : 100.0;
  double get _maxPrice => _chartPoints.isNotEmpty ? _chartPoints.reduce(max) : 200.0;
  double get _avgPrice => _chartPoints.isNotEmpty ? _chartPoints.reduce((a, b) => a + b) / _chartPoints.length : 150.0;

  // --- PREMIUM SYSTEM: BULLETPROOF METRIC POSITION DISTRIBUTOR ---
  String _getXAxisLabelText(double value, double maxVal) {
    if (value == 0) {
      return _selectedTimeframe == '1D' ? '9 AM' : (_selectedTimeframe == '1W' ? 'Mon' : 'Wk 1');
    } else if ((value - maxVal / 3).abs() < 0.1) {
      return _selectedTimeframe == '1D' ? '12 PM' : (_selectedTimeframe == '1W' ? 'Wed' : 'Wk 2');
    } else if ((value - 2 * maxVal / 3).abs() < 0.1) {
      return _selectedTimeframe == '1D' ? '3 PM' : (_selectedTimeframe == '1W' ? 'Fri' : 'Wk 3');
    } else if ((value - maxVal).abs() < 0.1) {
      return _selectedTimeframe == '1D' ? 'Close' : (_selectedTimeframe == '1W' ? 'Sun' : 'Wk 4');
    }
    return '';
  }

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
    final List<dynamic> newsItems = stockData['newsList'] ?? [];

    // Safe mathematical paddings
    final double computedMinY = _minPrice - (_minPrice * 0.015);
    final double computedMaxY = _maxPrice + (_maxPrice * 0.015);
    final double verticalSpread = computedMaxY - computedMinY;
    final double safeHorizontalInterval = verticalSpread > 0 ? verticalSpread / 3 : 1.0;

    // Fixed step intervals calculated directly from data coordinates length boundaries
    final double xMaxLimit = _chartPoints.length > 1 ? (_chartPoints.length - 1).toDouble() : 1.0;
    final double safeVerticalInterval = xMaxLimit / 3;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppLogoTitle(title: '${stockData['symbol']} Index'),
      ),
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

            // TIMEFRAME CONTROLS PILL BAR WIDGET
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: ['1D', '1W', '1M'].map((timeframe) {
                  final bool isActive = _selectedTimeframe == timeframe;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_selectedTimeframe == timeframe) return;
                        _selectedTimeframe = timeframe;
                        _loadLiveChartAndData(stockData['symbol']);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF0F172A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isActive ? Border.all(color: const Color(0xFF14B8A6).withValues(alpha:0.4)) : null,
                        ),
                        child: Text(
                          timeframe,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isActive ? const Color(0xFF14B8A6) : const Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // DYNAMIC INFORMATIVE FINANCIAL CHART
            const Text("Historical Interval Trends", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Container(
              height: 260,
              width: double.infinity,
              padding: const EdgeInsets.only(right: 20, top: 25, bottom: 10, left: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  border: Border.all(color: const Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(16)
              ),
              child: _isLoadingGraph
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)))
                  : LineChart(
                LineChartData(
                  minY: computedMinY,
                  maxY: computedMaxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: safeHorizontalInterval,
                    getDrawingHorizontalLine: (value) => const FlLine(
                        color: Color(0xFF334155),
                        strokeWidth: 1,
                        dashArray: [4, 4]
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: safeVerticalInterval, // FIX: Locked to mathematical grid steps to eliminate text replication duplication
                        getTitlesWidget: (value, meta) {
                          final label = _getXAxisLabelText(value, xMaxLimit);
                          return Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 55,
                        interval: safeHorizontalInterval, // FIX: Tied directly to the grid vertical spread metrics to stop text overlapping
                        getTitlesWidget: (value, meta) {
                          return Text('\$${value.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return TouchedSpotIndicatorData(
                          FlLine(color: const Color(0xFF14B8A6), strokeWidth: 2),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 5,
                              color: const Color(0xFF0F172A),
                              strokeColor: const Color(0xFF14B8A6),
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => const Color(0xFF0F172A),
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((barSpot) {
                          return LineTooltipItem(
                            FinoraApp.formatPrice(barSpot.y),
                            const TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold, fontSize: 13),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartPoints.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value)).toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      preventCurveOverShooting: true,
                      color: trendColor,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            trendColor.withValues(alpha:0.24),
                            trendColor.withValues(alpha:0.00),
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
            const SizedBox(height: 20),

            // METRICS ROW
            if (!_isLoadingGraph)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol('Period Low', FinoraApp.formatPrice(_minPrice)),
                    _buildMetricCol('Period High', FinoraApp.formatPrice(_maxPrice)),
                    _buildMetricCol('Average Val', FinoraApp.formatPrice(_avgPrice)),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // INTERACTIVE SIMULATOR TILES
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () {
                      // FIXED: Open modal confirmation slide drawer for BUY trades
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF131D31),
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (context) => TradeSheet(
                          symbol: stockData['symbol'],
                          companyName: stockData['name'],
                          currentPrice: _currentLivePrice,
                          tradeType: 'BUY',
                        ),
                      );
                    },
                    child: const Text('BUY IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () {
                      // FIXED: Validate allocation inventory position before rendering a LIQUIDATE modal
                      final bool hasInventory = portfolioManager.holdings.any((h) => h.symbol == stockData['symbol']);

                      if (!hasInventory) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFEF4444),
                            content: Text("Liquidation Denied: No active shares owned for ${stockData['symbol']}"),
                          ),
                        );
                        return;
                      }

                      showModalBottomSheet(
                        context: context,
                        backgroundColor: const Color(0xFF131D31),
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (context) => TradeSheet(
                          symbol: stockData['symbol'],
                          companyName: stockData['name'],
                          currentPrice: _currentLivePrice,
                          tradeType: 'LIQUIDATE',
                        ),
                      );
                    },
                    child: const Text('LIQUIDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- LIVE TRENDING NEWS SUBSECTION ---
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
                physics: const NeverScrollableScrollPhysics(),
                itemCount: newsItems.length > 5 ? 5 : newsItems.length,
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