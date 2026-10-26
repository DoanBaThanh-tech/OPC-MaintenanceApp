import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'man_chatbot.dart';

/// Icon chatbot — robot kỹ sư cơ điện chibi 3D, kéo thả, hiệu ứng động.
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
  late final AnimationController _float;
  late final AnimationController _pulse;
  late final AnimationController _blink;
  late final AnimationController _wave;
  Offset? _offset;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _pulse.dispose();
    _blink.dispose();
    _wave.dispose();
    super.dispose();
  }

  double _sizeFor(double width) {
    if (width < 360) return 56;
    if (width < 600) return 60;
    if (width < 900) return 64;
    return 68;
  }

  Offset _kep(Offset raw, double size, double maxW, double maxH) {
    const m = 8.0;
    return Offset(
      raw.dx.clamp(m, math.max(m, maxW - size - m)),
      raw.dy.clamp(m, math.max(m, maxH - size - m)),
    );
  }

  void _moChat() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ManChatbotScreen(
          hoTen: widget.hoTen,
          vaiTro: widget.vaiTro,
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;
          final size = _sizeFor(maxW);
          final def = _kep(
            Offset(maxW - size - 14, maxH - size - 14),
            size,
            maxW,
            maxH,
          );
          final pos = _kep(_offset ?? def, size, maxW, maxH);
          if (_offset != null &&
              (_offset!.dx != pos.dx || _offset!.dy != pos.dy)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _offset = pos);
            });
          }

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: pos.dx,
                top: pos.dy,
                child: GestureDetector(
                  onPanUpdate: (d) {
                    setState(() {
                      final base = _offset ?? def;
                      _offset = _kep(
                        Offset(base.dx + d.delta.dx, base.dy + d.delta.dy),
                        size,
                        maxW,
                        maxH,
                      );
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _offset = _kep(_offset ?? def, size, maxW, maxH);
                    });
                  },
                  onTap: _moChat,
                  child: AnimatedBuilder(
                    animation:
                    Listenable.merge([_float, _pulse, _blink, _wave]),
                    builder: (_, __) {
                      final dy = math.sin(_float.value * math.pi) * 5;
                      final scale = 1.0 + _pulse.value * 0.05;
                      final eyeClosed =
                          _blink.value > 0.88 && _blink.value < 0.94;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: CustomPaint(
                              painter: _RobotKySuPainter(
                                t: _float.value,
                                pulse: _pulse.value,
                                wave: _wave.value,
                                eyeClosed: eyeClosed,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

/// Robot kỹ sư chibi — mũ bảo hộ, mắt to, cờ lê, tông xanh OPC.
class _RobotKySuPainter extends CustomPainter {
  final double t;
  final double pulse;
  final double wave;
  final bool eyeClosed;

  _RobotKySuPainter({
    required this.t,
    required this.pulse,
    required this.wave,
    required this.eyeClosed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);

    // --- Hào quang / glow ---
    final glowR = s * (0.48 + pulse * 0.04);
    canvas.drawCircle(
      c,
      glowR,
      Paint()
        ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.18 + pulse * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      c,
      s * 0.46,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.25 + pulse * 0.2),
    );

    // --- Bóng dưới chân ---
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + s * 0.44),
        width: s * 0.42,
        height: s * 0.10,
      ),
      Paint()
        ..color = const Color(0xFF0369A1).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // --- Thân áo xanh OPC ---
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + s * 0.14),
        width: s * 0.50,
        height: s * 0.40,
      ),
      Radius.circular(s * 0.12),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF38BDF8),
            Color(0xFF0284C7),
            Color(0xFF0369A1),
          ],
        ).createShader(bodyRect.outerRect),
    );
    // Viền sáng thân
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Túi đựng dụng cụ
    final pocket = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(c.dx + s * 0.08, c.dy + s * 0.22),
        width: s * 0.16,
        height: s * 0.12,
      ),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(pocket, Paint()..color = const Color(0xFF0C4A6E));
    // Cờ lê nhỏ trong túi
    final wrench = Paint()
      ..color = const Color(0xFFFBBF24)
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx + s * 0.04, c.dy + s * 0.18),
      Offset(c.dx + s * 0.12, c.dy + s * 0.28),
      wrench,
    );

    // --- Tay trái (tĩnh) ---
    final armPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(0, 0, s, s))
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - s * 0.22, c.dy + s * 0.04),
      Offset(c.dx - s * 0.36, c.dy + s * 0.16),
      armPaint,
    );

    // --- Tay phải vẫy ---
    final swing = (wave - 0.5) * 0.55;
    final handEnd = Offset(
      c.dx + s * 0.34,
      c.dy - s * 0.02 + swing * s * 0.35,
    );
    canvas.drawLine(
      Offset(c.dx + s * 0.22, c.dy + s * 0.02),
      handEnd,
      armPaint,
    );
    // Bàn tay
    canvas.drawCircle(
      handEnd,
      s * 0.055,
      Paint()..color = const Color(0xFFE2E8F0),
    );

    // --- Chân ---
    final leg = Paint()
      ..color = const Color(0xFF075985)
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx - s * 0.10, c.dy + s * 0.32),
      Offset(c.dx - s * 0.12, c.dy + s * 0.42),
      leg,
    );
    canvas.drawLine(
      Offset(c.dx + s * 0.10, c.dy + s * 0.32),
      Offset(c.dx + s * 0.12, c.dy + s * 0.42),
      leg,
    );
    // Giày
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx - s * 0.12, c.dy + s * 0.44),
        width: s * 0.14,
        height: s * 0.06,
      ),
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx + s * 0.12, c.dy + s * 0.44),
        width: s * 0.14,
        height: s * 0.06,
      ),
      Paint()..color = const Color(0xFF0F172A),
    );

    // --- Đầu kim loại ---
    final headC = Offset(c.dx, c.dy - s * 0.14);
    final headR = s * 0.22;
    canvas.drawCircle(
      headC,
      headR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            const Color(0xFFF1F5F9),
            const Color(0xFFCBD5E1),
            const Color(0xFF94A3B8),
          ],
        ).createShader(Rect.fromCircle(center: headC, radius: headR)),
    );
    // Tai robot
    canvas.drawCircle(
      Offset(headC.dx - headR * 0.95, headC.dy),
      s * 0.06,
      Paint()..color = const Color(0xFF0284C7),
    );
    canvas.drawCircle(
      Offset(headC.dx + headR * 0.95, headC.dy),
      s * 0.06,
      Paint()..color = const Color(0xFF0284C7),
    );
    // Ăng-ten
    canvas.drawLine(
      Offset(headC.dx + headR * 0.55, headC.dy - headR * 0.7),
      Offset(headC.dx + headR * 0.75, headC.dy - headR * 1.25),
      Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = s * 0.025
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(headC.dx + headR * 0.75, headC.dy - headR * 1.25),
      s * 0.035,
      Paint()..color = const Color(0xFF22D3EE),
    );

    // --- Mũ bảo hộ vàng ---
    final hatPath = Path()
      ..moveTo(headC.dx - headR * 1.05, headC.dy - headR * 0.15)
      ..quadraticBezierTo(
        headC.dx,
        headC.dy - headR * 1.55,
        headC.dx + headR * 1.05,
        headC.dy - headR * 0.15,
      )
      ..close();
    canvas.drawPath(
      hatPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFFACC15), Color(0xFFEAB308)],
        ).createShader(Rect.fromCircle(center: headC, radius: headR)),
    );
    // Gờ mũ
    canvas.drawLine(
      Offset(headC.dx - headR * 1.15, headC.dy - headR * 0.12),
      Offset(headC.dx + headR * 1.15, headC.dy - headR * 0.12),
      Paint()
        ..color = const Color(0xFFCA8A04)
        ..strokeWidth = s * 0.045
        ..strokeCap = StrokeCap.round,
    );
    // Logo OPC nhỏ trên mũ
    final logoR = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(headC.dx, headC.dy - headR * 0.55),
        width: s * 0.16,
        height: s * 0.08,
      ),
      Radius.circular(s * 0.02),
    );
    canvas.drawRRect(logoR, Paint()..color = const Color(0xFF0369A1));
    final tp = TextPainter(
      text: TextSpan(
        text: 'OPC',
        style: TextStyle(
          color: Colors.white,
          fontSize: s * 0.055,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        headC.dx - tp.width / 2,
        headC.dy - headR * 0.55 - tp.height / 2,
      ),
    );

    // --- Mắt ---
    final eyeY = headC.dy + headR * 0.05;
    final eyeH = eyeClosed ? s * 0.012 : s * 0.07;
    for (final dx in [-headR * 0.35, headR * 0.35]) {
      final eyeCenter = Offset(headC.dx + dx, eyeY);
      // Tròng trắng
      if (!eyeClosed) {
        canvas.drawOval(
          Rect.fromCenter(
            center: eyeCenter,
            width: s * 0.10,
            height: eyeH,
          ),
          Paint()..color = Colors.white,
        );
        // Con ngươi
        canvas.drawCircle(
          eyeCenter.translate(0, s * 0.008),
          s * 0.028,
          Paint()..color = const Color(0xFF0EA5E9),
        );
        canvas.drawCircle(
          eyeCenter.translate(-s * 0.01, 0),
          s * 0.012,
          Paint()..color = Colors.white,
        );
      } else {
        canvas.drawLine(
          Offset(eyeCenter.dx - s * 0.04, eyeCenter.dy),
          Offset(eyeCenter.dx + s * 0.04, eyeCenter.dy),
          Paint()
            ..color = const Color(0xFF334155)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // --- Miệng cười ---
    final smile = Path()
      ..moveTo(headC.dx - headR * 0.28, headC.dy + headR * 0.38)
      ..quadraticBezierTo(
        headC.dx,
        headC.dy + headR * 0.58,
        headC.dx + headR * 0.28,
        headC.dy + headR * 0.38,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF0369A1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // --- Badge AI trên ngực ---
    final badge = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(c.dx - s * 0.08, c.dy + s * 0.12),
        width: s * 0.20,
        height: s * 0.11,
      ),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(
      badge,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    final ai = TextPainter(
      text: TextSpan(
        text: 'AI',
        style: TextStyle(
          color: const Color(0xFF0284C7),
          fontSize: s * 0.07,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    ai.paint(
      canvas,
      Offset(
        c.dx - s * 0.08 - ai.width / 2,
        c.dy + s * 0.12 - ai.height / 2,
      ),
    );

    // --- Sparkle xoay nhẹ ---
    final sparkAngle = t * math.pi * 2;
    final sparkPos = Offset(
      c.dx + math.cos(sparkAngle) * s * 0.42,
      c.dy + math.sin(sparkAngle) * s * 0.42 - s * 0.05,
    );
    canvas.drawCircle(
      sparkPos,
      s * 0.025,
      Paint()
        ..color = const Color(0xFF67E8F9).withValues(alpha: 0.7 + pulse * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RobotKySuPainter old) =>
      old.t != t ||
          old.pulse != pulse ||
          old.wave != wave ||
          old.eyeClosed != eyeClosed;
}