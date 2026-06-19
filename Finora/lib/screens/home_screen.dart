import 'package:flutter/material.dart';
import '../main.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  String _locationBadgeText = "Searching GPS...";

  @override
  void initState() {
    super.initState();
    _fetchGeolocatorData();
  }

  void _fetchGeolocatorData() async {
    String location = await _locationService.getCountryFromCoordinates();
    if (mounted) {
      setState(() { _locationBadgeText = location; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Finora'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10.0, bottom: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF1A2740), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF38BDF8), size: 14),
                  const SizedBox(width: 4),
                  Text(_locationBadgeText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1))),
                ],
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. VISUAL PORTFOLIO VALUE MATRICES COMPONENT
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131D31),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF22314F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ESTIMATED NET PORTFOLIO VALUE', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(FinoraApp.formatPrice(14250.00), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Color(0xFF22C55E), size: 16),
                    SizedBox(width: 4),
                    Text('+4.23% Session Index Profit', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. HORIZONTAL MARKET SECTOR BADGES CATEGORIES
          const Text('Market Sectors', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildSectorPill('💻 Technology Services'),
                _buildSectorPill('⚡ Energy Infrastructure'),
                _buildSectorPill('🚗 Automotive & EV'),
                _buildSectorPill('🏦 Banking Systems'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 3. PROMOTIONAL INSIGHT CARD
          const Text('Strategic Observations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            color: const Color(0xFF1A2740),
            child: const ListTile(
              leading: Icon(Icons.insights, color: Color(0xFF14B8A6)),
              title: Text('Automated Rebalancing Engine Active', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text('Your portfolio allocation metrics are locked and running perfectly matching target evaluation boundaries.', style: TextStyle(fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectorPill(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF1A2740), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF22314F))),
      child: Center(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)))),
    );
  }
}