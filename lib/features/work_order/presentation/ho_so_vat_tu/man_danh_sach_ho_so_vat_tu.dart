part of ho_so_vat_tu_screens;

/// Danh sách hồ sơ vật tư — Tổ trưởng cơ điện / Giám đốc.
class HoSoVatTuListScreen extends StatefulWidget {
  /// true: Giám đốc chỉ xem hồ sơ đã gửi
  final bool chiXemDaGui;

  const HoSoVatTuListScreen({super.key, this.chiXemDaGui = false});

  @override
  State<HoSoVatTuListScreen> createState() => _HoSoVatTuListScreenState();
}

class _HoSoVatTuListScreenState extends State<HoSoVatTuListScreen>
    with SingleTickerProviderStateMixin {
  List<HoSoVatTuItem> _all = [];
  bool _dangTai = true;
  String? _loi;
  late final AnimationController _headerAnim;

  /// Tổ trưởng chỉ theo dõi: Chờ duyệt (đã gửi GĐ) | Xác nhận — không còn tab Chờ gửi
  /// (Xưởng xác nhận quy trình → HS vật tư gửi thẳng Giám đốc).
  static const _tabsTt = ['Chờ duyệt', 'Xác nhận'];
  String _tab = 'Chờ duyệt';

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    if (widget.chiXemDaGui) _tab = 'Chờ duyệt';
    _tai();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final all = await MaterialUsageService.layDanhSachHoSoVatTu();
      setState(() {
        _all = all;
        _dangTai = false;
      });
    } catch (e) {
      setState(() {
        _loi = e is ApiException ? e.message : '$e';
        _dangTai = false;
        _all = [];
      });
    }
  }

  List<HoSoVatTuItem> get _list {
    if (widget.chiXemDaGui) {
      // GĐ: hồ sơ đã gửi (Chờ duyệt / Xác nhận)
      final gui = _all.where((e) => e.daGuiGiamDoc).toList();
      if (_tab == 'Xác nhận') return gui.where((e) => e.daXacNhan).toList();
      if (_tab == 'Chờ duyệt') return gui.where((e) => e.choDuyet).toList();
      return gui;
    }
    switch (_tab) {
      case 'Xác nhận':
        return _all.where((e) => e.daXacNhan).toList();
      case 'Chờ duyệt':
      default:
      // Gồm cả bản ghi cũ còn "Chờ gửi" (sẽ được API đẩy sang Chờ duyệt)
        return _all.where((e) => e.choDuyet || e.choGui).toList();
    }
  }

  String _nhanHienThi(String tt) {
    if (tt == 'Đã gửi GĐ') return 'Chờ duyệt';
    if (tt == 'Đã xem') return 'Xác nhận';
    return tt;
  }

  String _fmtDt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTien(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₫';
  }

  Color _mauTrangThai(String tt) {
    final n = _nhanHienThi(tt);
    if (n == 'Xác nhận') return AppColors.success;
    if (n == 'Chờ duyệt') return const Color(0xFF2563EB);
    return const Color(0xFFD97706); // Chờ gửi
  }

  Future<void> _moChiTiet(HoSoVatTuItem item) async {
    HapticFeedback.lightImpact();
    final changed = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, a, __) => HoSoVatTuDetailScreen(
          maHoSoVatTu: item.maHoSoVatTu,
          // TT không gửi GĐ; chỉ GĐ xác nhận — Xưởng XN quy trình đã gửi thẳng GĐ
          choPhepGuiGiamDoc: false,
          choPhepXacNhan: widget.chiXemDaGui,
        ),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
      ),
    );
    if (changed == true) _tai();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final tabs = widget.chiXemDaGui
        ? const ['Chờ duyệt', 'Xác nhận']
        : _tabsTt;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
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
                padding: EdgeInsets.fromLTRB(12, top + 8, 12, 0),
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
                        if (widget.chiXemDaGui)
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
                          child: const Icon(Icons.inventory_2_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.chiXemDaGui
                                    ? 'Duyệt hồ sơ vật tư'
                                    : 'Hồ sơ vật tư',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _dangTai
                                    ? 'Đang tải…'
                                    : '${_list.length} hồ sơ · $_tab',
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
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _tai,
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
                        itemCount: tabs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final tab = tabs[i];
                          final selected = _tab == tab;
                          final count = () {
                            if (tab == 'Chờ duyệt') {
                              return widget.chiXemDaGui
                                  ? _all
                                  .where((e) => e.daGuiGiamDoc && e.choDuyet)
                                  .length
                                  : _all
                                  .where((e) => e.choDuyet || e.choGui)
                                  .length;
                            }
                            return widget.chiXemDaGui
                                ? _all
                                .where((e) => e.daGuiGiamDoc && e.daXacNhan)
                                .length
                                : _all.where((e) => e.daXacNhan).length;
                          }();
                          return GestureDetector(
                            onTap: () => setState(() => _tab = tab),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
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
                                    tab,
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
          Expanded(
            child: _dangTai
                ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF0068A9), strokeWidth: 3),
            )
                : _loi != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.danger
                            .withValues(alpha: 0.7)),
                    const SizedBox(height: 12),
                    Text(_loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _tai,
                      style: FilledButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF0068A9)),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _tai,
              color: const Color(0xFF0068A9),
              child: _list.isEmpty
                  ? ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                      height: MediaQuery.of(context)
                          .size
                          .height *
                          0.2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(
                        milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, t, child) =>
                        Transform.scale(
                          scale: 0.7 + 0.3 * t,
                          child: Opacity(
                              opacity: t, child: child),
                        ),
                    child: Column(
                      children: [
                        Container(
                          padding:
                          const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE8F4FC),
                                const Color(0xFF0068A9)
                                    .withValues(
                                    alpha: 0.12),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Color(0xFF0068A9)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có hồ sơ · $_tab',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                physics:
                const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(
                    14, 14, 14, 28),
                itemCount: _list.length,
                itemBuilder: (context, i) {
                  final item = _list[i];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(
                        milliseconds:
                        280 + (i % 6) * 40),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) =>
                        Opacity(
                          opacity: v,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - v)),
                            child: child,
                          ),
                        ),
                    child: _card(item, i),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(HoSoVatTuItem item, int index) {
    final mau = _mauTrangThai(item.trangThai);
    final nhan = _nhanHienThi(item.trangThai);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index.clamp(0, 8) * 45)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        final v = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - v)),
            child: Transform.scale(scale: 0.96 + 0.04 * v, child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _moChiTiet(item),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: mau, width: 4),
                  top: const BorderSide(color: Color(0xFFE2E8F0)),
                  right: const BorderSide(color: Color(0xFFE2E8F0)),
                  bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: mau.withValues(alpha: 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
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
                              mau.withValues(alpha: 0.18),
                              const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.loaiCongViec == 'Bảo trì'
                              ? Icons.inventory_2_outlined
                              : Icons.handyman_outlined,
                          color: mau,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.tenThietBi,
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
                              'HS #${item.maHoSoVatTu} · ${_fmtDt(item.ngayThucHien)}',
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
                          color: mau.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: mau.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          nhan,
                          style: TextStyle(
                            color: mau,
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
                        Text(
                          '${item.loaiCongViec} · ${_fmtTien(item.tongTien)}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vật tư: ${item.chiTiet.map((c) => c.tenVatTu).where((t) => t.isNotEmpty).join(', ')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
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
    );
  }
}
