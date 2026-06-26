import 'dart:async';
import 'package:flutter/material.dart';
import '../services/otp_service.dart';

class OtpVerificationSheet extends StatefulWidget {
  final VoidCallback onVerificationSuccess;

  const OtpVerificationSheet({super.key, required this.onVerificationSuccess});

  @override
  State<OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<OtpVerificationSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _canResend = false;
  int _secondsRemaining = 30;
  Timer? _countdownTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 30;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _countdownTimer?.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  void _handleResend() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    bool contextSent = await OtpService.generateAndSendOtp();
    setState(() => _isLoading = false);

    if (contextSent) {
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A fresh security OTP has been dispatched to your email.')),
      );
    }
  }

  void _verifyCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = "Please input a valid 6-digit sequence token.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool matchSuccessful = await OtpService.verifyOtp(code);

    if (matchSuccessful) {
      if (mounted) {
        // FIXED: Only trigger Navigator.pop if this view is running inside a modal stack overlay
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        widget.onVerificationSuccess();
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Invalid code, expired window limits, or attempt lock out.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope prevents manual modal dismissals via swipe gestures or back clicks
    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identity Gateway Check',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'To finish setup and confirm account details, enter the 6-digit code sent to your email inbox.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: const Color(0xFF131D31),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22314F))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF14B8A6))),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(color: Color(0xFFEF4444))),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading ? null : _verifyCode,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Verify and Proceed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _canResend ? _handleResend : null,
                child: Text(
                  _canResend ? "Resend Verification Email" : "Resend available in ${_secondsRemaining}s",
                  style: TextStyle(
                    color: _canResend ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}