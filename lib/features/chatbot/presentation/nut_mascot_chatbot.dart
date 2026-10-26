import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'man_chatbot.dart';

/// Icon chatbot OPC Bot — ảnh 3D + hiệu ứng, kích thước nhỏ, kéo thả trong màn hình.
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
  Offset? _offset;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    _pulse.dispose();
    super.dispose();
  }

  double _sizeFor(double width) {
    if (width < 360) return 52;
    if (width < 600) return 56;
    if (width < 900) return 60;
    return 64;
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
            Offset(maxW - size - 12, maxH - size - 12),
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
                    animation: Listenable.merge([_float, _pulse]),
                    builder: (_, __) {
                      final dy = math.sin(_float.value * math.pi) * 4;
                      final scale = 1.0 + (_pulse.value * 0.04);
                      final glow = 0.25 + _pulse.value * 0.35;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF16A34A)
                                      .withValues(alpha: glow * 0.55),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/opc_bot.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF166534),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.smart_toy_rounded,
                                      color: Colors.white, size: 28),
                                ),
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