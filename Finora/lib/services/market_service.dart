import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketService {
  final String _apiKey = 'YOUR_API_KEY_HERE';
  final String _baseUrl = 'https://api.marketstack.com/v1/';

  Future<Map<String, dynamic>> fetchLiveTickerData(String symbol) async {
    final url = Uri.parse('${_baseUrl}tickers/$symbol/eod/latest?access_key=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed response status code ${response.statusCode}'};
    } catch (e) {
      return {'error': 'Network timeout or request failure Exception: $e'};
    }
  }
}