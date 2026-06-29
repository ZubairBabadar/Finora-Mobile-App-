import 'package:flutter/material.dart';

class StockLogo extends StatelessWidget {
  final String symbol;
  final double size;

  const StockLogo({
    super.key,
    required this.symbol,
    this.size = 64, // Matches LogoKit's standard base pixel block size
    // Removed websiteUrl since LogoKit's ticker endpoint handles everything
    String? websiteUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Your verified active publishable credential token
    const String apiToken = "pk_fr8b71f33c4e1b068c6486";

    // Clean, sanitized symbol string matching LogoKit's spec rules
    final String cleanSymbol = symbol.trim().toUpperCase();

    // Built exactly to the API Documentation specification specs:
    // https://img.logokit.com/ticker/{symbol}?token={token}&size=64&fallback=monogram
    final String targetLogoUrl =
        "https://img.logokit.com/ticker/$cleanSymbol?token=$apiToken&size=64&fallback=monogram";

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        targetLogoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback UI container widget if network framework drops entirely
          return Container(
            width: size,
            height: size,
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
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6)),
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }
}