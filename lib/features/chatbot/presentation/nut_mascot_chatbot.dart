import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'man_chatbot.dart';

/// Nút nhân vật hoạt hình nổi — bấm mở chatbot theo vai trò.
class NutMascotChatbot extends StatefulWidget {
  final String hoTen;
  final String vaiTro;

  const NutMascotChatbot({
    super.key,
    required this.hoTen,
    required this.vaiTro,
  });

  @override
  State<NutMascotChatbot> createState() => _NutMascotChatbotState();
}

class _NutMascotChatbotState extends State<NutMascotChatbot>
    with TickerProviderStateMixin {
  late final AnimationController _bounce;
  late final AnimationController _pulse;
  late final AnimationController _blink;
  late final Animation<double> _bounceY;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _bounceY = Tween(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _bounce, curve: Curves.easeInOut),
    );

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseScale = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _bounce.dispose();
    _pulse.dispose();
    _blink.dispose();
    super.dispose();
  }

  void _moChat() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ManChatbotScreen(
          hoTen: widget.hoTen,
          vaiTro: widget.vaiTro,
        ),
        transitionsBuilder: (_, a, __, child) {
          return FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounce, _pulse, _blink]),
      builder: (context, _) {
        final eyeScaleY = _blink.value > 0.92 && _blink.value < 0.96 ? 0.15 : 1.0;
        return Transform.translate(
          offset: Offset(0, _bounceY.value),
          child: Transform.scale(
            scale: _pulseScale.value,
            child: GestureDetector(
              onTap: _moChat,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF38BDF8), Color(0xFF0068A9), Color(0xFF004E80)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Vầng sáng
                    CustomPaint(
                      size: const Size(72, 72),
                      painter: _RingPainter(progress: _pulse.value),
                    ),
                    // Mặt robot
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _mat(eyeScaleY),
                            const SizedBox(width: 10),
                            _mat(eyeScaleY),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 18,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    // Badge AI
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0068A9),
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
      },
    );
  }

  Widget _mat(double scaleY) {
    return Transform.scale(
      scaleY: scaleY,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.6),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.25 + 0.25 * math.sin(progress * math.pi));
    canvas.drawCircle(c, r, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}