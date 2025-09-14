import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'smtp_email_service.dart'; // 👈 import service gửi mail

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _isSending = false;

  Future<void> _handleSubmit() async {
    setState(() => _isSending = true);

    final success = await SmtpEmailService.sendContactEmail(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      message: _messageCtrl.text,
    );

    setState(() => _isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "✅ Message sent successfully!" : "❌ Failed to send message.",
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      _nameCtrl.clear();
      _emailCtrl.clear();
      _messageCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Iconsax.message5, size: 60, color: Colors.blueAccent),
          const SizedBox(height: 16),
          const Text(
            "Get in Touch",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 28),
          _buildInputField("Full Name", Iconsax.user, controller: _nameCtrl),
          const SizedBox(height: 20),
          _buildInputField("Email Address", Iconsax.sms, controller: _emailCtrl),
          const SizedBox(height: 20),
          _buildInputField("Message", Iconsax.message, controller: _messageCtrl, maxLines: 4),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _isSending ? null : _handleSubmit,
            icon: _isSending
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Iconsax.send_2, color: Colors.white),
            label: Text(
              _isSending ? "Sending..." : "Submit",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, IconData icon,
      {int maxLines = 1, TextEditingController? controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blueAccent),
            hintText: "Enter your $label",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
