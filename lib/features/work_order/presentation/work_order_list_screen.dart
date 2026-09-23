import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
import 'work_order_detail_screen.dart';

/// Danh sách hồ sơ bảo trì — đồng bộ UI/hiệu ứng với hồ sơ sửa chữa.
const _btBg = Color(0xFFF0F6FB);
const _btAccent = Color(0xFF0EA5E9);

class WorkOrderBaoTriListScreen extends StatefulWidget {
  final String? trangThaiMacDinh;
  const WorkOrderBaoTriListScreen({super.key, this.trangThaiMacDinh});
  @override
  State<WorkOrderBaoTriListScreen> createState() =>
      _WorkOrderBaoTriListScreenState();
}

class _WorkOrderBaoTriListScreenState extends State<WorkOrderBaoTriListScreen>
    with TickerProviderStateMixin {
  final _controller = WorkOrderBaoTriListController();
  late TabController _tab;
  late AnimationController _headerAnim;

  final _tabs = const [
    'Tất cả',
    'Chờ duyệt',
    'Đã duyệt',
    'Đang thực hiện',
    'Đã hoàn thành',
    'Từ chối'
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    if (widget.trangThaiMacDinh != null) {
      final key = widget.trangThaiMacDinh == 'Chờ xưởng'
          ? 'Chờ duyệt'
          : widget.trangThaiMacDinh!;
      final idx = _tabs.indexOf(key);
      if (idx >= 0) _tab.index = idx;
    }
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _controller.taiDanhSach();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _tab.dispose();
    _controller.dispose();
    super.dispose();
  }

  Color _mau(TrangThaiHoSoBaoTri tt) {
    switch (tt) {
      case TrangThaiHoSoBaoTri.daDuyet:
        return AppColors.primary;
      case TrangThaiHoSoBaoTri.dangThucHien:
        return const Color(0xFF2563EB);
      case TrangThaiHoSoBaoTri.daHoanThanh:
        return AppColors.success;
      case TrangThaiHoSoBaoTri.tuChoi:
        return AppColors.danger;
      case TrangThaiHoSoBaoTri.choDuyet:
      case TrangThaiHoSoBaoTri.khac:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _icon(TrangThaiHoSoBaoTri tt) {
    switch (tt) {
      case TrangThaiHoSoBaoTri.daDuyet:
        return Icons.verified_outlined;
      case TrangThaiHoSoBaoTri.dangThucHien:
        return Icons.engineering_outlined;
      case TrangThaiHoSoBaoTri.daHoanThanh:
        return Icons.task_alt_rounded;
      case TrangThaiHoSoBaoTri.tuChoi:
        return Icons.cancel_outlined;
      case TrangThaiHoSoBaoTri.choDuyet:
      case TrangThaiHoSoBaoTri.khac:
        return Icons.schedule_rounded;
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _moBoLocNam() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final nams = _controller.cacNamCoKeHoach;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lọc theo năm kế hoạch',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chỉ các năm đã lập kế hoạch bảo trì',
                    style:
                    TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  if (nams.isEmpty)
                    Text('Chưa có dữ liệu năm',
                        style: TextStyle(color: Colors.grey.shade500))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chipNam('Tất cả', null),
                        for (final n in nams) _chipNam('Năm $n', n),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chipNam(String nhan, int? giaTri) {
    final chon = _controller.namLoc == giaTri;
    return ChoiceChip(
      label: Text(nhan),
      selected: chon,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: chon ? Colors.white : Colors.black87,
        fontWeight: chon ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: chon ? AppColors.primary : Colors.grey.shade300),
      ),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        _controller.datNamLoc(giaTri);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: _btBg,
      body: Column(
        children: [
          // ===== Header gradient (giống SC) =====
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
                      color: AppColors.primary.withValues(alpha: 0.35),
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
                          child: const Icon(Icons.build_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hồ sơ bảo trì',
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
                                    : '${_controller.danhSach.length} hồ sơ'
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
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _moBoLocNam,
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
                            onTap: () => _controller.taiDanhSach(),
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
                    TabBar(
                      controller: _tab,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: _tabs.map((e) => Tab(text: e)).toList(),
                    ),
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
                  color: AppColors.primary, strokeWidth: 3),
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
              Text(_controller.loi!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _controller.taiDanhSach,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
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

    return TabBarView(
      controller: _tab,
      children: _tabs.map((tab) {
        final list = _controller.locTheoTab(tab);
        if (list.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _controller.taiDanhSach,
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
                              AppColors.primary.withValues(alpha: 0.12),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inbox_outlined,
                            size: 48, color: AppColors.primary),
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
          color: AppColors.primary,
          onRefresh: _controller.taiDanhSach,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final hs = list[i];
              final loai = phanLoaiTrangThaiHoSo(hs.trangThai);
              final mau = _mau(loai);
              final tenTt =
              hs.trangThai == 'Chờ xưởng' ? 'Chờ duyệt' : hs.trangThai;
              return _HsCard(
                index: i,
                tenThietBi: hs.tenThietBi,
                maHoSo: hs.maHoSoBaoTri,
                ngayTao: _fmt(hs.ngayTao),
                ngayDuKien: hs.ngayDuKienBaoTri != null
                    ? _fmt(hs.ngayDuKienBaoTri!)
                    : null,
                noiDung: hs.noiDungCongViec,
                namKh: 'KH ${hs.nam}${hs.namTuKeHoach ? '' : ' · đột xuất'}',
                trangThai: tenTt,
                mau: mau,
                icon: _icon(loai),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final changed = await Navigator.push<bool>(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 320),
                      pageBuilder: (_, a, __) => WorkOrderBaoTriDetailScreen(
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
                  if (changed == true) _controller.taiDanhSach();
                },
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

class _HsCard extends StatefulWidget {
  final int index;
  final String tenThietBi;
  final int maHoSo;
  final String ngayTao;
  final String? ngayDuKien;
  final String? noiDung;
  final String namKh;
  final String trangThai;
  final Color mau;
  final IconData icon;
  final VoidCallback onTap;

  const _HsCard({
    required this.index,
    required this.tenThietBi,
    required this.maHoSo,
    required this.ngayTao,
    this.ngayDuKien,
    this.noiDung,
    required this.namKh,
    required this.trangThai,
    required this.mau,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HsCard> createState() => _HsCardState();
}

class _HsCardState extends State<_HsCard> with SingleTickerProviderStateMixin {
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
            child: Transform.scale(
              scale: 0.96 + 0.04 * t,
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              transform: Matrix4.identity()..scale(_pressed ? 0.985 : 1.0),
              transformAlignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A)
                        .withValues(alpha: _pressed ? 0.03 : 0.05),
                    blurRadius: _pressed ? 8 : 16,
                    offset: Offset(0, _pressed ? 3 : 6),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                              widget.mau.withValues(alpha: 0.15),
                              _btAccent.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(widget.icon, color: widget.mau, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tenThietBi,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'HS #${widget.maHoSo} · ${widget.ngayTao}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
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
                  if (widget.ngayDuKien != null ||
                      (widget.noiDung != null &&
                          widget.noiDung!.isNotEmpty)) ...[
                    const SizedBox(height: 12),
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
                                    size: 15, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Dự kiến: ${widget.ngayDuKien}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          if (widget.noiDung != null &&
                              widget.noiDung!.isNotEmpty) ...[
                            if (widget.ngayDuKien != null)
                              const SizedBox(height: 6),
                            Text(
                              widget.noiDung!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              _btAccent.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.namKh,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Chi tiết',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary.withValues(alpha: 0.95),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.primary.withValues(alpha: 0.85)),
                    ],
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