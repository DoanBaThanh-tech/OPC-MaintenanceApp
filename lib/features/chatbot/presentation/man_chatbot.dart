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
  bool? _online;
  String? _model;

  String get _tenChao {
    final t = widget.hoTen.trim();
    if (t.isEmpty) return 'bạn';
    final parts = t.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : t;
  }

  /// Tin hệ thống (lời chào / lỗi): hiển thị nhưng không gửi làm lịch sử hội thoại.
  ChatTinNhan _tinHeThong(String content) => ChatTinNhan(
    role: 'assistant',
    content: content,
    boQuaLichSu: true,
  );

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
      _tinNhan.add(_tinHeThong(
        'Chào $_tenChao! Mình là OPC Bot — chỉ hỗ trợ vai trò «${widget.vaiTro}».\n'
            'Hỏi số liệu/quy trình trong phạm vi của bạn. Nếu mình trả lời sai, bấm «Báo sai — kiểm tra lại» để mình đối chiếu lại ngay.',
      ));
    });
    try {
      final st = await ChatbotService.instance.kiemTra();
      if (!mounted) return;
      setState(() {
        _online = st.online;
        _model = st.model;
      });
      if (!st.online) {
        setState(() {
          _tinNhan.add(_tinHeThong(
            'Engine chatbot chưa sẵn sàng. Kiểm tra API đang chạy rồi hỏi lại nhé.',
          ));
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _online = false;
        _tinNhan.add(_tinHeThong(
          'Chưa kết nối được AI. Kiểm tra API/ngrok đang chạy.',
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
      // Lịch sử = các tin thật, bỏ tin hệ thống và bỏ câu hỏi vừa gửi
      final lichSu = _tinNhan.where((m) => !m.boQuaLichSu).toList()
        ..removeLast();
      final slice =
      lichSu.length > 8 ? lichSu.sublist(lichSu.length - 8) : lichSu;
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
        _tinNhan.add(_tinHeThong(e.message));
        _dangGui = false;
      });
      _scrollCuoi();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tinNhan.add(_tinHeThong(
          'Chưa nhận được phản hồi. Bạn thử lại sau ít giây nhé.',
        ));
        _dangGui = false;
      });
      _scrollCuoi();
    }
  }

  /// User bấm «Báo sai» trên 1 câu trả lời bot → API học lại theo dữ liệu app.
  Future<void> _baoSaiTai(int indexBot) async {
    if (_dangGui || indexBot < 0 || indexBot >= _tinNhan.length) return;
    final botMsg = _tinNhan[indexBot];
    if (!botMsg.laBot || botMsg.boQuaLichSu) return;

    // Tìm câu hỏi user ngay trước bubble bot này
    String? cauHoiGoc;
    for (var i = indexBot - 1; i >= 0; i--) {
      final m = _tinNhan[i];
      if (m.boQuaLichSu) continue;
      if (m.role == 'user') {
        cauHoiGoc = m.content;
        break;
      }
    }

    setState(() {
      _tinNhan.add(ChatTinNhan(
        role: 'user',
        content: 'Câu trả lời vừa rồi bị sai — hãy kiểm tra lại theo app.',
        boQuaLichSu: true, // không đưa vào lịch sử LLM như câu hỏi thường
      ));
      _dangGui = true;
    });
    _scrollCuoi();

    try {
      final lichSu = _tinNhan.where((m) => !m.boQuaLichSu).toList();
      final slice =
      lichSu.length > 8 ? lichSu.sublist(lichSu.length - 8) : lichSu;
      final traLoi = await ChatbotService.instance.guiTinNhan(
        cauHoi: 'Câu trả lời trước bị sai, hãy kiểm tra lại số liệu trên app.',
        lichSu: slice,
        baoSai: true,
        cauHoiGoc: cauHoiGoc,
        traLoiSai: botMsg.content,
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
        _tinNhan.add(_tinHeThong(e.message));
        _dangGui = false;
      });
      _scrollCuoi();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tinNhan.add(_tinHeThong(
          'Chưa kiểm tra lại được. Thử bấm Báo sai lần nữa sau vài giây.',
        ));
        _dangGui = false;
      });
      _scrollCuoi();
    }
  }

  void _scrollCuoi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
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
            colors: [
              Color(0xFF0C4A6E),
              Color(0xFF0369A1),
              Color(0xFFE0F2FE),
              Color(0xFFF8FAFC),
            ],
            stops: [0, 0.18, 0.45, 1],
          ),
        ),
        child: Column(
          children: [
            _header(),
            if (_online != null) _status(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                    itemCount: _tinNhan.length + (_dangGui ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_dangGui && i == _tinNhan.length) {
                        return const _Waiting();
                      }
                      final msg = _tinNhan[i];
                      final choBaoSai = msg.laBot &&
                          !msg.boQuaLichSu &&
                          !_dangGui &&
                          i == _tinNhan.lastIndexWhere(
                                  (m) => m.laBot && !m.boQuaLichSu);
                      return _Bubble(
                        msg: msg,
                        hienBaoSai: choBaoSai,
                        onBaoSai: choBaoSai ? () => _baoSaiTai(i) : null,
                      );
                    },
                  ),
                ),
              ),
            ),
            _input(bottom),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        6,
        MediaQuery.paddingOf(context).top + 4,
        14,
        12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 24),
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
                    fontSize: 18,
                  ),
                ),
                Text(
                  widget.vaiTro,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
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

  Widget _status() {
    final on = _online!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFFFEF2F2).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on
                ? Colors.white.withValues(alpha: 0.25)
                : const Color(0xFFFECACA),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? const Color(0xFF4ADE80) : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                on
                    ? 'OPC Bot · ${_model ?? "Groq+DB"} · realtime'
                    : 'OPC Bot offline',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : const Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(double bottom) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0369A1).withValues(alpha: 0.08),
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
              maxLength: 1000,
              buildCounter: (_,
                  {required currentLength,
                    required isFocused,
                    maxLength}) =>
              null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _gui(),
              decoration: InputDecoration(
                hintText: 'Hỏi OPC Bot…',
                filled: true,
                fillColor: const Color(0xFFF0F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
            child: InkWell(
              onTap: _dangGui ? null : _gui,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _dangGui
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Làm sạch markdown còn sót từ LLM để hiển thị dạng text thuần.
String _lamSachMarkdown(String s) {
  var t = s.replaceAll('**', '').replaceAll('`', '');
  t = t.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '');
  t = t.replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '• ');
  return t.trim();
}

class _Bubble extends StatefulWidget {
  final ChatTinNhan msg;
  final bool hienBaoSai;
  final VoidCallback? onBaoSai;

  const _Bubble({
    required this.msg,
    this.hienBaoSai = false,
    this.onBaoSai,
  });

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  static const int _maxDongRutGon = 5;
  bool _moRong = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.msg;
    final bot = msg.laBot;
    final full = _lamSachMarkdown(msg.content);
    final lines = full.split('\n');
    final quaDai = lines.length > _maxDongRutGon || full.length > 320;
    final hienThi = (!_moRong && quaDai)
        ? (lines.length > _maxDongRutGon
        ? '${lines.take(_maxDongRutGon).join('\n')}\n…'
        : '${full.substring(0, full.length.clamp(0, 280))}…')
        : full;

    return Align(
      alignment: bot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: bot
              ? null
              : const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
          ),
          color: bot ? const Color(0xFFF0F9FF) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(bot ? 6 : 18),
            bottomRight: Radius.circular(bot ? 18 : 6),
          ),
          border: bot ? Border.all(color: const Color(0xFFBAE6FD)) : null,
          boxShadow: [
            BoxShadow(
              color: (bot ? const Color(0xFF0369A1) : const Color(0xFF0284C7))
                  .withValues(alpha: bot ? 0.06 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              hienThi,
              style: TextStyle(
                color: bot ? const Color(0xFF0C4A6E) : Colors.white,
                height: 1.45,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (bot && quaDai) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _moRong = !_moRong),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _moRong
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _moRong ? 'Thu gọn' : 'Xem thêm',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (widget.hienBaoSai && widget.onBaoSai != null) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: widget.onBaoSai,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text(
                  'Báo sai — kiểm tra lại',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Waiting extends StatefulWidget {
  const _Waiting();
  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        builder: (_, _) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Transform.translate(
                    offset: Offset(
                      0,
                      -5 * math.sin((_c.value * math.pi * 2) + i * 0.85),
                    ),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Text(
                  'Đang trả lời…',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade600,
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