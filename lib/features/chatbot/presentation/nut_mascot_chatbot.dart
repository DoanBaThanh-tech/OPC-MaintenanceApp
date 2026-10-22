import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'man_chatbot.dart';

/// Nút AI 3D hoạt hình — cảm xúc + chuyển động, kéo thả, co giãn theo màn hình.
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
  late final AnimationController _emotion;
  late final AnimationController _blink;
  late final AnimationController _wave;
  Offset? _offset;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Chu kỳ cảm xúc: vui → suy nghĩ → vui → nháy mắt…
    _emotion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _emotion.dispose();
    _blink.dispose();
    _wave.dispose();
    super.dispose();
  }

  double _sizeFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 58;
    if (w < 600) return 66;
    if (w < 900) return 74;
    return 82;
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
                begin: const Offset(0, 0.06),
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
    final size = _sizeFor(context);
    final mq = MediaQuery.of(context);
    final pad = mq.padding;
    final screen = mq.size;

    final defaultLeft = screen.width - size - 16;
    final defaultTop = screen.height - size - pad.bottom - 88;

    final left =
    (_offset?.dx ?? defaultLeft).clamp(8.0, screen.width - size - 8);
    final top = (_offset?.dy ?? defaultTop)
        .clamp(pad.top + 8, screen.height - size - pad.bottom - 8);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            final base = _offset ?? Offset(defaultLeft, defaultTop);
            _offset = Offset(base.dx + d.delta.dx, base.dy + d.delta.dy);
          });
        },
        onTap: _moChat,
        child: AnimatedBuilder(
          animation: Listenable.merge([_float, _emotion, _blink, _wave]),
          builder: (context, _) {
            final dy = math.sin(_float.value * math.pi) * 6;
            final tilt = math.sin(_wave.value * math.pi) * 0.08;
            // 0=vui, 1=suy nghĩ, 2=ngạc nhiên
            final phase = (_emotion.value * 3).floor() % 3;
            final eyeClosed =
            _blink.value > 0.88 && _blink.value < 0.94 ? 1.0 : 0.0;

            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(
                angle: tilt,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _OpcBotEmotionPainter(
                      emotion: phase,
                      eyeClosed: eyeClosed,
                      t: _float.value,
                      arm: _wave.value,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Robot 3D-style OPC: mặt cảm xúc + tay vẫy + viên thuốc + bánh răng.
class _OpcBotEmotionPainter extends CustomPainter {
  final int emotion; // 0 smile, 1 think, 2 wow
  final double eyeClosed;
  final double t;
  final double arm;

  _OpcBotEmotionPainter({
    required this.emotion,
    required this.eyeClosed,
    required this.t,
    required this.arm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.40;

    // Bóng
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.95),
        width: r * 1.5,
        height: r * 0.32,
      ),
      Paint()
        ..color = const Color(0xFF004E80).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Tay trái vẫy
    final armAngle = -0.6 + arm * 0.9;
    _drawArm(canvas, c + Offset(-r * 0.85, r * 0.1), armAngle, r * 0.45);
    // Tay phải
    _drawArm(canvas, c + Offset(r * 0.85, r * 0.1), 0.5 - arm * 0.4, r * 0.45);

    // Thân cầu 3D
    final body = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.4, -0.45),
        radius: 1.05,
        colors: [
          Color(0xFFBAE6FD),
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
          Color(0xFF0C4A6E),
        ],
        stops: [0.0, 0.3, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, body);

    // Highlight
    canvas.drawCircle(
      c + Offset(-r * 0.28, -r * 0.32),
      r * 0.22,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Ăng-ten
    final ant = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(0, -r), c + Offset(0, -r * 1.35), ant);
    canvas.drawCircle(
      c + Offset(0, -r * 1.4),
      r * 0.12,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(const Color(0xFF4ADE80), const Color(0xFF22D3EE), t)!,
            const Color(0xFF0EA5E9),
          ],
        ).createShader(Rect.fromCircle(
            center: c + Offset(0, -r * 1.4), radius: r * 0.12)),
    );

    // Mắt
    final eyeY = c.dy - r * 0.12;
    final eyeW = r * 0.16;
    final eyeH = eyeClosed > 0.5 ? r * 0.03 : r * 0.18;
    for (final dx in [-r * 0.28, r * 0.28]) {
      final er = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx + dx, eyeY), width: eyeW, height: eyeH),
        const Radius.circular(6),
      );
      canvas.drawRRect(er, Paint()..color = Colors.white);
      if (eyeClosed < 0.5) {
        // Con ngươi theo cảm xúc
        final pupilShift = emotion == 1 ? 2.0 : (emotion == 2 ? 0.0 : 0.0);
        canvas.drawCircle(
          Offset(c.dx + dx + pupilShift, eyeY),
          eyeW * 0.35,
          Paint()..color = const Color(0xFF0F172A),
        );
        canvas.drawCircle(
          Offset(c.dx + dx + pupilShift - 1.5, eyeY - 1.5),
          eyeW * 0.12,
          Paint()..color = Colors.white,
        );
      }
    }

    // Miệng theo cảm xúc
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final my = c.dy + r * 0.28;
    final path = Path();
    if (emotion == 0) {
      // Cười
      path.moveTo(c.dx - r * 0.22, my);
      path.quadraticBezierTo(c.dx, my + r * 0.18, c.dx + r * 0.22, my);
    } else if (emotion == 1) {
      // Suy nghĩ — miệng nhỏ lệch
      path.moveTo(c.dx - r * 0.08, my + 2);
      path.lineTo(c.dx + r * 0.14, my);
    } else {
      // Ngạc nhiên — miệng O
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx, my + 2), width: r * 0.2, height: r * 0.16),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
    if (emotion != 2) canvas.drawPath(path, mouthPaint);

    // Má hồng khi vui
    if (emotion == 0) {
      final cheek = Paint()..color = const Color(0xFFF472B6).withValues(alpha: 0.35);
      canvas.drawCircle(Offset(c.dx - r * 0.48, c.dy + r * 0.08), r * 0.1, cheek);
      canvas.drawCircle(Offset(c.dx + r * 0.48, c.dy + r * 0.08), r * 0.1, cheek);
    }

    // Viên thuốc nhỏ (dược OPC) góc dưới
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(c.dx, c.dy + r * 0.55), width: r * 0.7, height: r * 0.22),
      Radius.circular(r * 0.11),
    );
    canvas.save();
    canvas.clipRRect(pill);
    canvas.drawRRect(pill, Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawRect(
      Rect.fromLTRB(c.dx, c.dy + r * 0.55 - r * 0.11, c.dx + r * 0.35, c.dy + r * 0.55 + r * 0.11),
      Paint()..color = const Color(0xFF0068A9).withValues(alpha: 0.85),
    );
    canvas.restore();

    // Viền sáng
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.3 + 0.2 * t),
    );
  }

  void _drawArm(Canvas canvas, Offset root, double angle, double len) {
    final end = Offset(
      root.dx + math.cos(angle) * len,
      root.dy + math.sin(angle) * len,
    );
    canvas.drawLine(
      root,
      end,
      Paint()
        ..color = const Color(0xFF38BDF8)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(end, 5, Paint()..color = const Color(0xFF7DD3FC));
  }

  @override
  bool shouldRepaint(covariant _OpcBotEmotionPainter old) =>
      old.emotion != emotion ||
          old.eyeClosed != eyeClosed ||
          old.t != t ||
          old.arm != arm;
}