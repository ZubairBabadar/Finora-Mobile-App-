import 'package:flutter/material.dart';
import '../services/finnhub_service.dart';

class StockLogo extends StatefulWidget {
  final String symbol;
  final double size;

  const StockLogo({
    super.key,
    required this.symbol,
    this.size = 64,
  });

  @override
  State<StockLogo> createState() => _StockLogoState();
}

class _StockLogoState extends State<StockLogo> {
  static final FinnhubService _finnhubService = FinnhubService();

  // Shared across every StockLogo instance in the app, so the same ticker
  // is only ever looked up once for the whole session instead of refetching
  // on every rebuild.
  static final Map<String, String?> _logoUrlCache = {};

  String? _logoUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveLogoUrl();
  }

  @override
  void didUpdateWidget(covariant StockLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _resolveLogoUrl();
    }
  }

  Future<void> _resolveLogoUrl() async {
    final String cleanSymbol = widget.symbol.trim().toUpperCase();

    if (_logoUrlCache.containsKey(cleanSymbol)) {
      setState(() {
        _logoUrl = _logoUrlCache[cleanSymbol];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    final String? resolvedUrl = await _finnhubService.fetchCompanyLogoUrl(cleanSymbol);
    _logoUrlCache[cleanSymbol] = resolvedUrl;

    if (mounted) {
      setState(() {
        _logoUrl = resolvedUrl;
        _loading = false;
      });
    }
  }

  Widget _buildFallback(String cleanSymbol) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        color: Color(0xFF22314F),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        cleanSymbol.padRight(1).substring(0, 1),
        style: const TextStyle(
          color: Color(0xFF38BDF8),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanSymbol = widget.symbol.trim().toUpperCase();

    if (_loading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
        ),
      );
    }

    if (_logoUrl == null) {
      return _buildFallback(cleanSymbol);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.size / 2),
      child: Image.network(
        _logoUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(cleanSymbol),
      ),
    );
  }
}