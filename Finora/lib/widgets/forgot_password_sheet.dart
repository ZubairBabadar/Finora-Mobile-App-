import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final rawEmail = _emailController.text.trim();
    final lowercaseEmail = rawEmail.toLowerCase();

    try {
      bool userExists = false;

      // 1. Try checking Firestore using the raw email string
      try {
        var userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: rawEmail)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          userExists = true;
        } else {
          // Try checking with lowercase version
          userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: lowercaseEmail)
              .limit(1)
              .get();
          if (userQuery.docs.isNotEmpty) userExists = true;
        }
      } catch (e) {
        // If there's any network or persistent rule block, we let it fall back directly to Auth
        debugPrint("Firestore lookup skipped or restricted: $e");
      }

      // 2. Strict condition check or direct execution fallback
      if (!userExists) {
        // Direct Fallback: Fire Auth request to see if Auth engine has the account
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: rawEmail);
          _showSuccessAndPop();
          return;
        } on FirebaseAuthException catch (authError) {
          if (authError.code == 'user-not-found') {
            if (mounted) {
              setState(() {
                _errorMessage = 'Account does not exist. Please check your email entry.';
                _isLoading = false;
              });
            }
            return;
          } else {
            // Rethrow other errors (like invalid-email) to handle below
            rethrow;
          }
        }
      }

      // 3. Normal path: If Firestore explicitly verified it, run reset normally
      await FirebaseAuth.instance.sendPasswordResetEmail(email: rawEmail);
      _showSuccessAndPop();

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'invalid-email') {
            _errorMessage = 'The email address format is invalid.';
          } else if (e.code == 'user-not-found') {
            _errorMessage = 'Account does not exist. Please check your email entry.';
          } else {
            _errorMessage = e.message ?? 'An error occurred. Please try again.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'An unexpected error occurred. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessAndPop() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent! Check your inbox and spam folder.'),
          backgroundColor: Color(0xFF14B8A6),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your registered email below. We will send you a secure link to reset your password.',
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: const TextStyle(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF131D31),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF14B8A6)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.w600
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'Send Reset Link',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}