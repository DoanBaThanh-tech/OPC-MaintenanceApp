part of '../work_order_repair_screens.dart';

// ============ DANH SÁCH HỒ SƠ SỬA CHỮA ============

class WorkOrderSuaChuaListScreen extends StatefulWidget {
  final String? trangThaiMacDinh;
  final bool hienFabTao;

  const WorkOrderSuaChuaListScreen({
    super.key,
    this.trangThaiMacDinh,
    this.hienFabTao = false,
  });

  @override
  State<WorkOrderSuaChuaListScreen> createState() =>
      _WorkOrderSuaChuaListScreenState();
}

class _WorkOrderSuaChuaListScreenState extends State<WorkOrderSuaChuaListScreen>
    with TickerProviderStateMixin {
  late final WorkOrderSuaChuaListController _ctrl;
  late final AnimationController _headerAnim;
  late final TabController _tab;

  // Không hiện tab "Chờ xác nhận" trên Hồ sơ SC — map sang Đang thực hiện; quy trình xem trong chi tiết.
  static const _tabs = [
    'Tất cả',
    'Chờ phân công',
    'Đang thực hiện',
    'Đã hoàn thành',
  ];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _tab = TabController(length: _tabs.length, vsync: this);
    if (widget.trangThaiMacDinh != null) {
      final idx = _tabs.indexOf(widget.trangThaiMacDinh!);
      if (idx >= 0) _tab.index = idx;
    }
    _tab.addListener(() {
      if (!_tab.indexIsChanging && mounted) setState(() {});
    });
    _ctrl = WorkOrderSuaChuaListController(
        trangThaiMacDinh: widget.trangThaiMacDinh);
    _ctrl.addListener(_onCtrl);
    _ctrl.tai();
  }

  void _onCtrl() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrl);
    _ctrl.dispose();
    _headerAnim.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _tai() => _ctrl.tai();

  Color _mauTt(String tt) {
    switch (tt) {
      case 'Chờ phân công':
      case 'Đã duyệt':
        return const Color(0xFFF59E0B);
      case 'Đang thực hiện':
      case 'Chờ xác nhận': // dữ liệu cũ trên HS → coi như Đang thực hiện
        return _scPrimary;
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.blueGrey;
    }
  }

  String _tenTt(String tt) =>
      tt == 'Chờ xác nhận' ? 'Đang thực hiện' : tt;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _scBg,
      extendBodyBehindAppBar: false,
      floatingActionButton: widget.hienFabTao
          ? ScaleTransition(
        scale: CurvedAnimation(
            parent: _headerAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final ok = await Navigator.push<bool>(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 380),
                pageBuilder: (_, a, __) => const TaoHoSoSuaChuaScreen(),
                transitionsBuilder: (_, a, __, child) {
                  final curved =
                  CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
              ),
            );
            if (ok == true) _tai();
          },
          backgroundColor: _scPrimary,
          elevation: 8,
          highlightElevation: 12,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Tạo hồ sơ SC',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      )
          : null,
      body: Column(
        children: [
          // ===== Header gradient + TabBar (đồng bộ hồ sơ bảo trì) =====
          FadeTransition(
            opacity: _headerAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.15),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, top + 10, 12, 0),
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
                      color: _scPrimary.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28)),
                          ),
                          child: const Icon(Icons.handyman_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hồ sơ sửa chữa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _ctrl.dangTai
                                    ? 'Đang tải…'
                                    : '${_ctrl.danhSach.length} hồ sơ',
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
                        itemCount: _tabs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final selected = _tab.index == i;
                          final count = _ctrl.locTheoTab(_tabs[i]).length;
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
                                          : Colors.white
                                          .withValues(alpha: 0.2),
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

  Widget _buildBody() {
    if (_ctrl.dangTai) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                  color: _scPrimary, strokeWidth: 3),
            ),
            SizedBox(height: 14),
            Text('Đang tải hồ sơ…',
                style: TextStyle(
                    color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (_ctrl.loi != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded,
                    size: 36, color: AppColors.danger),
              ),
              const SizedBox(height: 14),
              Text(_ctrl.loi!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.4)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _tai,
                style: FilledButton.styleFrom(
                  backgroundColor: _scPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    final list = _ctrl.locTheoTab(_tabs[_tab.index]);
    return RefreshIndicator(
      color: _scPrimary,
      onRefresh: _tai,
      child: list.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        _scSoft,
                        _scPrimary.withValues(alpha: 0.12),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.handyman_outlined,
                      size: 48, color: _scPrimary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có hồ sơ sửa chữa',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.hienFabTao
                      ? 'Bấm + để tạo hồ sơ khi thiết bị hư đột ngột'
                      : 'Danh sách sẽ hiện khi có hồ sơ mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      )
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final hs = list[i];
          final c = _mauTt(hs.trangThai);
          final tenTt = _tenTt(hs.trangThai);
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 320 + i * 45),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 22 * (1 - t)),
                child: Transform.scale(
                  scale: 0.96 + 0.04 * t,
                  child: child,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScCard(
                onTap: () async {
                  final changed = await Navigator.push<bool>(
                    context,
                    PageRouteBuilder(
                      transitionDuration:
                      const Duration(milliseconds: 320),
                      pageBuilder: (_, a, __) =>
                          ChiTietHoSoSuaChuaScreen(
                              maHoSo: hs.maHoSoSuaChua),
                      transitionsBuilder: (_, a, __, child) =>
                          FadeTransition(
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
                  if (changed == true) _tai();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _scPrimary.withValues(alpha: 0.15),
                                _scAccent.withValues(alpha: 0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.handyman_rounded,
                              color: _scPrimary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                hs.tenThietBi.isEmpty
                                    ? 'Thiết bị #${hs.maThietBi}'
                                    : hs.tenThietBi,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'HS SC #${hs.maHoSoSuaChua}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: c.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            tenTt,
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hs.moTaHuHong != null &&
                        hs.moTaHuHong!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hs.moTaHuHong!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 15, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hs.tenNhanVienTao ?? '—',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.calendar_today_rounded,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${hs.ngayTao.day.toString().padLeft(2, '0')}/${hs.ngayTao.month.toString().padLeft(2, '0')}/${hs.ngayTao.year}',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: Colors.grey.shade400),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}