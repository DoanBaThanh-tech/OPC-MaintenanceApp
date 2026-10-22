import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/chatbot_service.dart';

class ManChatbotScreen extends StatefulWidget {
  final String hoTen;
  final String vaiTro;

  const ManChatbotScreen({
    super.key,
    required this.hoTen,
    required this.vaiTro,
  });

  @override
  State<ManChatbotScreen> createState() => _ManChatbotScreenState();
}

class _ManChatbotScreenState extends State<ManChatbotScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _tinNhan = <ChatTinNhan>[];
  bool _dangGui = false;
  bool? _ollamaOnline;
  String? _model;

  String get _tenChao {
    final t = widget.hoTen.trim();
    if (t.isEmpty) return 'bạn';
    final parts = t.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : t;
  }

  @override
  void initState() {
    super.initState();
    _loiChaoVaKiemTra();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loiChaoVaKiemTra() async {
    setState(() {
      _tinNhan.add(ChatTinNhan(
        role: 'assistant',
        content:
        'Chào $_tenChao! Mình là OPC Bot đây 😊\n\n'
            'Mình hỗ trợ bạn với vai trò «${widget.vaiTro}» — '
            'hỏi số lượng hồ sơ, ngày bảo trì, tổng tiền vật tư… mình trả lời ngay bằng số liệu trên hệ thống.\n\n'
            'Bạn muốn hỏi gì nào?',
      ));
    });

    try {
      final st = await ChatbotService.instance.kiemTra();
      if (!mounted) return;
      setState(() {
        _ollamaOnline = st.online;
        _model = st.model;
      });
      if (!st.online) {
        setState(() {
          _tinNhan.add(ChatTinNhan(
            role: 'assistant',
            content:
            'À, AI local trên máy chưa bật. Bạn mở Ollama giúp mình rồi hỏi lại nhé.\n'
                '${st.message ?? ""}',
          ));
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ollamaOnline = false;
        _tinNhan.add(ChatTinNhan(
          role: 'assistant',
          content:
          'Mình chưa kết nối được AI local. Kiểm tra API/ngrok và Ollama trên máy giúp mình nhé.',
        ));
      });
    }
  }

  Future<void> _gui() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _dangGui) return;
    setState(() {
      _tinNhan.add(ChatTinNhan(role: 'user', content: text));
      _ctrl.clear();
      _dangGui = true;
    });
    _scrollCuoi();

    try {
      final lichSu = List<ChatTinNhan>.from(_tinNhan)..removeLast();
      final slice =
      lichSu.length > 10 ? lichSu.sublist(lichSu.length - 10) : lichSu;
      final traLoi = await ChatbotService.instance.guiTinNhan(
        cauHoi: text,
        lichSu: slice,
      );
      if (!mounted) return;
      setState(() {
        _tinNhan.add(ChatTinNhan(role: 'assistant', content: traLoi));
        _dangGui = false;
      });
      _scrollCuoi();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _tinNhan.add(ChatTinNhan(
            role: 'assistant', content: 'Xin lỗi nhé — ${e.message}'));
        _dangGui = false;
      });
      _scrollCuoi();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tinNhan.add(
            ChatTinNhan(role: 'assistant', content: 'Xin lỗi, có lỗi: $e'));
        _dangGui = false;
      });
      _scrollCuoi();
    }
  }

  void _scrollCuoi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  List<String> get _goiY {
    switch (widget.vaiTro) {
      case 'Tổ trưởng cơ điện':
      case 'Tổ trưởng kỹ thuật':
        return [
          'Có bao nhiêu hồ sơ bảo trì đang chờ?',
          'Ngày bảo trì sắp tới là khi nào?',
          'Cách phân công NVKT?',
        ];
      case 'Xưởng':
      case 'Tổ trưởng sản xuất':
        return [
          'Hồ sơ chờ duyệt còn bao nhiêu?',
          'Chốt ngày bảo trì thế nào?',
          'Tổng tiền vật tư tháng này?',
        ];
      case 'Giám đốc':
        return [
          'Tổng tiền vật tư năm nay?',
          'Có bao nhiêu hồ sơ chờ duyệt?',
          'Thống kê bảo trì tháng này?',
        ];
      case 'Nhân viên kỹ thuật':
        return [
          'Làm quy trình bước nào trước?',
          'Chọn vật tư ra sao?',
          'Gửi xưởng xác nhận?',
        ];
      default:
        return ['Số hồ sơ bảo trì?', 'Tổng tiền vật tư?'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC), Color(0xFFF0FDF4)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            if (_ollamaOnline != null) _statusBar(),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                itemCount: _tinNhan.length + (_dangGui ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_dangGui && i == _tinNhan.length) {
                    return const _WaitingEffect();
                  }
                  return _Bubble(msg: _tinNhan[i], index: i);
                },
              ),
            ),
            if (!_dangGui && _tinNhan.length <= 3) _chipsGoiY(),
            _buildInput(bottom),
          ],
        ),
      ),
    );
  }

  Widget _statusBar() {
    final on = _ollamaOnline!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: on ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              boxShadow: [
                BoxShadow(
                  color: (on ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      .withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              on
                  ? 'AI local · ${_model ?? "Ollama"} · số liệu realtime · 0 token'
                  : 'AI local offline — bật Ollama trên máy API',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: on ? const Color(0xFF065F46) : const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipsGoiY() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final g in _goiY)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(Icons.auto_awesome,
                    size: 16, color: AppColors.primary),
                label: Text(g,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
                backgroundColor: Colors.white,
                elevation: 1,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2)),
                onPressed: () {
                  _ctrl.text = g;
                  _gui();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.paddingOf(context).top + 6,
        16,
        18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0EA5E9), Color(0xFF0068A9), Color(0xFF004E80)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0068A9).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFBAE6FD), Color(0xFF0284C7)],
              ),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.health_and_safety_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OPC Bot',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Dược OPC · Bảo trì cơ điện · ${widget.vaiTro}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(double bottom) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottom),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _gui(),
              decoration: InputDecoration(
                hintText: 'Hỏi số liệu, ngày BT, tổng tiền…',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: _dangGui
                  ? const LinearGradient(
                  colors: [Color(0xFF94A3B8), Color(0xFF64748B)])
                  : const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0068A9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _dangGui ? null : _gui,
                borderRadius: BorderRadius.circular(18),
                child: Center(
                  child: _dangGui
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatTinNhan msg;
  final int index;
  const _Bubble({required this.msg, required this.index});

  @override
  Widget build(BuildContext context) {
    final bot = msg.laBot;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: Align(
        alignment: bot ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.84,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: bot
                ? null
                : const LinearGradient(
              colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
            ),
            color: bot ? Colors.white : null,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(bot ? 6 : 20),
              bottomRight: Radius.circular(bot ? 20 : 6),
            ),
            boxShadow: [
              BoxShadow(
                color: (bot ? Colors.black : const Color(0xFF0284C7))
                    .withValues(alpha: bot ? 0.06 : 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: bot ? Border.all(color: const Color(0xFFE2E8F0)) : null,
          ),
          child: Text(
            msg.content.replaceAll('**', ''),
            style: TextStyle(
              color: bot ? const Color(0xFF0F172A) : Colors.white,
              height: 1.45,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hiệu ứng chờ phản hồi — sóng + chấm nhảy + chữ.
class _WaitingEffect extends StatefulWidget {
  const _WaitingEffect();

  @override
  State<_WaitingEffect> createState() => _WaitingEffectState();
}

class _WaitingEffectState extends State<_WaitingEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0F2FE)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CustomPaint(
                    painter: _WavePainter(progress: _c.value),
                  ),
                ),
                const SizedBox(width: 10),
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Transform.translate(
                    offset: Offset(
                      0,
                      -6 * math.sin((_c.value * math.pi * 2) + i * 0.9),
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color.lerp(
                              const Color(0xFF7DD3FC),
                              const Color(0xFF0369A1),
                              ((math.sin(_c.value * math.pi * 2 + i) + 1) / 2),
                            )!,
                            const Color(0xFF0EA5E9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Text(
                  'OPC Bot đang soạn…',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.7);
    final path = Path();
    for (var x = 0.0; x <= size.width; x++) {
      final y = size.height / 2 +
          math.sin((x / size.width * 3 + progress * 4) * math.pi) * 6;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.progress != progress;
}