import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Ensure intl is added to pubspec.yaml for timestamp rendering
import '../main.dart';
import '../services/twelve_data_service.dart';
import '../services/watchlist_manager.dart';
import '../widgets/app_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FinnhubService _finnhubService = FinnhubService();
  String _searchQuery = "";
  bool _isRefreshing = false;
  String _locationStatus = "Detecting location...";
  String _selectedCountry = 'US';
  String? _lastUpdatedTimestamp; // Bug 1 & 2: Rate limit caching safeguard state
  String? _apiErrorMessage;

  final Map<String, String> _countryOptions = {
    'US': 'United States 🇺🇸',
    'GB': 'United Kingdom 🇬🇧',
    'DE': 'Germany 🇩🇪',
    'CA': 'Canada 🇨🇦',
  };

  final Map<String, Map<String, Map<String, dynamic>>> _regionalMarkets = {
    'US': {
      'AAPL': {'name': 'Apple Inc.', 'price': 188.30, 'dp': -0.45},
      'TSLA': {'name': 'Tesla Motors', 'price': 239.43, 'dp': 1.12},
      'NVDA': {'name': 'NVIDIA Corp.', 'price': 875.12, 'dp': 3.85},
      'MSFT': {'name': 'Microsoft Corp.', 'price': 420.55, 'dp': 0.85},
      'AMZN': {'name': 'Amazon Inc.', 'price': 178.15, 'dp': -1.20},
      'GOOG': {'name': 'Alphabet Inc.', 'price': 150.22, 'dp': 2.41},
    },
    'GB': {
      'BP': {'name': 'BP plc ADR', 'price': 38.20, 'dp': -0.12},
      'HSBC': {'name': 'HSBC Holdings ADR', 'price': 42.15, 'dp': 0.65},
      'VOD': {'name': 'Vodafone Group ADR', 'price': 8.90, 'dp': -1.10},
      'GSK': {'name': 'GlaxoSmithKline ADR', 'price': 40.50, 'dp': 0.35},
      'AZN': {'name': 'AstraZeneca plc ADR', 'price': 67.80, 'dp': 1.45},
      'BTI': {'name': 'British American Tobacco', 'price': 31.10, 'dp': -0.22},
    },
    'DE': {
      'SAP': {'name': 'SAP SE ADR', 'price': 192.40, 'dp': 1.85},
      'SIEGY': {'name': 'Siemens AG ADR', 'price': 94.20, 'dp': -0.40},
      'ALIZY': {'name': 'Allianz SE ADR', 'price': 28.50, 'dp': 0.15},
      'VWAGY': {'name': 'Volkswagen AG ADR', 'price': 14.35, 'dp': -2.10},
      'BMWYY': {'name': 'BMW AG ADR', 'price': 33.10, 'dp': 0.95},
      'DTEGY': {'name': 'Deutsche Telekom ADR', 'price': 24.15, 'dp': 0.30},
    },
    'CA': {
      'RY': {'name': 'Royal Bank of Canada', 'price': 102.40, 'dp': 0.55},
      'TD': {'name': 'Toronto-Dominion Bank', 'price': 61.20, 'dp': -0.80},
      'ENB': {'name': 'Enbridge Inc.', 'price': 36.45, 'dp': -0.15},
      'SHOP': {'name': 'Shopify Inc.', 'price': 74.90, 'dp': 4.12},
      'CNI': {'name': 'Canadian National Railway', 'price': 122.30, 'dp': -0.25},
      'BNS': {'name': 'Bank of Nova Scotia', 'price': 48.15, 'dp': 0.10},
    }
  };

  Map<String, Map<String, dynamic>> _allStocks = {};

  @override
  void initState() {
    super.initState();
    _allStocks = Map.from(_regionalMarkets[_selectedCountry]!);
    _handleLocationPermission();
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationStatus = "Location services disabled");
      _fetchLivePrices();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _locationStatus = "Permission denied");
        _fetchLivePrices();
        return;
      }
    }

    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {
      position = await Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
    }

    if (position == null) {
      if (mounted) {
        setState(() {
          _locationStatus = "Berlin, Germany (Simulated)";
          _selectedCountry = 'DE';
          _allStocks = Map.from(_regionalMarkets['DE']!);
        });
      }
      _fetchLivePrices();
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String rawCountryCode = place.isoCountryCode ?? 'US';
        String locationName = "${place.locality ?? ''}, ${place.country ?? ''}".trim();

        if (mounted) {
          setState(() {
            _locationStatus = locationName.isEmpty ? "Location detected" : locationName;
            if (_regionalMarkets.containsKey(rawCountryCode)) {
              _selectedCountry = rawCountryCode;
              _allStocks = Map.from(_regionalMarkets[rawCountryCode]!);
            }
          });
        }
        _fetchLivePrices();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationStatus = "Berlin, Germany";
          _selectedCountry = 'DE';
          _allStocks = Map.from(_regionalMarkets['DE']!);
        });
      }
      _fetchLivePrices();
    }
  }

  // Bug 1 Fix: Explicit error state handler and loading wrapper to intercept API rate limits
  Future<void> _fetchLivePrices() async {
    if (_allStocks.isEmpty) return;
    setState(() {
      _isRefreshing = true;
      _apiErrorMessage = null;
    });

    bool rateLimitedDetected = false;

    for (String symbol in _allStocks.keys) {
      try {
        final quote = await _finnhubService.fetchLiveQuote(symbol);
        // Standard Finnhub empty payload structural validation indicator
        if (quote.containsKey('c') && quote['c'] != 0 && quote['c'] != null) {
          if (mounted) {
            setState(() {
              _allStocks[symbol]!['price'] = double.parse(quote['c'].toString());
              _allStocks[symbol]!['dp'] = double.parse((quote['dp'] ?? 0.0).toString());
            });
          }
        } else {
          rateLimitedDetected = true;
        }
      } catch (e) {
        rateLimitedDetected = true;
      }
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        // Bug 2: Log exact timestamp formatting sequence safely
        _lastUpdatedTimestamp = DateFormat('hh:mm:ss a').format(DateTime.now());
        if (rateLimitedDetected) {
          _apiErrorMessage = "API standard tier request threshold reached. Showing last known snapshot data.";
        }
      });
    }
  }

  void _updateCountryMarketSelection(String countryCode) {
    setState(() {
      _selectedCountry = countryCode;
      _allStocks = Map.from(_regionalMarkets[countryCode]!);
    });
    _fetchLivePrices();
  }

  Future<void> _performDynamicSearch(String rawSymbol) async {
    final symbol = rawSymbol.trim().toUpperCase();
    if (symbol.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
    );

    try {
      final quote = await _finnhubService.fetchLiveQuote(symbol);
      final String token = "YOUR_FINNHUB_KEY_HERE";
      final today = DateTime.now().toString().substring(0, 10);
      final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toString().substring(0, 10);

      final newsUrl = Uri.parse("https://finnhub.io/api/v1/company-news?symbol=$symbol&from=$weekAgo&to=$today&token=$token");
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

        String displayName = _allStocks.containsKey(symbol) ? _allStocks[symbol]!['name'] : 'Global Security Asset';

        if (context.mounted) {
          Navigator.pushNamed(context, '/stock-detail', arguments: {
            'symbol': symbol,
            'name': displayName,
            'usdPrice': price,
            'change': '${isBullish ? "+" : ""}${percent.toStringAsFixed(2)}%',
            'isBullish': isBullish,
            'newsList': parsedNewsList
          }).then((_) => setState(() {}));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Ticker '$symbol' returned an empty profile signature from Finnhub.")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queryUpper = _searchQuery.toUpperCase().trim();
    final filteredSymbols = _allStocks.keys.where((sym) =>
    sym.contains(queryUpper) ||
        _allStocks[sym]!['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    final bool showDynamicOption = queryUpper.isNotEmpty && !_allStocks.containsKey(queryUpper);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Finora'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh, color: Color(0xFF14B8A6)),
            onPressed: _fetchLivePrices,
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW BLOCK
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome, Investor", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF38BDF8), size: 15),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(_locationStatus, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCountry,
                      dropdownColor: const Color(0xFF1E293B),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF14B8A6)),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      onChanged: (String? newCountry) {
                        if (newCountry != null) _updateCountryMarketSelection(newCountry);
                      },
                      items: _countryOptions.entries.map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value))).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bug 1 & 2 UI Safety Net Banner Section
          if (_lastUpdatedTimestamp != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.access_time_filled, size: 12, color: _apiErrorMessage != null ? const Color(0xFFEAB308) : const Color(0xFF14B8A6)),
                  const SizedBox(width: 6),
                  Text(
                    "Prices Snapshot Fetched: $_lastUpdatedTimestamp",
                    style: TextStyle(fontSize: 12, color: _apiErrorMessage != null ? const Color(0xFFEAB308) : const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          if (_apiErrorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF7F1D1D), borderRadius: BorderRadius.circular(8)),
              child: Text(_apiErrorMessage!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11, fontWeight: FontWeight.w500)),
            ),

          // SEARCH INPUT INTERFACE FIELD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => _searchQuery = val),
              textInputAction: TextInputAction.search,
              onSubmitted: (val) => _performDynamicSearch(val),
              decoration: InputDecoration(
                hintText: 'Search stock tickers or names...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF14B8A6)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text("Trending Tickers ($_selectedCountry)", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white60)),
          ),

          // Bug 4 Fix: Dynamic snapshot map configuration loop supporting empty lists safely
          Expanded(
            child: filteredSymbols.isEmpty && !showDynamicOption
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.layers_clear, size: 48, color: Color(0xFF475569)),
                    const SizedBox(height: 12),
                    const Text("No Active Price Assets Found", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("No asset metrics matching '$_searchQuery' found inside this country cluster.", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => setState(() => _searchQuery = ""),
                      icon: const Icon(Icons.restart_alt, size: 16, color: Color(0xFF14B8A6)),
                      label: const Text("Reset Search Query Filter", style: TextStyle(color: Color(0xFF14B8A6))),
                    )
                  ],
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredSymbols.length + (showDynamicOption ? 1 : 0),
              itemBuilder: (context, index) {
                if (showDynamicOption && index == filteredSymbols.length) {
                  final bool isSavedGlobal = WatchlistManager.selectedSymbols.contains(queryUpper);
                  return Card(
                    color: const Color(0xFF131D31),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF14B8A6), width: 1)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      onTap: () => _performDynamicSearch(queryUpper),
                      leading: const Icon(Icons.travel_explore, color: Color(0xFF38BDF8)),
                      title: Text("Search '$queryUpper' globally", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                      subtitle: const Text("Fetch live metrics & news from Finnhub", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isSavedGlobal ? Icons.star : Icons.star_border, color: const Color(0xFFEAB308)),
                            onPressed: () => setState(() => WatchlistManager.toggleWatchlist(queryUpper, context)),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Color(0xFF14B8A6), size: 14),
                        ],
                      ),
                    ),
                  );
                }

                final symbol = filteredSymbols[index];
                final stock = _allStocks[symbol]!;
                final double percent = stock['dp'] ?? 0.0;
                final double currentPrice = stock['price'] ?? 0.0;
                final bool isBullish = percent >= 0;
                final bool isSaved = WatchlistManager.selectedSymbols.contains(symbol);

                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    onTap: () => _performDynamicSearch(symbol), // Bug 4 Fix: Continuous clean dynamic downstream detail view routing loop
                    title: Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    subtitle: Text(stock['name'] ?? '', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currentPrice == 0.0 ? "Hold..." : FinoraApp.formatPrice(currentPrice), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('${isBullish ? "+" : ""}${percent.toStringAsFixed(2)}%', style: TextStyle(color: isBullish ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(isSaved ? Icons.star : Icons.star_border, color: const Color(0xFFEAB308)),
                          onPressed: () => setState(() => WatchlistManager.toggleWatchlist(symbol, context)),
                        )
                      ],
                    ),
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