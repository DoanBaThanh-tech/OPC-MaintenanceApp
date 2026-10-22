import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/chatbot_service.dart';

/// Màn chatbot AI — chào theo tên, khóa phạm vi theo vai trò.
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

class _ManChatbotScreenState extends State<ManChatbotScreen>
    with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _tinNhan = <ChatTinNhan>[];
  bool _dangGui = false;
  bool? _ollamaOnline;
  String? _model;

  late final AnimationController _headerAnim;

  String get _tenChao {
    final t = widget.hoTen.trim();
    if (t.isEmpty) return 'bạn';
    final parts = t.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : t;
  }

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loiChaoVaKiemTra();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _loiChaoVaKiemTra() async {
    final chao = ChatTinNhan(
      role: 'assistant',
      content:
      'Xin chào $_tenChao! 👋\n\n'
          'Mình là **OPC Bot** — trợ lý AI cho vai trò **${widget.vaiTro}**.\n'
          'Mình chỉ hỗ trợ công việc thuộc vai trò này trong app bảo trì–sửa chữa OPC.\n\n'
          'Bạn cần mình giúp gì hôm nay?',
    );
    setState(() => _tinNhan.add(chao));

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
            '⚠️ AI local chưa sẵn sàng.\n'
                '${st.message ?? "Hãy cài Ollama, chạy model, rồi thử lại."}',
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
          '⚠️ Không kiểm tra được AI local. Kiểm tra API/ngrok và Ollama trên máy server.',
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
      final lichSu = _tinNhan
          .where((e) => e.content.isNotEmpty)
          .toList()
        ..removeLast(); // câu vừa gửi sẽ nằm trong cauHoi
      final traLoi = await ChatbotService.instance.guiTinNhan(
        cauHoi: text,
        lichSu: lichSu.length > 12 ? lichSu.sublist(lichSu.length - 12) : lichSu,
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
          role: 'assistant',
          content: '❌ ${e.message}',
        ));
        _dangGui = false;
      });
      _scrollCuoi();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tinNhan.add(ChatTinNhan(
          role: 'assistant',
          content: '❌ $e',
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

  List<String> get _goiY {
    switch (widget.vaiTro) {
      case 'Tổ trưởng cơ điện':
      case 'Tổ trưởng kỹ thuật':
        return [
          'Cách tạo hồ sơ bảo trì?',
          'Khi nào được tạo sửa chữa?',
          'Phân công NVKT thế nào?',
        ];
      case 'Xưởng':
      case 'Tổ trưởng sản xuất':
        return [
          'Chốt ngày bảo trì ra sao?',
          'Xác nhận quy trình NVKT?',
          'GĐ từ chối thì làm gì?',
        ];
      case 'Giám đốc':
        return [
          'Duyệt hồ sơ bảo trì?',
          'Xem thống kê ở đâu?',
          'Từ chối hồ sơ khi nào?',
        ];
      case 'Nhân viên kỹ thuật':
        return [
          'Làm quy trình bước nào?',
          'Chọn vật tư thế nào?',
          'Gửi xưởng xác nhận?',
        ];
      default:
        return ['App dùng để làm gì?', 'Vai trò của tôi làm gì?'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FC),
      body: Column(
        children: [
          _buildHeader(),
          if (_ollamaOnline != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: _ollamaOnline!
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              child: Row(
                children: [
                  Icon(
                    _ollamaOnline!
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    size: 16,
                    color: _ollamaOnline!
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _ollamaOnline!
                          ? 'AI local · ${_model ?? "Ollama"} · không tốn token'
                          : 'AI local offline — bật Ollama trên máy API',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _ollamaOnline!
                            ? const Color(0xFF065F46)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              itemCount: _tinNhan.length + (_dangGui ? 1 : 0),
              itemBuilder: (context, i) {
                if (_dangGui && i == _tinNhan.length) {
                  return const _TypingBubble();
                }
                return _Bubble(msg: _tinNhan[i]);
              },
            ),
          ),
          if (!_dangGui && _tinNhan.length <= 2)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final g in _goiY)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(g, style: const TextStyle(fontSize: 12.5)),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                        onPressed: () {
                          _ctrl.text = g;
                          _gui();
                        },
                      ),
                    ),
                ],
              ),
            ),
          _buildInput(bottom),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 8,
        16,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0077B8), Color(0xFF004E80)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.smart_toy_rounded,
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
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Hỗ trợ · ${widget.vaiTro}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
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
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _gui(),
              decoration: InputDecoration(
                hintText: 'Hỏi OPC Bot theo vai trò của bạn…',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
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

class _Bubble extends StatelessWidget {
  final ChatTinNhan msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final bot = msg.laBot;
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
            colors: [Color(0xFF0068A9), Color(0xFF0EA5E9)],
          ),
          color: bot ? Colors.white : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(bot ? 6 : 18),
            bottomRight: Radius.circular(bot ? 18 : 6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: bot
              ? Border.all(color: const Color(0xFFE2E8F0))
              : null,
        ),
        child: Text(
          msg.content.replaceAll('**', ''),
          style: TextStyle(
            color: bot ? const Color(0xFF0F172A) : Colors.white,
            height: 1.4,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        ),
      ),
    );
  }

  Widget _dot(int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1),
      duration: Duration(milliseconds: 400 + i * 120),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF0068A9),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}