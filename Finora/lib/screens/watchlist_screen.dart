import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../widgets/stock_logo.dart';
import '../main.dart';
import '../services/finnhub_service.dart';
import '../services/watchlist_manager.dart';
import '../portfolio_manager.dart';// REQUIRED: Linking centralized state manager

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _lookoutNews = [];
  String _searchQuery = "";
  bool _isLoading = false;
  bool _isLoadingNews = false;

  static const String _token = "d8qhif1r01qr03nj4shgd8qhif1r01qr03nj4si0";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialSetup();

    _tabController.addListener(() {
      if (_tabController.index == 1 && !_tabController.indexIsChanging) {
        _fetchLookoutNews();
      }
    });
  }

  Future<void> _initialSetup() async {
    if (WatchlistManager.selectedSymbols.isEmpty) {
      await WatchlistManager.initializeWatchlist();
    }
    _loadWatchlistPrices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlistPrices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await WatchlistManager.fetchWatchlistPrices();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLookoutNews() async {
    final symbols = WatchlistManager.selectedSymbols.toList();
    if (symbols.isEmpty) {
      setState(() => _lookoutNews = []);
      return;
    }

    setState(() => _isLoadingNews = true);
    List<dynamic> compiledNews = [];

    // CHANGED: Pulls news dynamically for ALL saved watchlist elements concurrently
    final sampleTargets = symbols.toList();
    final today = DateTime.now().toString().substring(0, 10);
    // CHANGED: Expanded lookup timeline gap constraint to 30 days for continuous feeds
    final weekAgo = DateTime.now().subtract(const Duration(days: 30)).toString().substring(0, 10);

    final newsTasks = sampleTargets.map((symbol) async {
      try {
        final newsUrl = Uri.parse("https://finnhub.io/api/v1/company-news?symbol=$symbol&from=$weekAgo&to=$today&token=$_token");
        final response = await http.get(newsUrl);
        if (response.statusCode == 200) {
          final List<dynamic> parsed = json.decode(response.body);
          // CHANGED: Boosted standard layout snapshot to track up to 10 articles per ticket
          return parsed.take(10).toList();
        }
      } catch (_) {}
      return [];
    });

    final results = await Future.wait(newsTasks);
    for (var list in results) {
      compiledNews.addAll(list);
    }

    compiledNews.sort((a, b) => (b['datetime'] ?? 0).compareTo(a['datetime'] ?? 0));

    if (mounted) {
      setState(() {
        _lookoutNews = compiledNews;
        _isLoadingNews = false;
      });
    }
  }

  Future<void> _navigateToDetail(String symbol) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
      ),
    );

    try {
      final quote = await FinnhubService().fetchLiveQuote(symbol);
      final today = DateTime.now().toString().substring(0, 10);
      final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toString().substring(0, 10);

      final newsUrl = Uri.parse("https://finnhub.io/api/v1/company-news?symbol=$symbol&from=$weekAgo&to=$today&token=$_token");
      final response = await http.get(newsUrl);

      List<dynamic> parsedNewsList = [];
      if (response.statusCode == 200) {
        parsedNewsList = json.decode(response.body);
      }

      if (context.mounted) Navigator.pop(context);

      if (quote.containsKey('c') && quote['c'] != 0 && quote['c'] != null) {
        final double price = double.parse(quote['c'].toString());
        final double percent = double.parse((quote['dp'] ?? 0.0).toString());
        final bool isBullish = percent >= 0;

        if (context.mounted) {
          Navigator.pushNamed(context, '/stock-detail', arguments: {
            'symbol': symbol,
            'name': 'Saved Asset Security',
            'usdPrice': price,
            'change': '${isBullish ? "+" : ""}${percent.toStringAsFixed(2)}%',
            'isBullish': isBullish,
            'newsList': parsedNewsList
          }).then((_) {
            _loadWatchlistPrices();
            if (_tabController.index == 1) _fetchLookoutNews();
          });
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  // INTERACTIVE TRANSACTION OVERLAY SHEET FOR WATCHLIST TRADING
  void _openQuickBuyModal(String symbol, String name, double currentPrice) {
    final TextEditingController sharesController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131D31),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buy $symbol', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(name, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
                Text(FinoraApp.formatPrice(currentPrice), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: Color(0xFF22314F), height: 24),
            TextField(
              controller: sharesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Number of Shares',
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
                final double? inputShares = double.tryParse(sharesController.text);
                if (inputShares != null && inputShares > 0) {
                  final bool success = portfolioManager.executeTrade(
                    type: 'BUY',
                    symbol: symbol,
                    companyName: name,
                    shares: inputShares,
                    currentPrice: currentPrice,
                    context: context,
                  );
                  if (success) {
                    Navigator.pop(context);
                    _loadWatchlistPrices(); // Refresh local list context metrics
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount of shares.')),
                  );
                }
              },
              child: const Text('Confirm Purchase', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSymbols = WatchlistManager.selectedSymbols.where((symbol) {
      return symbol.toUpperCase().contains(_searchQuery.toUpperCase().trim());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Watchlist Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoading || _isLoadingNews
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh, color: Color(0xFF14B8A6)),
            onPressed: () {
              _loadWatchlistPrices();
              if (_tabController.index == 1) _fetchLookoutNews();
            },
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF14B8A6),
              labelColor: const Color(0xFF14B8A6),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              indicatorWeight: 2,
              tabs: const [
                Tab(text: "My Assets"),
                Tab(text: "Lookout Pulse"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search within saved assets...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF14B8A6), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),

              Expanded(
                child: filteredSymbols.isEmpty
                    ? Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Your Watchlist is empty.\nStar items on the home screen to track them!'
                        : 'No matching tickers found inside\nyour saved portfolio stack.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4),
                  ),
                )
                    : RefreshIndicator(
                  color: const Color(0xFF14B8A6),
                  onRefresh: _loadWatchlistPrices,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredSymbols.length,
                    separatorBuilder: (context, index) => const Divider(color: Color(0xFF1E293B), height: 1),
                    itemBuilder: (context, index) {
                      final symbol = filteredSymbols[index];
                      final data = WatchlistManager.cachedPrices[symbol] ?? {'price': 0.0, 'dp': 0.0};
                      final double currentPrice = data['price'] ?? 0.0;
                      final double percent = data['dp'] ?? 0.0;
                      final bool isBullish = percent >= 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        onTap: () => _navigateToDetail(symbol),
                        leading: StockLogo(symbol: symbol, size: 40),
                        title: Text(
                          symbol,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text('Global Market Security', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currentPrice == 0.0 ? "Loading..." : FinoraApp.formatPrice(currentPrice),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${isBullish ? "+" : ""}${percent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: isBullish ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            // QUICK BUY TRADING ACTION BUTTON
                            IconButton(
                              icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF14B8A6), size: 20),
                              onPressed: () => _openQuickBuyModal(symbol, 'Global Market Security', currentPrice),
                            ),
                            IconButton(
                              icon: const Icon(Icons.star, color: Color(0xFFEAB308), size: 20),
                              onPressed: () async {
                                await WatchlistManager.toggleWatchlist(symbol, context);
                                setState(() {});
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // TAB 2: LOOKOUT PULSE LIVE RECENT NEWS FEED
          _isLoadingNews
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)))
              : _lookoutNews.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'Track active security tickers under "My Assets"\nto generate specialized financial lookup intel feeds.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
              ),
            ),
          )
              : RefreshIndicator(
            color: const Color(0xFF14B8A6),
            onRefresh: _fetchLookoutNews,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _lookoutNews.length,
              itemBuilder: (context, index) {
                final story = _lookoutNews[index];
                final String channel = story['source'] ?? 'Market Brief';
                final String title = story['headline'] ?? '';
                final String overview = story['summary'] ?? '';
                final int epoch = story['datetime'] ?? 0;
                final String postTime = epoch > 0
                    ? DateFormat('MM/dd hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(epoch * 1000))
                    : 'Recent';

                if (title.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(channel.toUpperCase(), style: const TextStyle(color: Color(0xFF14B8A6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          Text(postTime, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.3)),
                      if (overview.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(overview, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.3)),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}