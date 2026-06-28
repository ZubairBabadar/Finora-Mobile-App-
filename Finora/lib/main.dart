import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'navigation_controller.dart';
import 'screens/detail_screen.dart';
import 'services/watchlist_manager.dart';
import 'portfolio_manager.dart';
import 'screens/account_screen.dart';
import 'widgets/otp_verification_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase using the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialize Google Sign-In with explicit Web Client ID parameters
  await GoogleSignIn.instance.initialize(
    serverClientId: '378713624345-c819eg5075ukmji816cg406mtn32dqn9.apps.googleusercontent.com',
  );

  runApp(const FinoraApp());
}

class FinoraApp extends StatelessWidget {
  const FinoraApp({super.key});

  // Converted to ValueNotifier to support real-time reactive UI updates across the navigation stack
  static final ValueNotifier<String> globalCurrency = ValueNotifier<String>("USD (\$)");
  static String globalCountryFilter = "United States";

  // FIXED: Added an optional 'isNativeEur' flag so that your Portfolio data doesn't get double-converted
  static String formatPrice(double basePrice, {bool isNativeEur = false}) {
    if (isNativeEur) {
      return '€${basePrice.toStringAsFixed(2)}';
    }

    double conversionRate = 1.0;
    String symbol = '\$';

    // Extracted current value from the notifier wrapper
    final String currentCurrencySelection = globalCurrency.value;

    if (currentCurrencySelection.contains('EUR')) {
      conversionRate = 0.92;
      symbol = '€';
    } else if (currentCurrencySelection.contains('GBP')) {
      conversionRate = 0.78;
      symbol = '£';
    }

    double finalPrice = basePrice * conversionRate;
    return '$symbol${finalPrice.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131D31),
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/home': (context) => const NavigationController(),
        '/stock-detail': (context) => const StockDetailScreen(),
      },
    );
  }
}

// The "Traffic Controller" for your app handling authentication and security layer routing
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // LAYER 1: If snapshot has no data, the user is completely signed out -> show gateway access
        if (!snapshot.hasData) {
          return const AccountScreen();
        }

        final user = snapshot.data!;

        // LAYER 2: Stream verification document status dynamically to handle persistent state locks
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('otp_verifications')
              .doc(user.uid)
              .snapshots(),
          builder: (context, otpSnapshot) {
            // Display loading blocker while retrieving server timestamps/status data
            if (otpSnapshot.hasError) {
              return const Scaffold(
                backgroundColor: Color(0xFF0B1220),
                body: Center(child: Text("Security check error. Please reload.")),
              );
            }

            if (!otpSnapshot.hasData || !otpSnapshot.data!.exists) {
              return const Scaffold(
                backgroundColor: Color(0xFF0B1220),
                body: Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6))),
              );
            }

            final otpData = otpSnapshot.data!.data() as Map<String, dynamic>?;
            final bool isVerified = otpData?['isVerified'] ?? false;

            // If user exists but security contract is unverified -> send them instantly to the verification panel layout
            if (!isVerified) {
              return Scaffold(
                backgroundColor: const Color(0xFF0B1220),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF0B1220),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                    onPressed: () async {
                      // Gracefully signs the unverified user out so they can modify inputs or change emails if typed wrong
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ),
                body: Center(
                  child: SingleChildScrollView(
                    child: OtpVerificationSheet(
                      onVerificationSuccess: () {
                        // Displays classic success message indicator toast pipeline upon confirmation match
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account successfully created and verified!',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            backgroundColor: Color(0xFF14B8A6),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }

            // LAYER 3: Only clear through to internal views once security token validation returns true
            WatchlistManager.initializeWatchlist();

            // FIXED: Explicitly force-sync the user's isolated portfolio state upon entering application views
            portfolioManager.loadUserDataFromCloud();

            return const NavigationController();
          },
        );
      },
    );
  }
}