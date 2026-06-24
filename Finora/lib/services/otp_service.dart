import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart'; // REQUIRED: Provides the structural SmtpServer class definition

class OtpService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generates a secure random OTP token, saves verification bounds to Firestore,
  /// and dispatches the email payload directly via your Brevo SMTP tunnel.
  static Future<bool> generateAndSendOtp() async {
    final User? user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    // 1. Generate secure random 6-digit token context string
    final random = Random.secure();
    final String otpCode = (100000 + random.nextInt(900000)).toString();

    final DateTime now = DateTime.now();
    final DateTime expiresAt = now.add(const Duration(minutes: 5));

    try {
      // 2. Clear previous session checks and set the new verification document
      await _firestore.collection('otp_verifications').doc(user.uid).set({
        'email': user.email,
        'otpCode': otpCode,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
        'isVerified': false,
      });

      // 3. Configure direct outbound SMTP relay channel to Brevo
      // ⚠️ REPLACE 'YOUR_ACTUAL_BREVO_PASSWORD_HERE' WITH YOUR BREVO MASTER SMTP KEY
      final smtpServer = SmtpServer(
        'smtp-relay.brevo.com',
        username: 'afe0cf001@smtp-brevo.com',
        password: 'xsmtpsib-5be0329933bdd702fb7d40fc188cf44b67bb04a555fdabd74ea1efe019853aa2-v9CJl1XuxGZfbaeR',
        port: 587,
      );

      // 4. Construct the formal HTML confirmation message layout package
      final message = Message()
        ..from = const Address('zubairnoob27@gmail.com', 'Finora App')
        ..recipients.add(user.email!)
        ..subject = 'Welcome to Finora - Confirm Your Account'
        ..html = '''
          <div style="font-family: sans-serif; padding: 20px; background-color: #0F172A; color: #F8FAFC; max-width: 500px; border-radius: 8px;">
            <h3 style="color: #F8FAFC; font-size: 20px; margin-bottom: 8px;">Welcome to Finora!</h3>
            <p style="color: #CBD5E1; font-size: 14px; line-height: 1.5;">Your account registration was successful.</p>
            <p style="color: #CBD5E1; font-size: 14px; line-height: 1.5;">Please enter the following One-Time Password (OTP) inside the application panel to authorize your device session:</p>
            <div style="text-align: center; margin: 24px 0;">
              <h2 style="color: #14B8A6; letter-spacing: 6px; font-size: 36px; font-weight: bold; margin: 0; background-color: #131D31; padding: 12px; border-radius: 6px; display: inline-block;">$otpCode</h2>
            </div>
            <p style="color: #64748B; font-size: 12px; font-style: italic;">This security verification identity contract window expires in 5 minutes.</p>
          </div>
        ''';

      // 5. Fire transmission out-of-band directly across the web
      await send(message, smtpServer);
      debugPrint("🚀 OTP Email sent successfully through Brevo direct transmission!");
      return true;

    } catch (e) {
      debugPrint("Direct SMTP Transport Error: $e");
      return false;
    }
  }

  /// Validates the code input parameter submitted by the user layout entry view
  static Future<bool> verifyOtp(String userSubmittedCode) async {
    final User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      final docRef = _firestore.collection('otp_verifications').doc(user.uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) return false;

      final data = snapshot.data()!;
      final String correctCode = data['otpCode'] ?? '';
      final Timestamp expiresAt = data['expiresAt'];
      final int attempts = data['attempts'] ?? 0;

      // Restrict access instantly if document timestamps exceed limits or retry ceiling hit
      if (DateTime.now().isAfter(expiresAt.toDate()) || attempts >= 3) {
        return false;
      }

      if (userSubmittedCode == correctCode) {
        // Clear identity gate tracking checks
        await docRef.update({'isVerified': true});
        return true;
      } else {
        // Track malicious brute force variants via retry counter increments
        await docRef.update({'attempts': attempts + 1});
        return false;
      }
    } catch (e) {
      debugPrint("Verification transaction failed: $e");
      return false;
    }
  }
}