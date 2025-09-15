import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aspire_edge_404_notfound/utils/smtp_email_service.dart';
import 'package:aspire_edge_404_notfound/widgets/otp_code_input.dart';

class OtpVerificationPage extends StatefulWidget {
  final Map<String, dynamic> tempData;
  const OtpVerificationPage({super.key, required this.tempData});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  int _secondsRemaining = 60;
  Timer? _timer;
  late String _otp;
  late DateTime _expiryTime;
  String _enteredOtp = "";
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _otp = widget.tempData['otp'];
    _expiryTime = DateTime.parse(widget.tempData['otpExpiry']);
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() => _isVerifying = true);
    if (_enteredOtp == _otp && DateTime.now().isBefore(_expiryTime)) {
      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: widget.tempData['E-mail'],
              password: widget.tempData['Password'],
            );
        final uid = userCredential.user!.uid;

        final dataToSave = Map<String, dynamic>.from(widget.tempData);
        dataToSave.remove('otp');
        dataToSave.remove('otpExpiry');
        dataToSave.remove('Password');
        dataToSave['User_Id'] = uid;
        dataToSave['isVerified'] = true;

        await FirebaseFirestore.instance
            .collection("Users")
            .doc(uid)
            .set(dataToSave);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful! Please log in."),
              backgroundColor: Colors.green,
            ),
          );
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Auth error: ${e.message}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid or expired OTP"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isVerifying = false);
  }

  Future<void> _resendOtp() async {
    final otp = (Random().nextInt(900000) + 100000).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 1));
    setState(() {
      _otp = otp;
      _expiryTime = expiry;
      _secondsRemaining = 60;
    });
    await SmtpEmailService.sendOtpEmail(
      toEmail: widget.tempData['E-mail'],
      otp: otp,
    );
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onOtpCompleted(String code) {
    _enteredOtp = code;
    _verifyOtp();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsRemaining ~/ 60).toString();
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, "0");
    final isExpired = _secondsRemaining == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Verify Your Email",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "We sent a 6-digit code to\n${widget.tempData['E-mail']}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 30),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    OtpCodeInput(
                      length: 6,
                      onCompleted: _onOtpCompleted,
                      disabled: _isVerifying,
                    ),
                    if (_isVerifying)
                      const Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isExpired ? Icons.error_outline : Icons.access_time,
                        color: isExpired ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isExpired
                            ? "OTP has expired"
                            : "Your OTP is valid for $minutes:$seconds",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isExpired ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (isExpired)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _resendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "Resend OTP",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
