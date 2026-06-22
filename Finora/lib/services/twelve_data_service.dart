import 'dart:convert';
import 'package:http/http.dart' as http;

class FinnhubService {
  static const String _baseUrl = "https://finnhub.io/api/v1";
  static const String _apiKey = "d8qhif1r01qr03nj4shgd8qhif1r01qr03nj4si0";

  /// Pulls a real-time price quote snapshot from Finnhub
  Future<Map<String, dynamic>> fetchLiveQuote(String symbol) async {
    final Uri url = Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("Finnhub Quote retrieval exception: $e");
    }
    return {};
  }

  /// Pulls historical closing prices for your charts from Finnhub
  Future<List<double>> fetchChartCoordinates(String symbol) async {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int oneDayAgo = now - (24 * 60 * 60);

    final Uri url = Uri.parse(
        '$_baseUrl/stock/candle?symbol=$symbol&resolution=30&from=$oneDayAgo&to=$now&token=$_apiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['s'] == 'ok' && data.containsKey('c')) {
          List<dynamic> closes = data['c'];
          return closes.map<double>((val) => double.parse(val.toString())).toList();
        }
      }
    } catch (e) {
      print("Finnhub chart dataset parsing error: $e");
    }
    return [150.0, 155.2, 153.4, 158.9, 162.1, 160.5, 165.8]; // Safe UI fallback
  }
}