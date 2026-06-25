import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import '../widgets/app_logo.dart';
import '../services/otp_service.dart'; // REQUIRED: For validation checks
import '../widgets/otp_verification_sheet.dart'; // REQUIRED: Persistent verification UI modal
import '../widgets/forgot_password_sheet.dart'; // ADDED: Recovery modal sheet connection

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isSigningUp = false;
  bool _isCheckingAvailability = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  /// Displays the persistent, non-dismissible OTP verification gateway modal
  void _showOtpVerificationGateway() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Prevents dismiss by tapping screen background
      enableDrag: false,    // Prevents dismiss by dragging down
      backgroundColor: const Color(0xFF0F172A),
      builder: (context) => OtpVerificationSheet(
        onVerificationSuccess: () {
          Navigator.pushReplacementNamed(context, '/home');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: AppLogoTitle(title: _isSigningUp ? 'Finora Registration' : 'Finora Access Gateway'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isSigningUp ? 'Create Your Account' : 'Welcome to Finora',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFF8FAFC)),
              ),
              const SizedBox(height: 8),
              Text(
                _isSigningUp
                    ? 'Join to track localized stock markets and manage your portfolio.'
                    : 'Sign in to access real-time localized stock metrics.',
                style: const TextStyle(color: Color(0xFFCBD5E1)),
              ),
              const SizedBox(height: 32),

              if (_isSigningUp) ...[
                TextField(
                  controller: _usernameController,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Unique Username',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF14B8A6), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF131D31),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF22314F)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'User ID / Email Address',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF14B8A6), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF131D31),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF22314F)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF14B8A6), size: 18),
                  filled: true,
                  fillColor: const Color(0xFF131D31),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF22314F)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                  ),
                ),
              ),

              // ADDED: Forgot Password element (Only visible when signing in)
              if (!_isSigningUp) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const ForgotPasswordSheet(),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              if (_isSigningUp) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF14B8A6), size: 18),
                    filled: true,
                    fillColor: const Color(0xFF131D31),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF22314F)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF14B8A6)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isCheckingAvailability ? null : _handleAuthenticationForm,
                child: _isCheckingAvailability
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                  _isSigningUp ? 'Register & Enter' : 'Access Dashboard',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                  height: 18,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: Colors.white),
                ),
                label: const Text('Continue with Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  side: const BorderSide(color: Color(0xFF22314F)),
                  backgroundColor: const Color(0xFF131D31),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isCheckingAvailability ? null : _handleGoogleSignInPipeline,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isSigningUp ? 'Already have an account? ' : 'New to Finora? ', style: const TextStyle(color: Color(0xFF94A3B8))),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSigningUp = !_isSigningUp;
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                        _usernameController.clear();
                      });
                    },
                    child: Text(
                      _isSigningUp ? 'Sign In' : 'Sign Up Here',
                      style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Pure clean, compiler-safe modern authentication pipeline
  Future<void> _handleGoogleSignInPipeline() async {
    setState(() => _isCheckingAvailability = true);

    try {
      final googleSignIn = GoogleSignIn.instance;
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      final List<String> targetScopes = ['email', 'profile'];
      final GoogleSignInClientAuthorization clientAuthorization = await googleUser.authorizationClient.authorizeScopes(targetScopes);
      final String accessToken = clientAuthorization.accessToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCred.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          String baseSuggestion = googleUser.email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          if (baseSuggestion.length < 3) baseSuggestion = "user";

          String absoluteUniqueUsername = baseSuggestion.toLowerCase();
          bool choicePending = true;

          while (choicePending) {
            final check = await FirebaseFirestore.instance.collection('usernames').doc(absoluteUniqueUsername).get();
            if (!check.exists) {
              choicePending = false;
            } else {
              absoluteUniqueUsername = "$baseSuggestion${Random().nextInt(900) + 100}".toLowerCase();
            }
          }

          WriteBatch batch = FirebaseFirestore.instance.batch();
          batch.set(FirebaseFirestore.instance.collection('users').doc(user.uid), {
            'username': absoluteUniqueUsername,
            'email': googleUser.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
          batch.set(FirebaseFirestore.instance.collection('usernames').doc(absoluteUniqueUsername), {'uid': user.uid});

          await batch.commit();
        }

        // Trigger OTP Delivery Pipeline upon Google authentication mapping step
        bool otpSent = await OtpService.generateAndSendOtp();
        if (otpSent && mounted) {
          _showOtpVerificationGateway();
        }
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint("User voluntarily canceled login workflows.");
      } else {
        _showSnackbarError("Google Core Exception: ${e.code.name}");
      }
    } catch (e) {
      _showSnackbarError("Google authentication routing error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isCheckingAvailability = false);
    }
  }

  // Manual authentication registration logic handling mapping
  Future<void> _handleAuthenticationForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim().toLowerCase();

    if (email.isEmpty || password.isEmpty || (_isSigningUp && username.isEmpty)) {
      _showSnackbarError('Error: Fields cannot be left empty. Please supply valid parameters.');
      return;
    }

    if (_isSigningUp && username.length < 3) {
      _showSnackbarError('Username must be at least 3 characters long.');
      return;
    }

    setState(() => _isCheckingAvailability = true);

    try {
      if (_isSigningUp) {
        if (password != _confirmPasswordController.text.trim()) {
          _showSnackbarError('Error: Passwords do not match!');
          setState(() => _isCheckingAvailability = false);
          return;
        }

        final usernameDocRef = FirebaseFirestore.instance.collection('usernames').doc(username);
        final bool isTaken = await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(usernameDocRef);
          return snapshot.exists;
        });

        if (isTaken) {
          _showSnackbarError('The username "$username" is already taken. Please try another variant.');
          setState(() => _isCheckingAvailability = false);
          return;
        }

        UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final String uid = credential.user!.uid;

        WriteBatch batch = FirebaseFirestore.instance.batch();
        batch.set(FirebaseFirestore.instance.collection('users').doc(uid), {
          'username': _usernameController.text.trim(),
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.set(usernameDocRef, {'uid': uid});

        await batch.commit();

        // Trigger OTP Delivery Pipeline automatically after successful registration document commits
        bool otpSent = await OtpService.generateAndSendOtp();
        if (otpSent && mounted) {
          _showOtpVerificationGateway();
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

        // Also challenge existing returning standard login sessions with a fresh token gateway verify step
        bool otpSent = await OtpService.generateAndSendOtp();
        if (otpSent && mounted) {
          _showOtpVerificationGateway();
        }
      }
    } on FirebaseAuthException catch (e) {
      String userFeedbackMessage = e.message ?? "An authentication error occurred.";
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        userFeedbackMessage = "Account credentials mismatch. Please try again or create an account.";
      } else if (e.code == 'wrong-password') {
        userFeedbackMessage = "Incorrect password credentials supplied.";
      } else if (e.code == 'email-already-in-use') {
        userFeedbackMessage = "An account already exists for that email configuration.";
      }
      _showSnackbarError(userFeedbackMessage);
    } catch (e) {
      _showSnackbarError("Registration failed completely: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isCheckingAvailability = false);
    }
  }

  void _showSnackbarError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444), duration: const Duration(seconds: 4)),
    );
  }
}