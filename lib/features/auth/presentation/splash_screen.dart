import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import 'auth_screens.dart';

/// Splash OPC — xanh chủ đạo, hiệu ứng vào/ra hiện đại → Đăng nhập.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _blue = Color(0xFF0068A9);
  static const _blueMid = Color(0xFF0284C7);
  static const _blueSoft = Color(0xFF0EA5E9);
  static const _blueDeep = Color(0xFF004E80);

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
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _subFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );
    _barFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInCubic),
    );
    _exitScale = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _mainCtrl.forward();
    _scheduleGoLogin();
  }

  Future<void> _scheduleGoLogin() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    await _exitCtrl.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) {
          final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainCtrl, _pulseCtrl, _ringCtrl, _exitCtrl]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitFade.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF003D66),
                      _blueDeep,
                      _blue,
                      _blueMid,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    // Vòng sáng nền
                    Positioned(
                      top: -size.height * 0.12,
                      right: -size.width * 0.2,
                      child: _GlowOrb(
                        size: size.width * 0.7,
                        color: _blueSoft.withValues(alpha: 0.22),
                        pulse: _pulseCtrl.value,
                      ),
                    ),
                    Positioned(
                      bottom: -size.height * 0.08,
                      left: -size.width * 0.25,
                      child: _GlowOrb(
                        size: size.width * 0.65,
                        color: Colors.white.withValues(alpha: 0.08),
                        pulse: 1 - _pulseCtrl.value,
                      ),
                    ),
                    // Vòng quay trang trí
                    Center(
                      child: Transform.rotate(
                        angle: _ringCtrl.value * 2 * math.pi,
                        child: Opacity(
                          opacity: 0.18 * _logoFade.value,
                          child: CustomPaint(
                            size: const Size(220, 220),
                            painter: _DashedRingPainter(
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Nội dung chính
                    SafeArea(
                      child: Column(
                        children: [
                          const Spacer(flex: 3),
                          // Logo
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: _LogoBadge(pulse: _pulseCtrl.value),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Tên app
                          SlideTransition(
                            position: _titleSlide,
                            child: FadeTransition(
                              opacity: _titleFade,
                              child: const Column(
                                children: [
                                  Text(
                                    'OPC Maintenance',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.4,
                                      height: 1.15,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Công ty CP Dược phẩm OPC',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          FadeTransition(
                            opacity: _subFade,
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Quản lý hồ sơ bảo trì & sửa chữa cơ điện',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(flex: 2),
                          // Progress
                          FadeTransition(
                            opacity: _barFade,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      minHeight: 3.5,
                                      backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                      valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Đang khởi động…',
                                  style: TextStyle(
                                    color:
                                    Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 36),
                          FadeTransition(
                            opacity: _barFade,
                            child: Text(
                              '© OPC · Cơ điện nhà máy',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                              16 + MediaQuery.paddingOf(context).bottom),
                        ],
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
  final double pulse;
  const _LogoBadge({required this.pulse});

  @override
  Widget build(BuildContext context) {
    final glow = 0.35 + pulse * 0.25;
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0068A9), Color(0xFF004E80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: glow),
            blurRadius: 28 + pulse * 12,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2.5,
        ),
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.precision_manufacturing_rounded,
            size: 48,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double pulse;

  const _GlowOrb({
    required this.size,
    required this.color,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final s = size * (0.92 + pulse * 0.08);
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
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    const dash = 10.0;
    const gap = 8.0;
    final circumference = 2 * math.pi * (rect.width / 2);
    final n = (circumference / (dash + gap)).floor();
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