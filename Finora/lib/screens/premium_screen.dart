import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED for Logout
import '../widgets/app_logo.dart';
import '../main.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _pushNotifications = true;
  bool _biometricLock = false;
  String _selectedTierPlan = "Monthly Strategy";
  bool _isDeleting = false; // Flag to gate UI interactions during deletion

  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131D31),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                  'Select Active Currency Format',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ),
            ListTile(
                title: const Text('USD - United States Dollar', style: TextStyle(color: Colors.white)),
                onTap: () {
                  FinoraApp.globalCurrency.value = "USD (\$)";
                  Navigator.pop(context);
                }
            ),
            ListTile(
                title: const Text('EUR - Euro Region', style: TextStyle(color: Colors.white)),
                onTap: () {
                  FinoraApp.globalCurrency.value = "EUR (€)";
                  Navigator.pop(context);
                }
            ),
            ListTile(
                title: const Text('GBP - Great British Pound', style: TextStyle(color: Colors.white)),
                onTap: () {
                  FinoraApp.globalCurrency.value = "GBP (£)";
                  Navigator.pop(context);
                }
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _triggerSyncToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API Sync Triggered: Fetching data from MarketStack caches...'),
        backgroundColor: Color(0xFF14B8A6),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _simulatePurchase(BuildContext modalContext) {
    Navigator.pop(modalContext);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checkout Intent Captured: Initiating localized pipeline for $_selectedTierPlan...'),
        backgroundColor: const Color(0xFF2563EB),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSubscriptionPlans() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0B1220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF22314F))),
          title: const Text(
            'Select Pro Access Strategy',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPlanTile(setModalState, 'Weekly Ticket', 2.99, 'Basic real-time technical alerts access'),
                _buildPlanTile(setModalState, 'Monthly Strategy', 9.99, 'Full indicators access + Reverse Geolocation API'),
                _buildPlanTile(setModalState, 'Annual Matrix', 79.99, 'Save 35% + Deep historical analytics parameters', isPopular: true),

                const SizedBox(height: 20),
                const Divider(color: Color(0xFF22314F), height: 1),
                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _simulatePurchase(context),
                  child: Text(
                    'Purchase Plan Selection',
                    style: TextStyle(
                        color: Colors.black.withValues(alpha:0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 14
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Color(0xFF64748B)))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTile(StateSetter setModalState, String title, double baseUsdCost, String feature, {bool isPopular = false}) {
    bool isSelected = _selectedTierPlan == title;
    return GestureDetector(
      onTap: () {
        setModalState(() { _selectedTierPlan = title; });
        if (mounted) setState(() { _selectedTierPlan = title; });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? const Color(0xFF14B8A6) : (isPopular ? const Color(0xFF22314F).withValues(alpha:0.5) : const Color(0xFF22314F)),
              width: isSelected ? 2.0 : 1.0
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                    FinoraApp.formatPrice(baseUsdCost),
                    style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 13)
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(feature, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // --- TYPE TO CONFIRM ACCOUNT DELETION SYSTEM ---
  void _showDeleteAccountConfirmation() {
    final TextEditingController confirmController = TextEditingController();
    bool isConfirmEnabled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF131D31),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF22314F)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
                  SizedBox(width: 10),
                  Text("Confirm Account Deletion", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "This action is permanent and completely irreversible. Your profile data and access settings will be completely purged.",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Type 'DELETE' to confirm authorization:",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    cursorColor: const Color(0xFF14B8A6),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFF0B1220),
                      hintText: "DELETE",
                      hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF22314F)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                      ),
                    ),
                    onChanged: (val) {
                      setStateDialog(() {
                        isConfirmEnabled = val.trim() == "DELETE";
                      });
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Future.delayed(const Duration(milliseconds: 300), () => confirmController.dispose());
                  },
                  child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConfirmEnabled ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: isConfirmEnabled
                      ? () {
                    Navigator.of(dialogContext).pop();
                    // Keeps controller valid for the length of the slide/fade routing animation frame
                    Future.delayed(const Duration(milliseconds: 300), () => confirmController.dispose());
                    _executeAccountPurge();
                  }
                      : null,
                  child: const Text("Delete Forever", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- SAFE ASYNC FIREBASE PURGE EXECUTION ---
  Future<void> _executeAccountPurge() async {
    if (!mounted) return;
    setState(() => _isDeleting = true);

    // Snapshot Messenger parameters prior to any asynchronous context dropping
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }

      // STOP: If the user stream dropped and AuthGate popped this widget, exit cleanly.
      if (!mounted) return;

    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);

      String errorMessage = e.toString();
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        errorMessage = "Security Gate: Please log out and sign back in to re-authenticate before attempting account erasure.";
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const AppLogoTitle(title: 'Hub & Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.workspace_premium, color: Color(0xFFEAB308), size: 28),
                          SizedBox(width: 8),
                          Text('Premium Strategy Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                            _selectedTierPlan,
                            style: const TextStyle(color: Color(0xFF14B8A6), fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Explore advanced market tools, geolocation trackers, and dynamic real-time baseline analytics filters.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1220),
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    onPressed: _showSubscriptionPlans,
                    child: const Text('Subscription Plans', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Application Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC))),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF131D31),
              shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF22314F)), borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.notifications,
                    title: 'Push Notifications',
                    subtitle: 'Configure real-time stock alert thresholds',
                    trailing: Switch(
                        value: _pushNotifications,
                        onChanged: _isDeleting ? null : (val) => setState(() => _pushNotifications = val),
                        activeThumbColor: const Color(0xFF14B8A6)
                    ),
                  ),
                  const Divider(color: Color(0xFF22314F), height: 1),
                  _buildSettingsTile(
                    icon: Icons.security,
                    title: 'Biometric Security',
                    subtitle: 'Manage face/fingerprint credentials verification',
                    trailing: Switch(
                        value: _biometricLock,
                        onChanged: _isDeleting ? null : (val) => setState(() => _biometricLock = val),
                        activeThumbColor: const Color(0xFF14B8A6)
                    ),
                  ),
                  const Divider(color: Color(0xFF22314F), height: 1),
                  _buildSettingsTile(
                    icon: Icons.currency_exchange,
                    title: 'Base Display Currency',
                    subtitle: 'Alter app baseline structural pricing valuations',
                    trailing: InkWell(
                        onTap: _isDeleting ? null : _showCurrencySelector,
                        child: Text(FinoraApp.globalCurrency.value, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold))
                    ),
                  ),
                  const Divider(color: Color(0xFF22314F), height: 1),
                  _buildSettingsTile(
                    icon: Icons.refresh,
                    title: 'Force API Refresh',
                    subtitle: 'Clear cached JSON states from endpoint right now',
                    trailing: IconButton(icon: const Icon(Icons.sync, color: Color(0xFF14B8A6)), onPressed: _isDeleting ? null : _triggerSyncToast),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECURE LOGOUT ACTION
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1220),
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              label: const Text('Log Out from Finora', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: _isDeleting ? null : () async {
                await FirebaseAuth.instance.signOut();
              },
            ),

            const SizedBox(height: 12),

            // DANGER ZONE DELETION TRIGGER BUTTON
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3), width: 1.2),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              icon: _isDeleting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFEF4444), strokeWidth: 2))
                  : const Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
              label: Text(
                _isDeleting ? 'Processing Account Purge...' : 'Delete Secure Account',
                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: _isDeleting ? null : _showDeleteAccountConfirmation,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required String subtitle, required Widget trailing}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF38BDF8)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC), fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      trailing: trailing,
    );
  }
}