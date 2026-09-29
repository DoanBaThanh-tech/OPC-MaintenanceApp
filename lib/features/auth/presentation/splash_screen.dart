import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth_screens.dart';

/// Splash OPC — logo dược phẩm căn giữa, nền trắng, xanh chủ đạo, responsive.
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
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _logoScale = Tween<double>(begin: 0.78, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
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
        curve: const Interval(0.28, 0.62, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.28, 0.68, curve: Curves.easeOutCubic),
      ),
    );
    _subFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
      ),
    );
    _barFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
    _exitScale = Tween<double>(begin: 1, end: 0.98).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _mainCtrl.forward();
    _scheduleGoLogin();
  }

  Future<void> _scheduleGoLogin() async {
    await Future.delayed(const Duration(milliseconds: 2700));
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
            begin: const Offset(0, 0.03),
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

    final logoW = (shortest * 0.42).clamp(140.0, isTablet ? 280.0 : 220.0);
    final logoH = logoW * 0.55;
    final titleSize = (shortest * 0.048).clamp(20.0, isTablet ? 28.0 : 24.0);
    final subSize = (shortest * 0.032).clamp(13.0, 15.5);
    final hPad = isWide ? size.width * 0.2 : (isTablet ? 56.0 : 32.0);
    final ringSize = logoW * 1.35;

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
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: Colors.white),
                    ),
                    Positioned(
                      top: size.height * 0.08,
                      right: -size.width * 0.12,
                      child: _SoftBlob(
                        size: size.width * (isTablet ? 0.42 : 0.5),
                        color: _blueSoft.withValues(alpha: 0.1),
                        pulse: _pulseCtrl.value,
                      ),
                    ),
                    Positioned(
                      bottom: size.height * 0.05,
                      left: -size.width * 0.15,
                      child: _SoftBlob(
                        size: size.width * (isTablet ? 0.38 : 0.48),
                        color: _blue.withValues(alpha: 0.07),
                        pulse: 1 - _pulseCtrl.value,
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),
                            SizedBox(
                              width: ringSize,
                              height: ringSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: _ringCtrl.value * 2 * math.pi,
                                    child: Opacity(
                                      opacity: 0.4 * _logoFade.value,
                                      child: CustomPaint(
                                        size: Size(ringSize, ringSize),
                                        painter: _DashedRingPainter(
                                          color: _blue.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  FadeTransition(
                                    opacity: _logoFade,
                                    child: ScaleTransition(
                                      scale: _logoScale,
                                      child: Container(
                                        width: logoW,
                                        height: logoH,
                                        padding: EdgeInsets.all(
                                            isTablet ? 12.0 : 8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                          BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _blue.withValues(
                                                  alpha: 0.12 +
                                                      _pulseCtrl.value * 0.06),
                                              blurRadius:
                                              18 + _pulseCtrl.value * 6,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/images/logo_opc.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.local_pharmacy_rounded,
                                            size: logoW * 0.35,
                                            color: _blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isTablet ? 28 : 22),
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
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: isTablet ? 8 : 6),
                                    Text(
                                      'Công ty CP Dược phẩm OPC',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _blue,
                                        fontSize: (titleSize * 0.58)
                                            .clamp(13.0, 16.0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 14 : 10),
                            FadeTransition(
                              opacity: _subFade,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth: isTablet ? 400 : 300),
                                child: Text(
                                  'Quản lý hồ sơ bảo trì & sửa chữa cơ điện',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF64748B),
                                    fontSize: subSize,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(flex: 2),
                            FadeTransition(
                              opacity: _barFade,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: isTablet ? 130 : 100,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        minHeight: 3,
                                        backgroundColor:
                                        _blue.withValues(alpha: 0.1),
                                        valueColor:
                                        const AlwaysStoppedAnimation(
                                            _blueMid),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Đang khởi động…',
                                    style: TextStyle(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: isTablet ? 13 : 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isTablet ? 24 : 16),
                            FadeTransition(
                              opacity: _barFade,
                              child: Text(
                                '© OPC Pharma · Cơ điện nhà máy',
                                style: TextStyle(
                                  color: const Color(0xFFCBD5E1),
                                  fontSize: isTablet ? 12 : 11,
                                ),
                              ),
                            ),
                            SizedBox(height: 10 + media.padding.bottom),
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
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    const dash = 8.0;
    const gap = 6.0;
    final r = rect.width / 2;
    final circumference = 2 * math.pi * r;
    final n = math.max(10, (circumference / (dash + gap)).floor());
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