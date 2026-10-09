import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _matKhauController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _dangTai = false;
  bool _anMatKhau = true;
  String? _loi;

  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;

  static const _blue = Color(0xFF0068A9);
  static const _slate = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _fadeIn = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _enterCtrl.forward();
  }

  Future<void> _xuLyDangNhap() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      await AuthService.dangNhap(
        _emailController.text.trim(),
        _matKhauController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } catch (_) {
      setState(() => _loi = 'Không thể kết nối tới máy chủ.');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  InputDecoration _fieldDeco({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 22, color: _muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  Widget _buildForm({required double maxWidth, required bool compact}) {
    final titleSize = compact ? 24.0 : 26.0;
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideIn,
        child: Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  Center(
                    child: Container(
                      width: 148,
                      height: 72,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo_opc.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.local_pharmacy_rounded,
                          color: _blue,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color: _slate,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sử dụng email nội bộ do Admin cấp',
                  style: TextStyle(
                    color: _muted,
                    fontSize: compact ? 13.5 : 14,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: compact ? 28 : 32),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _passFocus.requestFocus(),
                  decoration: _fieldDeco(
                    label: 'Email nội bộ',
                    icon: Icons.mail_outline_rounded,
                  ),
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _matKhauController,
                  focusNode: _passFocus,
                  obscureText: _anMatKhau,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _xuLyDangNhap(),
                  decoration: _fieldDeco(
                    label: 'Mật khẩu',
                    icon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        _anMatKhau
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 22,
                        color: _muted,
                      ),
                      onPressed: () =>
                          setState(() => _anMatKhau = !_anMatKhau),
                    ),
                  ),
                  validator: AuthValidators.matKhauDangNhap,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _blue,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (_loi != null) ...[
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loi!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _dangTai ? null : _xuLyDangNhap,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      disabledBackgroundColor: _blue.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _dangTai
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Hệ thống nội bộ · Chỉ dùng trong nhà máy OPC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF94A3B8),
                    fontSize: compact ? 11.5 : 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandSide({required bool isTablet}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004E80), Color(0xFF0068A9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 36 : 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isTablet ? 160 : 200,
                    height: isTablet ? 78 : 96,
                    padding: EdgeInsets.all(isTablet ? 10 : 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo_opc.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.local_pharmacy_rounded,
                        size: isTablet ? 40 : 48,
                        color: _blue,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 28),
                  Text(
                    'OPC Maintenance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Quản lý bảo trì & sửa chữa\ncơ điện nhà máy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: isTablet ? 13.5 : 14.5,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: isTablet ? 28 : 36),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Công ty CP Dược phẩm OPC',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _emailController.dispose();
    _matKhauController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Responsive(
        builder: (context, info) {
          final pad = MediaQuery.paddingOf(context);

          // Phone: form full width, scroll
          if (info.isMobile) {
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24 + pad.top * 0.1,
                      24,
                      24 + pad.bottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Center(
                        child: _buildForm(
                          maxWidth: 420,
                          compact: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          // Tablet / Desktop: brand + form
          final isTablet = info.isTablet;
          return Row(
            children: [
              Expanded(
                flex: isTablet ? 4 : 5,
                child: _brandSide(isTablet: isTablet),
              ),
              Expanded(
                flex: isTablet ? 6 : 5,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 48,
                        vertical: 40,
                      ),
                      child: _buildForm(
                        maxWidth: isTablet ? 400 : 420,
                        compact: false,
                      ),
                    ),
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

// ============ SHARED UI — QUÊN MẬT KHẨU / OTP / ĐẶT LẠI MK ============

class _AuthRecoveryPalette {
  static const blue = Color(0xFF0068A9);
  static const blueDeep = Color(0xFF024E82);
  static const blueSoft = Color(0xFF0EA5E9);
  static const mist = Color(0xFFEFF6FF);
  static const slate = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
}

/// Nền gradient + vòng sáng mờ, dùng chung 3 màn recovery.
class _RecoveryScaffold extends StatelessWidget {
  final Widget child;
  final String title;
  final Animation<double> fade;
  final Animation<Offset> slide;

  const _RecoveryScaffold({
    required this.child,
    required this.title,
    required this.fade,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          // Nền gradient xanh dịu
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0F7FC),
                  Color(0xFFE8F4FB),
                  Color(0xFFF8FBFE),
                ],
              ),
            ),
          ),
          // Vòng trang trí
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              size: 220,
              color: _AuthRecoveryPalette.blue.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -50,
            child: _GlowOrb(
              size: 180,
              color: _AuthRecoveryPalette.blueSoft.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 120,
            left: -30,
            child: _GlowOrb(
              size: 100,
              color: _AuthRecoveryPalette.blue.withValues(alpha: 0.06),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: _AuthRecoveryPalette.slate,
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: _AuthRecoveryPalette.slate,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      child: FadeTransition(
                        opacity: fade,
                        child: SlideTransition(
                          position: slide,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // chừa top inset visual
          Positioned(top: 0, left: 0, right: 0, height: top, child: const SizedBox()),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final Widget child;
  const _RecoveryCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: _AuthRecoveryPalette.blue.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _RecoveryHeroIcon extends StatelessWidget {
  final IconData icon;
  final Animation<double> pulse;
  const _RecoveryHeroIcon({required this.icon, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final s = 1 + (pulse.value * 0.04);
        return Transform.scale(
          scale: s,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _AuthRecoveryPalette.blue,
                  _AuthRecoveryPalette.blueSoft,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _AuthRecoveryPalette.blue.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        );
      },
    );
  }
}

InputDecoration _recoveryFieldDeco({
  required String label,
  String? hint,
  IconData? prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix == null
        ? null
        : Icon(prefix, size: 22, color: _AuthRecoveryPalette.muted),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF8FBFE),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide:
      const BorderSide(color: _AuthRecoveryPalette.blue, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
  );
}

Widget _recoveryPrimaryBtn({
  required String label,
  required VoidCallback? onPressed,
  required bool loading,
}) {
  return SizedBox(
    height: 52,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: onPressed == null
            ? null
            : const LinearGradient(
          colors: [
            _AuthRecoveryPalette.blue,
            _AuthRecoveryPalette.blueSoft,
          ],
        ),
        color: onPressed == null ? Colors.grey.shade300 : null,
        boxShadow: onPressed == null
            ? null
            : [
          BoxShadow(
            color: _AuthRecoveryPalette.blue.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.2, color: Colors.white),
        )
            : Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15.5,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
  );
}

// ============ MÀN 2: QUÊN MẬT KHẨU ============

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailLoginCtrl = TextEditingController();
  final _emailOtpCtrl = TextEditingController();
  bool _dangTai = false;
  String? _loi;

  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _enter.forward();
  }

  Future<void> _guiOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final emailLogin = _emailLoginCtrl.text.trim();
      final emailOtp = _emailOtpCtrl.text.trim();
      await AuthService.quenMatKhau(emailLogin, emailNhanOtp: emailOtp);
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, __, ___) => OtpScreen(
            email: emailLogin,
            emailNhanOtp: emailOtp,
          ),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    _emailLoginCtrl.dispose();
    _emailOtpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RecoveryScaffold(
      title: 'Khôi phục mật khẩu',
      fade: _fade,
      slide: _slide,
      child: _RecoveryCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: _RecoveryHeroIcon(
                      icon: Icons.mark_email_unread_rounded, pulse: _pulse)),
              const SizedBox(height: 18),
              const Text(
                'Nhận mã OTP qua Gmail đã đăng ký',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _AuthRecoveryPalette.slate,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập email đăng nhập công ty và đúng Gmail cá nhân đã gắn trên hồ sơ. '
                    'OTP chỉ gửi tới email đó — không gửi sang Gmail khác. '
                    'Đăng nhập sau vẫn dùng email công ty.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AuthRecoveryPalette.muted,
                  height: 1.45,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _emailLoginCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _recoveryFieldDeco(
                  label: 'Email đăng nhập (công ty)',
                  hint: 'vd: ten@opc.com',
                  prefix: Icons.business_rounded,
                ),
                validator: AuthValidators.email,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailOtpCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _recoveryFieldDeco(
                  label: 'Gmail cá nhân đã đăng ký trên hồ sơ',
                  hint: 'Phải khớp email nhận OTP trong Hồ sơ cá nhân',
                  prefix: Icons.alternate_email_rounded,
                ),
                validator: (v) {
                  final e = AuthValidators.email(v);
                  if (e != null) return e;
                  final low = v!.trim().toLowerCase();
                  if (!low.endsWith('@gmail.com')) {
                    return 'Email cá nhân phải đúng định dạng …@gmail.com';
                  }
                  return null;
                },
              ),
              if (_loi != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(text: _loi!),
              ],
              const SizedBox(height: 22),
              _recoveryPrimaryBtn(
                label: 'Gửi mã OTP',
                onPressed: _dangTai ? null : _guiOtp,
                loading: _dangTai,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ MÀN 3: NHẬP OTP ============

class OtpScreen extends StatefulWidget {
  final String email;
  final String emailNhanOtp;
  const OtpScreen({
    super.key,
    required this.email,
    required this.emailNhanOtp,
  });
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _dangTai = false;
  String? _loi;

  int _conHieuLuc = 120;
  int _choGuiLai = 60;
  Timer? _timer;

  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _enter.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_conHieuLuc > 0) _conHieuLuc--;
        if (_choGuiLai > 0) _choGuiLai--;
      });
    });
  }

  String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _xacThuc() async {
    if (!_formKey.currentState!.validate()) return;
    if (_conHieuLuc <= 0) {
      setState(() => _loi = 'Mã OTP đã hết hạn. Vui lòng gửi lại mã mới.');
      return;
    }
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      await AuthService.xacNhanOtp(widget.email, _otpController.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, __, ___) =>
              ResetPasswordScreen(email: widget.email),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  Future<void> _guiLai() async {
    if (_choGuiLai > 0) return;
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      await AuthService.quenMatKhau(
        widget.email,
        emailNhanOtp: widget.emailNhanOtp,
      );
      if (!mounted) return;
      setState(() {
        _conHieuLuc = 120;
        _choGuiLai = 60;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã gửi lại mã OTP · hiệu lực 2 phút'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _AuthRecoveryPalette.blue,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enter.dispose();
    _pulse.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hetHan = _conHieuLuc <= 0;
    final progress = _conHieuLuc / 120.0;

    return _RecoveryScaffold(
      title: 'Nhập mã OTP',
      fade: _fade,
      slide: _slide,
      child: _RecoveryCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: _RecoveryHeroIcon(
                      icon: Icons.password_rounded, pulse: _pulse)),
              const SizedBox(height: 18),
              const Text(
                'Xác thực OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _AuthRecoveryPalette.slate,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã đã gửi tới email cá nhân đã đăng ký\n(${widget.emailNhanOtp})',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _AuthRecoveryPalette.muted,
                  height: 1.4,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 18),
              // Timer ring-style bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hetHan
                      ? AppColors.danger.withValues(alpha: 0.06)
                      : _AuthRecoveryPalette.mist,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hetHan
                        ? AppColors.danger.withValues(alpha: 0.25)
                        : _AuthRecoveryPalette.blue.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          hetHan
                              ? Icons.timer_off_rounded
                              : Icons.timer_rounded,
                          color: hetHan
                              ? AppColors.danger
                              : _AuthRecoveryPalette.blue,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hetHan
                                ? 'Mã OTP đã hết hạn'
                                : 'Còn hiệu lực ${_fmt(_conHieuLuc)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: hetHan
                                  ? AppColors.danger
                                  : _AuthRecoveryPalette.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: progress, end: progress),
                        duration: const Duration(milliseconds: 350),
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white,
                          color: hetHan
                              ? AppColors.danger
                              : _AuthRecoveryPalette.blueSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  letterSpacing: 10,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _AuthRecoveryPalette.slate,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _recoveryFieldDeco(
                  label: 'Mã OTP (6 số)',
                ).copyWith(counterText: ''),
                validator: AuthValidators.otp,
              ),
              if (_loi != null) ...[
                const SizedBox(height: 10),
                _ErrorBanner(text: _loi!),
              ],
              const SizedBox(height: 18),
              _recoveryPrimaryBtn(
                label: 'Xác nhận OTP',
                onPressed: _dangTai ? null : _xacThuc,
                loading: _dangTai,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: (_dangTai || _choGuiLai > 0) ? null : _guiLai,
                child: Text(
                  _choGuiLai > 0
                      ? 'Gửi lại sau ${_fmt(_choGuiLai)}'
                      : 'Gửi lại OTP',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _choGuiLai > 0
                        ? Colors.grey
                        : _AuthRecoveryPalette.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ MÀN 4: ĐẶT LẠI MẬT KHẨU ============

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mkMoi = TextEditingController();
  final _mkLai = TextEditingController();
  bool _dangTai = false;
  bool _an1 = true;
  bool _an2 = true;
  String? _loi;
  int _doManh = 0;

  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _enter.forward();
  }

  Future<void> _luu() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      await AuthService.datLaiMatKhau(widget.email, _mkMoi.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Đã đổi mật khẩu. Đăng nhập bằng email công ty và mật khẩu mới.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
            (_) => false,
      );
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  Color _mauDoManh(int p) {
    if (p < 40) return AppColors.danger;
    if (p < 70) return const Color(0xFFF59E0B);
    return AppColors.success;
  }

  String _nhanDoManh(int p) {
    if (p <= 0) return 'Chưa nhập';
    if (p < 40) return 'Yếu';
    if (p < 70) return 'Trung bình';
    if (p < 90) return 'Khá tốt';
    return 'Mạnh';
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    _mkMoi.dispose();
    _mkLai.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mau = _mauDoManh(_doManh);
    return _RecoveryScaffold(
      title: 'Mật khẩu mới',
      fade: _fade,
      slide: _slide,
      child: _RecoveryCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: _RecoveryHeroIcon(
                      icon: Icons.lock_reset_rounded, pulse: _pulse)),
              const SizedBox(height: 18),
              const Text(
                'Tạo mật khẩu mới',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _AuthRecoveryPalette.slate,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tối thiểu 8 ký tự, có số và ký tự đặc biệt. '
                    'Đăng nhập vẫn dùng email công ty.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AuthRecoveryPalette.muted,
                  height: 1.45,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _mkMoi,
                obscureText: _an1,
                onChanged: (v) =>
                    setState(() => _doManh = AuthValidators.doManhMatKhau(v)),
                decoration: _recoveryFieldDeco(
                  label: 'Mật khẩu mới',
                  prefix: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      _an1 ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: _AuthRecoveryPalette.muted,
                    ),
                    onPressed: () => setState(() => _an1 = !_an1),
                  ),
                ),
                validator: AuthValidators.matKhauMoi,
              ),
              const SizedBox(height: 12),
              // Thanh độ mạnh
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _doManh / 100),
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          color: mau,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: mau,
                    ),
                    child: Text('$_doManh% · ${_nhanDoManh(_doManh)}'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _mkLai,
                obscureText: _an2,
                decoration: _recoveryFieldDeco(
                  label: 'Nhập lại mật khẩu',
                  prefix: Icons.verified_user_outlined,
                  suffix: IconButton(
                    icon: Icon(
                      _an2 ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: _AuthRecoveryPalette.muted,
                    ),
                    onPressed: () => setState(() => _an2 = !_an2),
                  ),
                ),
                validator: (v) {
                  if (v != _mkMoi.text) return 'Mật khẩu không khớp';
                  return AuthValidators.matKhauMoi(v);
                },
              ),
              if (_loi != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(text: _loi!),
              ],
              const SizedBox(height: 22),
              _recoveryPrimaryBtn(
                label: 'Xác nhận',
                onPressed: _dangTai ? null : _luu,
                loading: _dangTai,
              ),
            ],
          ),
        ),
      ),
    );
  }
}