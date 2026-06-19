import 'package:flutter/material.dart';
import '../main.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Flag to manage whether the screen displays sign-in or sign-up fields
  bool _isSigningUp = false;

  // Controllers to grab user inputs easily for database integration later
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

              // Email Text Input Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'User ID / Email Address',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFF131D31), // Midnight Blue
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF22314F)), // Slate Blue Border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF14B8A6)), // Turquoise Brand Color
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Text Input Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
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

              // Conditional dynamic structural field block rendering only when inside Sign Up state
              if (_isSigningUp) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
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

              // Primary Submit Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6), // Brand Turquoise
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Direct clean layout replace to switch users permanently into dashboard setup view context
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Text(
                    _isSigningUp ? 'Register & Enter' : 'Access Dashboard',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Text Row to switch views seamlessly
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSigningUp ? 'Already have an account? ' : 'New to Finora? ',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSigningUp = !_isSigningUp;
                      });
                    },
                    child: Text(
                      _isSigningUp ? 'Sign In' : 'Sign Up Here',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8), // Electric Cyan
                        fontWeight: FontWeight.bold,
                      ),
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
}