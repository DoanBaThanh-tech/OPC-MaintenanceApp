import 'package:flutter/material.dart';
// features/auth/presentation/auth_screens.dart
import '../../../core/network/api_exception.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_logic.dart';                      
import '../../dashboard/presentation/dashboard_screen.dart';

// ============ MÀN 1: ĐĂNG NHẬP ============

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _matKhauController = TextEditingController();
  bool _dangTai = false;
  bool _anMatKhau = true;
  String? _loi;

  Future<void> _xuLyDangNhap() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _dangTai = true; _loi = null; });
    try {
      await AuthService.dangNhap(_emailController.text.trim(), _matKhauController.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } catch (_) {
      setState(() => _loi = 'Không thể kết nối tới máy chủ.');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  Widget _buildForm(double maxWidth) {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Đăng nhập', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Nhập email nội bộ và mật khẩu được Admin cấp',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email nội bộ', prefixIcon: Icon(Icons.email_outlined)),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _matKhauController,
              obscureText: _anMatKhau,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_anMatKhau ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
                ),
              ),
              validator: AuthValidators.matKhauDangNhap,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            if (_loi != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(_loi!, style: const TextStyle(color: AppColors.danger)),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _dangTai ? null : _xuLyDangNhap,
                child: _dangTai
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Đăng nhập'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandPanel() {
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle, size: 72, color: Colors.white),
          SizedBox(height: 12),
          Text('HỆ THỐNG QUẢN LÝ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text('Bảo trì · Sửa chữa cơ điện', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _matKhauController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive(
        builder: (context, info) {
          if (info.isMobile) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(child: _buildForm(double.infinity)),
              ),
            );
          }
          return Row(
            children: [
              Expanded(flex: 4, child: _brandPanel()),
              Expanded(
                flex: 6,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: _buildForm(420),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============ MÀN 2: NHẬP EMAIL QUÊN MẬT KHẨU ============

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _dangTai = false;
  String? _loi;

  Future<void> _guiOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _dangTai = true; _loi = null; });
    try {
      final email = _emailController.text.trim();
      await AuthService.quenMatKhau(email);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(email: email)));
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khôi phục mật khẩu')),
      body: Responsive(
        builder: (context, info) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: info.isMobile ? double.infinity : 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mail_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text('Nhập email nội bộ đã đăng ký. Mã xác thực sẽ gửi qua hệ thống mail công ty.'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email nội bộ'),
                      validator: AuthValidators.email,
                    ),
                    if (_loi != null) ...[
                      const SizedBox(height: 8),
                      Text(_loi!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _dangTai ? null : _guiOtp,
                      child: _dangTai
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Gửi mã xác thực'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ MÀN 3: NHẬP OTP ============

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _dangTai = false;
  String? _loi;

  Future<void> _xacNhan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _dangTai = true; _loi = null; });
    try {
      await AuthService.xacNhanOtp(widget.email, _otpController.text.trim());
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: widget.email)));
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực OTP')),
      body: Responsive(
        builder: (context, info) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: info.isMobile ? double.infinity : 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mã xác thực đã gửi tới\n${widget.email}', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      decoration: const InputDecoration(counterText: ''),
                      validator: AuthValidators.otp,
                    ),
                    if (_loi != null) ...[
                      const SizedBox(height: 8),
                      Text(_loi!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _dangTai ? null : _xacNhan,
                      child: _dangTai
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Xác nhận'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ MÀN 4: ĐẶT MẬT KHẨU MỚI ============

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matKhauController = TextEditingController();
  final _xacNhanController = TextEditingController();
  bool _dangTai = false;
  String? _loi;

  Future<void> _datLai() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _dangTai = true; _loi = null; });
    try {
      await AuthService.datLaiMatKhau(widget.email, _matKhauController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công. Vui lòng đăng nhập lại.')),
      );
      Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mật khẩu mới')),
      body: Responsive(
        builder: (context, info) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: info.isMobile ? double.infinity : 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _matKhauController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                      validator: AuthValidators.matKhauMoi,
                    ),
                    const SizedBox(height: 4),
                    const Text('Tối thiểu 8 ký tự, có 1 chữ hoa và 1 ký tự đặc biệt',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _xacNhanController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                      validator: (v) => AuthValidators.xacNhanMatKhau(v, _matKhauController.text),
                    ),
                    if (_loi != null) ...[
                      const SizedBox(height: 8),
                      Text(_loi!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _dangTai ? null : _datLai,
                      child: _dangTai
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Xác nhận'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}