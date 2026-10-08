part of approval_screens;

// ============ MÀN 1: DANH SÁCH HỒ SƠ BẢO TRÌ (UI = Hồ sơ BT Xưởng) ============

class ApprovalBaoTriListScreen extends StatefulWidget {
  const ApprovalBaoTriListScreen({super.key});
  @override
  State<ApprovalBaoTriListScreen> createState() =>
      _ApprovalBaoTriListScreenState();
}

class _ApprovalBaoTriListScreenState extends State<ApprovalBaoTriListScreen>
    with TickerProviderStateMixin {
  final _controller = ApprovalBaoTriListController();
  late TabController _tab;
  late AnimationController _headerAnim;

  final _tabs = const [
    'Tất cả',
    'Chờ duyệt',
    'Đang thực hiện',
    'Đã hoàn thành',
    'Từ chối',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.taiDanhSachChoDuyet();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _tab.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  List<HoSoBaoTriDuyet> _locTab(String tab) {
    final all = _controller.danhSach;
    switch (tab) {
      case 'Chờ duyệt':
        return all.where((h) => h.choDuyet).toList();
      case 'Đang thực hiện':
        return all.where((h) => h.dangThucHien).toList();
      case 'Đã hoàn thành':
        return all.where((h) => h.daHoanThanh).toList();
      case 'Từ chối':
        return all.where((h) => h.biTuChoi).toList();
      default:
        return all;
    }
  }

  Color _mau(String tt) => _GdUi.mauTrangThai(tt);

  IconData _icon(String tt) {
    switch (tt) {
      case 'Đã duyệt':
        return Icons.verified_outlined;
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return Icons.engineering_outlined;
      case 'Đã hoàn thành':
        return Icons.task_alt_rounded;
      case 'Từ chối':
        return Icons.cancel_outlined;
      case 'Chờ duyệt':
      case 'Chờ GĐ duyệt':
        return Icons.schedule_rounded;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LichSuPheDuyetScreen()),
          );
        },
        backgroundColor: const Color(0xFF0068A9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.history_rounded),
        label: const Text(
          'Lịch sử phê duyệt',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12, top + 10, 12, 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0068A9),
                      Color(0xFF0284C7),
                      Color(0xFF0EA5E9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0068A9).withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: const Icon(Icons.build_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Duyệt hồ sơ bảo trì',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _controller.dangTai
                                    ? 'Đang tải…'
                                    : '${_locTab('Tất cả').length} hồ sơ'
                                    '${_controller.namLoc != null ? ' · ${_controller.namLoc}' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: PopupMenuButton<int>(
                            tooltip: 'Lọc năm',
                            offset: const Offset(0, 44),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            onSelected: (v) =>
                                _controller.datNamLoc(v == -1 ? null : v),
                            itemBuilder: (ctx) {
                              final nams = _controller.cacNamCoDuLieu;
                              return [
                                const PopupMenuItem(
                                    value: -1, child: Text('Tất cả năm')),
                                ...nams.map((n) => PopupMenuItem(
                                    value: n, child: Text('Năm $n'))),
                              ];
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Badge(
                                isLabelVisible: _controller.namLoc != null,
                                label: Text('${_controller.namLoc}',
                                    style: const TextStyle(fontSize: 9)),
                                child: const Icon(Icons.filter_list_rounded,
                                    color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _controller.taiDanhSachChoDuyet,
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tabs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final selected = _tab.index == i;
                          final count = _locTab(_tabs[i]).length;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _tab.animateTo(i));
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                                ),
                                boxShadow: selected
                                    ? [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _tabs[i],
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF0369A1)
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF0EA5E9)
                                          .withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF0369A1)
                                            : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.dangTai) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                  color: Color(0xFF0068A9), strokeWidth: 3),
            ),
            SizedBox(height: 14),
            Text('Đang tải hồ sơ…',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (_controller.loi != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_controller.loi!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _controller.taiDanhSachChoDuyet,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0068A9)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tab,
      children: _tabs.map((tab) {
        final list = _locTab(tab);
        if (list.isEmpty) {
          return RefreshIndicator(
            color: const Color(0xFF0068A9),
            onRefresh: _controller.taiDanhSachChoDuyet,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Transform.scale(
                    scale: 0.7 + 0.3 * t,
                    child: Opacity(opacity: t, child: child),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE8F4FC),
                              const Color(0xFF0068A9).withValues(alpha: 0.12),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inbox_outlined,
                            size: 48, color: Color(0xFF0068A9)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có hồ sơ · $tab',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: const Color(0xFF0068A9),
          onRefresh: _controller.taiDanhSachChoDuyet,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final hs = list[i];
              final mau = _mau(hs.trangThai);
              return _GdHsCard(
                index: i,
                tenThietBi: hs.tenThietBi,
                maHoSo: hs.maHoSoBaoTri,
                ngayTao: _fmt(hs.ngayTao),
                ngayDuKien: hs.ngayDuKienBaoTri != null
                    ? _fmt(hs.ngayDuKienBaoTri!)
                    : null,
                noiDung: hs.noiDungCongViec,
                subLine:
                'Người lập: ${hs.tenNguoiLap ?? '—'} · KH ${hs.nam}${hs.namTuKeHoach ? '' : ' · đột xuất'}',
                trangThai: hs.trangThai,
                mau: mau,
                icon: _icon(hs.trangThai),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final changed = await Navigator.push<bool>(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 320),
                      pageBuilder: (_, a, __) => ApprovalBaoTriDetailScreen(
                          maHoSoBaoTri: hs.maHoSoBaoTri),
                      transitionsBuilder: (_, a, __, child) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: a, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                    ),
                  );
                  if (changed == true) _controller.taiDanhSachChoDuyet();
                },
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

/// Thẻ hồ sơ — copy hiệu ứng _HsCard trang Hồ sơ bảo trì Xưởng.
class _GdHsCard extends StatefulWidget {
  final int index;
  final String tenThietBi;
  final int maHoSo;
  final String ngayTao;
  final String? ngayDuKien;
  final String? noiDung;
  final String subLine;
  final String trangThai;
  final Color mau;
  final IconData icon;
  final VoidCallback onTap;

  const _GdHsCard({
    required this.index,
    required this.tenThietBi,
    required this.maHoSo,
    required this.ngayTao,
    this.ngayDuKien,
    this.noiDung,
    required this.subLine,
    required this.trangThai,
    required this.mau,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GdHsCard> createState() => _GdHsCardState();
}

class _GdHsCardState extends State<_GdHsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _enter;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 320 + (widget.index.clamp(0, 8) * 45)),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _enter,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_enter.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - t)),
            child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              transform: Matrix4.identity()..scale(_pressed ? 0.985 : 1.0),
              transformAlignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: widget.mau, width: 4),
                  top: const BorderSide(color: Color(0xFFE2E8F0)),
                  right: const BorderSide(color: Color(0xFFE2E8F0)),
                  bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.mau.withValues(alpha: _pressed ? 0.06 : 0.1),
                    blurRadius: _pressed ? 8 : 14,
                    offset: Offset(0, _pressed ? 2 : 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.mau.withValues(alpha: 0.18),
                              const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon, color: widget.mau, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tenThietBi,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'HS #${widget.maHoSo} · ${widget.ngayTao}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.mau.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: widget.mau.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          widget.trangThai,
                          style: TextStyle(
                            color: widget.mau,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.ngayDuKien != null)
                          Row(
                            children: [
                              const Icon(Icons.event_available_rounded,
                                  size: 15, color: Color(0xFF0068A9)),
                              const SizedBox(width: 6),
                              Text(
                                'Dự kiến: ${widget.ngayDuKien}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        if (widget.ngayDuKien != null) const SizedBox(height: 6),
                        Text(
                          widget.subLine,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (widget.noiDung != null &&
                            widget.noiDung!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.noiDung!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}