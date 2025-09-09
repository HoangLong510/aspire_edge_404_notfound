// --- PHẦN 1: IMPORT CÁC THƯ VIỆN CẦN THIẾT ---
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- PHẦN 2: ĐỊNH NGHĨA WIDGET CỦA TRANG ĐĂNG NHẬP ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- PHẦN 3: KHAI BÁO CÁC BIẾN TRẠNG THÁI VÀ CONTROLLERS ---

  // GlobalKey để quản lý và validate Form
  final _formKey = GlobalKey<FormState>();

  // Controllers để quản lý text trong các ô nhập liệu
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Biến để quản lý trạng thái loading
  bool _isLoading = false;

  // --- PHẦN 4: LOGIC XỬ LÝ CHỨC NĂNG ĐĂNG NHẬP ---
  Future<void> _loginUser() async {
    // 1. Kiểm tra xem các trường nhập liệu có hợp lệ không
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Bật trạng thái loading để hiển thị vòng quay
    setState(() {
      _isLoading = true;
    });

    // 3. Sử dụng khối try-catch để xử lý lỗi từ Firebase
    try {
      // Gọi hàm đăng nhập của Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Nếu đăng nhập thành công, chuyển hướng đến trang chính
      // và xóa các trang cũ (login, register) khỏi stack
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } on FirebaseAuthException catch (e) {
      // 4. Bắt và xử lý các lỗi đăng nhập cụ thể
      String message = 'An error occurred. Please try again.';
      // Dựa vào mã lỗi (e.code) để đưa ra thông báo phù hợp
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-credential') {
        // Lỗi này chung cho cả sai email và sai mật khẩu ở các phiên bản SDK mới
        message = 'Invalid email or password.';
      }

      // Hiển thị thông báo lỗi cho người dùng
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 5. Luôn tắt trạng thái loading sau khi hoàn tất
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- PHẦN 5: DỌN DẸP TÀI NGUYÊN ---
  @override
  void dispose() {
    // Hủy các controller để tránh rò rỉ bộ nhớ
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- PHẦN 6: HÀM HELPER ĐỂ TẠO GIAO DIỆN (TÁI SỬ DỤNG TỪ TRANG ĐĂNG KÝ) ---
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.1),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
    );
  }

  // --- PHẦN 7: HÀM BUILD - DỰNG GIAO DIỆN NGƯỜI DÙNG ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const SizedBox(height: 50),
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue your journey.',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Trường nhập liệu Email
                TextFormField(
                  controller: _emailController,
                  decoration: _buildInputDecoration('E-mail', Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Trường nhập liệu Mật khẩu
                TextFormField(
                  controller: _passwordController,
                  decoration: _buildInputDecoration('Password', Icons.lock_outline),
                  obscureText: true, // Ẩn mật khẩu
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Nút Đăng nhập
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        child: const Text('Login',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                const SizedBox(height: 24),

                // Phần chuyển hướng sang trang Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: TextStyle(color: Colors.grey[700])),
                    TextButton(
                      onPressed: () {
                        // pushReplacementNamed thay thế trang hiện tại bằng trang mới
                        // để người dùng không thể back lại trang login từ trang register
                        Navigator.of(context).pushReplacementNamed('/register');
                      },
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
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
      ),
    );
  }
}