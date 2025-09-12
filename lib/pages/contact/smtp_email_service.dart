import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class SmtpEmailService {
  static const String _username = "team02aptech@gmail.com";
  static const String _password = "npytjpxmmkwizhts";      

  static Future<bool> sendContactEmail({
    required String name,
    required String email,
    required String message,
  }) async {
    final smtpServer = gmail(_username, _password);

    final mail = Message()
      ..from = Address(_username, "AspireEdge Contact")
      ..recipients.add(_username)
      ..subject = "📩 New Contact Message from $name"
      ..html = _contactTemplate(name, email, message);

    try {
      await send(mail, smtpServer);
      return true;
    } catch (e) {
      print("Contact email failed: $e");
      return false;
    }
  }

  static String _contactTemplate(String name, String email, String message) => """
<div style="font-family: system-ui, sans-serif, Arial; font-size: 14px; color: #212121">
  <div style="max-width: 600px; margin: auto">
    <div style="text-align: center; background-color: #2196f3; padding: 40px 16px; border-radius: 32px 32px 0 0;">
      <img style="height: 140px; background-color: #ffffff; padding: 12px; border-radius: 12px;" 
           src="https://res.cloudinary.com/daxpkqhmd/image/upload/v1757581315/image-Photoroom_vrxff8.png" 
           alt="AspireEdge Logo"/>
    </div>
    <div style="padding: 28px">
      <h1 style="font-size: 24px; margin-bottom: 20px; color: #2196f3">📩 New Contact Message</h1>
      <p><strong>Name:</strong> $name</p>
      <p><strong>Email:</strong> $email</p>
      <p><strong>Message:</strong></p>
      <p style="background: #f5f5f5; padding: 14px; border-radius: 8px">$message</p>
      <p style="margin-top: 28px; color: #555">This message was sent via <strong>AspireEdge Contact Form</strong>.</p>
    </div>
    <div style="text-align: center; background-color: #2196f3; padding: 20px; border-radius: 0 0 32px 32px; color: #fff;">
      <p>For support, contact <a href="mailto:team02aptech@gmail.com" style="color: #fff; text-decoration: underline">team02aptech@gmail.com</a></p>
    </div>
  </div>
</div>
""";
}
