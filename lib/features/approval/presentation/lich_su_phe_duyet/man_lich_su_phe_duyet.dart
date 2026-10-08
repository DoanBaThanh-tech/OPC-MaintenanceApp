part of approval_screens;

// ============ LỊCH SỬ PHÊ DUYỆT (Giám đốc) — chỉ Bảo trì ============

class LichSuPheDuyetScreen extends StatefulWidget {
  const LichSuPheDuyetScreen({super.key});

  @override
  State<LichSuPheDuyetScreen> createState() => _LichSuPheDuyetScreenState();
}

class _LichSuPheDuyetScreenState extends State<LichSuPheDuyetScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = LichSuPheDuyetController();
  late final AnimationController _headerAnim;
  int _filter = 0; // 0 tất cả · 1 đã duyệt · 2 từ chối

  static const _filters = ['Tất cả', 'Đã duyệt', 'Từ chối'];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _ctrl.tabLoai = 'Bảo trì';
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _fmtNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtGio(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  List<LichSuPheDuyetItem> get _list {
    final all = _ctrl.danhSach;
    if (_filter == 1) return all.where((e) => e.daDuyet).toList();
    if (_filter == 2) return all.where((e) => e.tuChoi).toList();
    return all;
  }

  int _count(int i) {
    final all = _ctrl.danhSach;
    if (i == 1) return all.where((e) => e.daDuyet).length;
    if (i == 2) return all.where((e) => e.tuChoi).length;
    return all.length;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

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
                          child: const Icon(Icons.history_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lịch sử phê duyệt',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 19,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _ctrl.dangTai
                                    ? 'Đang tải…'
                                    : '${_ctrl.danhSach.length} bản ghi bảo trì'
                                    '${_ctrl.namLoc != null ? ' · ${_ctrl.namLoc}' : ''}',
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
                            onTap: _ctrl.tai,
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
                    // Chip: Tất cả / Đã duyệt / Từ chối
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final selected = _filter == i;
                          return GestureDetector(
                            onTap: () => setState(() => _filter = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
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
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _filters[i],
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF0369A1)
                                          : Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_count(i)}',
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF0369A1)
                                          : Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Lọc năm
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _yearChip('Tất cả năm', null),
                          ..._ctrl.cacNam.map((y) => _yearChip('$y', y)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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

  Widget _yearChip(String label, int? value) {
    final selected = _ctrl.namLoc == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _ctrl.datNam(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF0369A1) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.dangTai) {
      return const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF0068A9), strokeWidth: 3),
      );
    }
    if (_ctrl.loi != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_ctrl.loi!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _ctrl.tai,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0068A9)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final list = _list;
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _ctrl.tai,
        color: const Color(0xFF0068A9),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),
            const Icon(Icons.history_toggle_off_rounded,
                size: 56, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử · ${_filters[_filter]}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    // Nhóm: Đã duyệt trước, Từ chối sau (khi xem Tất cả)
    final daDuyet = list.where((e) => e.daDuyet).toList();
    final tuChoi = list.where((e) => e.tuChoi).toList();

    return RefreshIndicator(
      onRefresh: _ctrl.tai,
      color: const Color(0xFF0068A9),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          if (_filter == 0 || _filter == 1) ...[
            if (daDuyet.isNotEmpty) ...[
              _sectionHeader(
                'Đã duyệt',
                daDuyet.length,
                const Color(0xFF0B6BCB),
                Icons.verified_rounded,
              ),
              ...daDuyet.asMap().entries.map(
                    (e) => _LichSuCard(
                  item: e.value,
                  index: e.key,
                  fmtNgay: _fmtNgay,
                  fmtGio: _fmtGio,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (_filter == 0 || _filter == 2) ...[
            if (tuChoi.isNotEmpty) ...[
              _sectionHeader(
                'Từ chối',
                tuChoi.length,
                const Color(0xFFDC2626),
                Icons.cancel_rounded,
              ),
              ...tuChoi.asMap().entries.map(
                    (e) => _LichSuCard(
                  item: e.value,
                  index: e.key,
                  fmtNgay: _fmtNgay,
                  fmtGio: _fmtGio,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(
      String title, int count, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LichSuCard extends StatelessWidget {
  final LichSuPheDuyetItem item;
  final int index;
  final String Function(DateTime) fmtNgay;
  final String Function(DateTime) fmtGio;

  const _LichSuCard({
    required this.item,
    required this.index,
    required this.fmtNgay,
    required this.fmtGio,
  });

  @override
  Widget build(BuildContext context) {
    final daDuyet = item.daDuyet;
    // Nền trung tính — chỉ badge màu trạng thái (không tô cả thẻ)
    final badgeColor =
    daDuyet ? const Color(0xFF0B6BCB) : const Color(0xFFDC2626);
    final nhan = daDuyet ? 'Đã duyệt' : 'Từ chối';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index % 6) * 40),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - v)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.tenThietBi ??
                                    'Hồ sơ #${item.maHoSo ?? '—'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                nhan,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'HS #${item.maHoSo ?? '—'} · ${fmtNgay(item.ngayDuyet)} ${fmtGio(item.ngayDuyet)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Người lập: ${item.tenNguoiLap ?? '—'}  ·  Duyệt: ${item.tenNguoiDuyet ?? '—'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (item.tuChoi &&
                            item.lyDo != null &&
                            item.lyDo!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Lý do: ${item.lyDo}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
