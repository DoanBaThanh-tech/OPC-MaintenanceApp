import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'man_chatbot.dart';

/// Nút AI 3D-style (OPC dược + cơ điện), co giãn theo màn hình, kéo thả tự do.
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
  late final AnimationController _spin;
  Offset? _offset; // null = góc mặc định

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _spin.dispose();
    super.dispose();
  }

  double _sizeFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 360) return 56;
    if (w < 600) return 64;
    if (w < 900) return 72;
    return 80;
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

    // Mặc định: góc phải dưới, tránh home indicator
    final defaultLeft = screen.width - size - 16;
    final defaultTop = screen.height - size - pad.bottom - 88;

    final left = (_offset?.dx ?? defaultLeft).clamp(8.0, screen.width - size - 8);
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
          animation: Listenable.merge([_float, _spin]),
          builder: (context, _) {
            final dy = math.sin(_float.value * math.pi) * 5;
            return Transform.translate(
              offset: Offset(0, dy),
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _OpcBot3dPainter(
                    t: _float.value,
                    spin: _spin.value,
                  ),
                  child: Center(
                    child: Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w900,
                        fontSize: size * 0.18,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
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

/// Vẽ nhân vật 3D-style: viên thuốc OPC + bánh răng cơ điện.
class _OpcBot3dPainter extends CustomPainter {
  final double t;
  final double spin;
  _OpcBot3dPainter({required this.t, required this.spin});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;

    // Bóng đổ 3D
    final shadow = Paint()
      ..color = const Color(0xFF004E80).withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy + r * 0.85),
        width: r * 1.4,
        height: r * 0.35,
      ),
      shadow,
    );

    // Thân cầu gradient (chiều sâu)
    final body = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.4),
        radius: 1.1,
        colors: [
          Color(0xFF7DD3FC),
          Color(0xFF0EA5E9),
          Color(0xFF0068A9),
          Color(0xFF003A5C),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, body);

    // Highlight bóng kính
    final hi = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.55),
        radius: 0.55,
        colors: [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r * 0.92, hi);

    // Viên nang thuốc (chủ đề dược OPC)
    final pillW = r * 0.95;
    final pillH = r * 0.38;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(c.dx, c.dy - r * 0.08), width: pillW, height: pillH),
      Radius.circular(pillH / 2),
    );
    canvas.save();
    canvas.clipRRect(pillRect);
    canvas.drawRRect(
      pillRect,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
    canvas.drawRect(
      Rect.fromLTRB(
        c.dx,
        c.dy - r * 0.08 - pillH / 2,
        c.dx + pillW / 2,
        c.dy - r * 0.08 + pillH / 2,
      ),
      Paint()..color = const Color(0xFF0068A9).withValues(alpha: 0.9),
    );
    canvas.restore();
    canvas.drawRRect(
      pillRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.5),
    );

    // Bánh răng quay (cơ điện)
    final gearR = r * 0.55;
    final gearPaint = Paint()
      ..color = const Color(0xFFFFF7ED).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.save();
    canvas.translate(c.dx, c.dy + r * 0.12);
    canvas.rotate(spin * math.pi * 2);
    final path = Path();
    const teeth = 8;
    for (var i = 0; i < teeth; i++) {
      final a0 = (i / teeth) * math.pi * 2;
      final a1 = a0 + math.pi / teeth;
      path.moveTo(math.cos(a0) * gearR * 0.72, math.sin(a0) * gearR * 0.72);
      path.lineTo(math.cos(a0) * gearR, math.sin(a0) * gearR);
      path.lineTo(math.cos(a1) * gearR, math.sin(a1) * gearR);
      path.lineTo(math.cos(a1) * gearR * 0.72, math.sin(a1) * gearR * 0.72);
    }
    canvas.drawPath(path, gearPaint);
    canvas.drawCircle(Offset.zero, gearR * 0.28, gearPaint);
    canvas.restore();

    // Viền phát sáng
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.25 + 0.2 * t),
    );
  }

  @override
  bool shouldRepaint(covariant _OpcBot3dPainter old) =>
      old.t != t || old.spin != spin;
}