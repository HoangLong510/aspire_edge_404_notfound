import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class SmtpEmailService {
  static const String _username = "team02aptech@gmail.com";
  static const String _password = "npytjpxmmkwizhts";

  /// Gửi email liên hệ từ người dùng
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

  /// Gửi email OTP để xác thực người dùng
  static Future<bool> sendOtpEmail({
    required String toEmail,
    required String otp,
  }) async {
    final smtpServer = gmail(_username, _password);

    final mail = Message()
      ..from = Address(_username, "AspireEdge Verification")
      ..recipients.add(toEmail)
      ..subject = "🔐 Your AspireEdge OTP Code"
      ..html = _otpTemplate(otp);

    try {
      await send(mail, smtpServer);
      return true;
    } catch (e) {
      print("OTP email failed: $e");
      return false;
    }
  }

  /// Gửi email trả lời từ admin tới người dùng
  static Future<bool> sendReplyEmail({
    required String toEmail,
    required String userName,
    required String replyMessage,
  }) async {
    final smtpServer = gmail(_username, _password);

    final mail = Message()
      ..from = Address(_username, "AspireEdge Admin")
      ..recipients.add(toEmail)
      ..subject = "📩 Reply to your message"
      ..html = _replyTemplate(userName, replyMessage);

    try {
      await send(mail, smtpServer);
      return true;
    } catch (e) {
      print("Reply email failed: $e");
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

  static String _otpTemplate(String otp) => """
  <div style="font-family: Arial, sans-serif; font-size: 16px; color: #333;">
    <div style="max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 8px; overflow: hidden;">
      <div style="background-color: #2196f3; padding: 20px; text-align: center; color: #fff;">
        <h1>AspireEdge</h1>
      </div>
      <div style="padding: 30px;">
        <h2 style="color: #2196f3;">Your OTP Code</h2>
        <p>Please use the following OTP to verify your email. This code will expire in 5 minutes:</p>
        <p style="font-size: 28px; font-weight: bold; text-align: center; letter-spacing: 4px;">$otp</p>
        <p style="margin-top: 20px;">If you did not request this, you can safely ignore this email.</p>
      </div>
      <div style="background-color: #f5f5f5; padding: 16px; text-align: center; color: #555;">
        <p>&copy; 2025 AspireEdge. All rights reserved.</p>
      </div>
    </div>
  </div>
  """;

  static String _replyTemplate(String userName, String replyMessage) => """
<div style="font-family: system-ui, sans-serif, Arial; font-size: 14px; color: #212121">
  <div style="max-width: 600px; margin: auto">
    <div style="text-align: center; background-color: #2196f3; padding: 40px 16px; border-radius: 32px 32px 0 0;">
      <img style="height: 140px; background-color: #ffffff; padding: 12px; border-radius: 12px;"
            src="https://res.cloudinary.com/daxpkqhmd/image/upload/v1757581315/image-Photoroom_vrxff8.png"
            alt="AspireEdge Logo"/>
    </div>
    <div style="padding: 28px">
      <h1 style="font-size: 24px; margin-bottom: 20px; color: #2196f3">📩 Aspire Edge Reply</h1>
      <p><strong>Dear $userName,</strong></p>
      <p>We have reviewed your message. Here is our response:</p>
      <p style="background: #f5f5f5; padding: 14px; border-radius: 8px">$replyMessage</p>
      <p style="margin-top: 28px; color: #555">
        Thank you for using <strong>AspireEdge</strong>.
        We truly appreciate your trust and feedback 💙
      </p>
    </div>
    <div style="text-align: center; background-color: #2196f3; padding: 20px; border-radius: 0 0 32px 32px; color: #fff;">
      <p>For more help, contact
        <a href="mailto:team02aptech@gmail.com" style="color: #fff; text-decoration: underline">team02aptech@gmail.com</a>
      </p>
    </div>
  </div>
</div>
""";
}