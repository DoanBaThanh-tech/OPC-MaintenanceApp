part of technician_screens;

// ============ QUẢN LÝ YÊU CẦU (NVKT) — UI hiện đại, responsive ============

class QuanLyYeuCauScreen extends StatefulWidget {
  const QuanLyYeuCauScreen({super.key});

  @override
  State<QuanLyYeuCauScreen> createState() => _QuanLyYeuCauScreenState();
}

class _QuanLyYeuCauScreenState extends State<QuanLyYeuCauScreen>
    with TickerProviderStateMixin {
  static const _blue = Color(0xFF0068A9);
  static const _blueDark = Color(0xFF004E80);
  static const _bg = Color(0xFFF0F5FA);

  final _ctrl = QuanLyYeuCauController();
  late TabController _tabCtrl;
  late AnimationController _enterCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _ctrl.doiTab(_tabCtrl.index == 0 ? 'Bảo trì' : 'Sửa chữa');
      }
    });
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _moChiTiet(YeuCauPhanCong y) async {
    final changed = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, a, __) => ChiTietYeuCauScreen(yeuCau: y),
        transitionsBuilder: (_, a, __, child) {
          final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.02),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    if (changed == true) _ctrl.tai();
  }

  double _hPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 900) return 28;
    if (w >= 600) return 22;
    return 16;
  }

  int _crossAxis(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1100) return 3;
    if (w >= 700) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final hPad = _hPad(context);
    final fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(fade);

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(hPad, top + 10, hPad, 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_blue, _blueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, child) {
                            final s = 1 + 0.03 * _pulseCtrl.value;
                            return Transform.scale(scale: s, child: child);
                          },
                          child: Container(
                            width: 46,
                            height: 46,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/logo_opc_icon.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.engineering_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Yêu cầu công việc',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 21,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _ctrl.dangTai
                                    ? 'Đang tải…'
                                    : '${_ctrl.danhSach.length} yêu cầu · ${_ctrl.tabLoai}',
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
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _ctrl.tai();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: _blueDark,
                        unselectedLabelColor:
                        Colors.white.withValues(alpha: 0.9),
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5),
                        unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.5),
                        tabs: const [
                          Tab(text: 'Bảo trì'),
                          Tab(text: 'Sửa chữa'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _ctrl.dangTai
                ? const Center(
              child: CircularProgressIndicator(
                  color: _blue, strokeWidth: 2.8),
            )
                : _ctrl.loi != null
                ? Center(
              child: Padding(
                padding: EdgeInsets.all(hPad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.cloud_off_rounded,
                          size: 40,
                          color: AppColors.danger
                              .withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: 14),
                    Text(_ctrl.loi!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _ctrl.tai,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _ctrl.tai,
              color: _blue,
              child: _buildList(context, hPad),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, double hPad) {
    final canLam = _ctrl.canThucHien;
    final hoTro = _ctrl.chiXemHoTro;
    final choXn = _ctrl.choXacNhanKetQua;
    final xong = _ctrl.daHoanThanh;
    final huy = _ctrl.danhSach
        .where((e) =>
    e.daHuy &&
        !e.choXacNhanKetQua &&
        !e.daHoanThanhPc &&
        !e.canThucHien)
        .toList();

    if (canLam.isEmpty &&
        hoTro.isEmpty &&
        choXn.isEmpty &&
        xong.isEmpty &&
        huy.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 480),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.86 + 0.14 * t, child: child),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.inbox_outlined,
                      size: 52, color: _blue.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 14),
                Text(
                  'Chưa có yêu cầu ${_ctrl.tabLoai.toLowerCase()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Khi được phân công, yêu cầu sẽ hiện tại đây',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final sections = <_SectionData>[
      if (canLam.isNotEmpty)
        _SectionData('Cần thực hiện', canLam, const Color(0xFFD97706),
            Icons.play_circle_outline_rounded),
      if (hoTro.isNotEmpty)
        _SectionData('Hỗ trợ (chỉ xem)', hoTro, const Color(0xFF64748B),
            Icons.visibility_outlined),
      if (choXn.isNotEmpty)
        _SectionData('Chờ xác nhận', choXn, const Color(0xFF0284C7),
            Icons.hourglass_top_rounded),
      if (xong.isNotEmpty)
        _SectionData(
            'Xác nhận', xong, const Color(0xFF059669), Icons.verified_rounded),
      if (huy.isNotEmpty)
        _SectionData(
            'Đã hủy', huy, const Color(0xFF94A3B8), Icons.cancel_outlined),
    ];

    final cols = _crossAxis(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
      children: [
        for (final s in sections) ...[
          _sectionHeader(s.title, s.items.length, s.color, s.icon),
          const SizedBox(height: 10),
          if (cols == 1)
            ...s.items.asMap().entries.map(
                  (e) => _YeuCauCardModern(
                yeuCau: e.value,
                index: e.key,
                onTap: () => _moChiTiet(e.value),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final gap = 12.0;
                final w = (c.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: s.items.asMap().entries.map((e) {
                    return SizedBox(
                      width: w,
                      child: _YeuCauCardModern(
                        yeuCau: e.value,
                        index: e.key,
                        onTap: () => _moChiTiet(e.value),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _sectionHeader(
      String title, int count, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionData {
  final String title;
  final List<YeuCauPhanCong> items;
  final Color color;
  final IconData icon;
  _SectionData(this.title, this.items, this.color, this.icon);
}

class _YeuCauCardModern extends StatefulWidget {
  final YeuCauPhanCong yeuCau;
  final int index;
  final VoidCallback onTap;

  const _YeuCauCardModern({
    required this.yeuCau,
    required this.index,
    required this.onTap,
  });

  @override
  State<_YeuCauCardModern> createState() => _YeuCauCardModernState();
}

class _YeuCauCardModernState extends State<_YeuCauCardModern>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF0068A9);
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 360 + (widget.index % 6) * 40),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(_fade);
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _statusColor(YeuCauPhanCong y) {
    if (y.daHuy) return const Color(0xFF94A3B8);
    if (y.daHoanThanhPc) return const Color(0xFF059669);
    if (y.choXacNhanKetQua) return const Color(0xFF0284C7);
    if (y.canThucHien) return const Color(0xFFD97706);
    if (y.chiXem) return const Color(0xFF64748B);
    return _blue;
  }

  String _statusLabel(YeuCauPhanCong y) {
    if (y.daHuy) return 'Đã hủy';
    if (y.daHoanThanhPc) return 'Xác nhận';
    if (y.choXacNhanKetQua) return 'Chờ xác nhận';
    if (y.biTuChoi && y.laNguoiGhiChep) return 'Cập nhật lại';
    if (y.canThucHien) return 'Cần thực hiện';
    if (y.chiXem) return 'Chỉ xem';
    return y.trangThaiPhanCong;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final y = widget.yeuCau;
    final c = _statusColor(y);
    final label = _statusLabel(y);
    final isBt = y.laBaoTri;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap();
              },
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8EEF4)),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 14,
                      bottom: 14,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      c.withValues(alpha: 0.16),
                                      c.withValues(alpha: 0.06),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isBt
                                      ? Icons.precision_manufacturing_rounded
                                      : Icons.handyman_rounded,
                                  color: c,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      y.tenThietBi ??
                                          'Thiết bị #${y.maHoSo ?? ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        height: 1.25,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isBt ? 'Bảo trì' : 'Sửa chữa',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: c.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: c,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if ((y.noiDung ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              y.noiDung!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13.2,
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F8FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline_rounded,
                                    size: 15, color: Colors.grey.shade500),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    y.tenNhanVienPhanCong ?? '—',
                                    style: TextStyle(
                                      fontSize: 12.2,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  y.ngayDuKienBaoTri != null
                                      ? Icons.event_outlined
                                      : Icons.calendar_today_outlined,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _fmt(y.ngayDuKienBaoTri ?? y.ngayPhanCong),
                                  style: TextStyle(
                                    fontSize: 12.2,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded,
                                    size: 18, color: Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}