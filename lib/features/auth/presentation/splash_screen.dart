import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_screens.dart';

/// Splash OPC — nền trắng, điểm nhấn xanh, co giãn theo phone/tablet → Đăng nhập.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _blue = Color(0xFF0068A9);
  static const _blueMid = Color(0xFF0284C7);
  static const _blueSoft = Color(0xFF38BDF8);

  late final AnimationController _mainCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subFade;
  late final Animation<double> _barFade;
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _subFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.48, 0.82, curve: Curves.easeOut),
      ),
    );
    _barFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.62, 1.0, curve: Curves.easeOut),
      ),
    );
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
    _exitScale = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _mainCtrl.forward();
    _scheduleGoLogin();
  }

  Future<void> _scheduleGoLogin() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    await _exitCtrl.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 480),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) {
          final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final shortest = size.shortestSide;
    final isTablet = shortest >= 600;
    final isWide = size.width >= 900;

    // Co giãn theo kích thước thiết bị
    final logoSize = (shortest * 0.22).clamp(88.0, isTablet ? 140.0 : 118.0);
    final titleSize = (shortest * 0.055).clamp(22.0, isTablet ? 32.0 : 26.0);
    final subSize = (shortest * 0.032).clamp(13.0, 16.0);
    final companySize = (shortest * 0.034).clamp(13.5, 16.0);
    final hPad = isWide ? size.width * 0.18 : (isTablet ? 48.0 : 28.0);
    final ringSize = logoSize * 1.85;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [_mainCtrl, _pulseCtrl, _ringCtrl, _exitCtrl]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitFade.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
                child: Stack(
                  children: [
                    // Soft blue blobs (nhẹ, nền trắng)
                    Positioned(
                      top: -size.height * 0.08,
                      right: -size.width * 0.15,
                      child: _SoftBlob(
                        size: size.width * (isTablet ? 0.45 : 0.55),
                        color: _blueSoft.withValues(alpha: 0.12),
                        pulse: _pulseCtrl.value,
                      ),
                    ),
                    Positioned(
                      bottom: -size.height * 0.06,
                      left: -size.width * 0.18,
                      child: _SoftBlob(
                        size: size.width * (isTablet ? 0.4 : 0.5),
                        color: _blue.withValues(alpha: 0.08),
                        pulse: 1 - _pulseCtrl.value,
                      ),
                    ),
                    // Vòng dashed quanh logo
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, -size.height * 0.06),
                        child: Transform.rotate(
                          angle: _ringCtrl.value * 2 * math.pi,
                          child: Opacity(
                            opacity: 0.35 * _logoFade.value,
                            child: CustomPaint(
                              size: Size(ringSize, ringSize),
                              painter: _DashedRingPainter(
                                color: _blue.withValues(alpha: 0.28),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Column(
                          children: [
                            const Spacer(flex: 5),
                            FadeTransition(
                              opacity: _logoFade,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: _LogoBadge(
                                  size: logoSize,
                                  pulse: _pulseCtrl.value,
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 32 : 24),
                            SlideTransition(
                              position: _titleSlide,
                              child: FadeTransition(
                                opacity: _titleFade,
                                child: Column(
                                  children: [
                                    Text(
                                      'OPC Maintenance',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFF0F172A),
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        height: 1.15,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 8 : 6),
                                    Text(
                                      'Công ty CP Dược phẩm OPC',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _blue,
                                        fontSize: companySize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 16 : 12),
                            FadeTransition(
                              opacity: _subFade,
                              child: ConstrainedBox(
                                constraints:
                                BoxConstraints(maxWidth: isTablet ? 420 : 320),
                                child: Text(
                                  'Quản lý hồ sơ bảo trì & sửa chữa cơ điện',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF64748B),
                                    fontSize: subSize,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(flex: 4),
                            FadeTransition(
                              opacity: _barFade,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: isTablet ? 140 : 112,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        minHeight: 3,
                                        backgroundColor:
                                        _blue.withValues(alpha: 0.12),
                                        valueColor:
                                        const AlwaysStoppedAnimation(_blueMid),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Đang khởi động…',
                                    style: TextStyle(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: isTablet ? 13.5 : 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isTablet ? 28 : 20),
                            FadeTransition(
                              opacity: _barFade,
                              child: Text(
                                '© OPC · Cơ điện nhà máy',
                                style: TextStyle(
                                  color: const Color(0xFFCBD5E1),
                                  fontSize: isTablet ? 12.5 : 11.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 12 + media.padding.bottom),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  final double size;
  final double pulse;
  const _LogoBadge({required this.size, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.42;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0068A9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0068A9).withValues(alpha: 0.22 + pulse * 0.1),
            blurRadius: 20 + pulse * 8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.precision_manufacturing_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double pulse;

  const _SoftBlob({
    required this.size,
    required this.color,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final s = size * (0.94 + pulse * 0.06);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  _DashedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    const dash = 9.0;
    const gap = 7.0;
    final r = rect.width / 2;
    final circumference = 2 * math.pi * r;
    final n = math.max(8, (circumference / (dash + gap)).floor());
    final sweep = (2 * math.pi) / n;

    for (var i = 0; i < n; i++) {
      canvas.drawArc(
        rect,
        i * sweep,
        sweep * (dash / (dash + gap)),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) => old.color != color;
}