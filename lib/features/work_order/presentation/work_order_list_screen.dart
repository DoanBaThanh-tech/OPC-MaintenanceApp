import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
import 'work_order_detail_screen.dart';

/// Danh sách hồ sơ bảo trì — xanh / trắng, hiện đại, hiệu ứng nhẹ.
class WorkOrderBaoTriListScreen extends StatefulWidget {
  final String? trangThaiMacDinh;
  const WorkOrderBaoTriListScreen({super.key, this.trangThaiMacDinh});
  @override
  State<WorkOrderBaoTriListScreen> createState() => _WorkOrderBaoTriListScreenState();
}

class _WorkOrderBaoTriListScreenState extends State<WorkOrderBaoTriListScreen>
    with TickerProviderStateMixin {
  final _controller = WorkOrderBaoTriListController();
  late TabController _tab;
  late AnimationController _fadeCtrl;

  final _tabs = const ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Đang thực hiện', 'Đã hoàn thành', 'Từ chối'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    if (widget.trangThaiMacDinh != null) {
      final key = widget.trangThaiMacDinh == 'Chờ xưởng' ? 'Chờ duyệt' : widget.trangThaiMacDinh!;
      final idx = _tabs.indexOf(key);
      if (idx >= 0) _tab.index = idx;
    }
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _controller.taiDanhSach();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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
        return const Color(0xFFE6A700);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chỉ các năm đã lập kế hoạch bảo trì',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  if (nams.isEmpty)
                    Text('Chưa có dữ liệu năm', style: TextStyle(color: Colors.grey.shade500))
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
        side: BorderSide(color: chon ? AppColors.primary : Colors.grey.shade300),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      appBar: AppBar(
        title: const Text('Hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => IconButton(
              tooltip: 'Lọc năm',
              onPressed: _moBoLocNam,
              icon: Badge(
                isLabelVisible: _controller.namLoc != null,
                label: Text('${_controller.namLoc}', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.filter_list_rounded),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: _tabs.map((e) => Tab(text: e)).toList(),
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _fadeCtrl]),
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (_controller.loi != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(_controller.loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _controller.taiDanhSach,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeCtrl,
            child: TabBarView(
              controller: _tab,
              children: _tabs.map((tab) {
                final list = _controller.locTheoTab(tab);
                if (list.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _controller.taiDanhSach,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Không có hồ sơ · $tab',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _controller.taiDanhSach,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final hs = list[i];
                      final loai = phanLoaiTrangThaiHoSo(hs.trangThai);
                      final mau = _mau(loai);
                      final tenTt = hs.trangThai == 'Chờ xưởng' ? 'Chờ duyệt' : hs.trangThai;
                      return _HsCard(
                        index: i,
                        tenThietBi: hs.tenThietBi,
                        maHoSo: hs.maHoSoBaoTri,
                        ngayTao: _fmt(hs.ngayTao),
                        ngayDuKien: hs.ngayDuKienBaoTri != null ? _fmt(hs.ngayDuKienBaoTri!) : null,
                        noiDung: hs.noiDungCongViec,
                        namKh: 'KH ${hs.nam}${hs.namTuKeHoach ? '' : ' · đột xuất'}',
                        trangThai: tenTt,
                        mau: mau,
                        icon: _icon(loai),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkOrderBaoTriDetailScreen(maHoSoBaoTri: hs.maHoSoBaoTri),
                            ),
                          );
                          if (changed == true) _controller.taiDanhSach();
                        },
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
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
      duration: Duration(milliseconds: 320 + (widget.index.clamp(0, 8) * 40)),
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
            offset: Offset(0, 18 * (1 - t)),
            child: child,
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
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              transform: Matrix4.identity()..scale(_pressed ? 0.985 : 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2EAF2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: _pressed ? 0.06 : 0.07),
                    blurRadius: _pressed ? 6 : 14,
                    offset: Offset(0, _pressed ? 2 : 5),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: widget.mau,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: widget.mau.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(widget.icon, color: widget.mau, size: 22),
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
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'HS #${widget.maHoSo} · ${widget.ngayTao}',
                                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: widget.mau.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.trangThai,
                                    style: TextStyle(
                                      color: widget.mau,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.ngayDuKien != null ||
                                (widget.noiDung != null && widget.noiDung!.isNotEmpty)) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F9FC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.ngayDuKien != null)
                                      Row(
                                        children: [
                                          Icon(Icons.event_available_rounded, size: 15, color: AppColors.primary),
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
                                    if (widget.noiDung != null && widget.noiDung!.isNotEmpty) ...[
                                      if (widget.ngayDuKien != null) const SizedBox(height: 6),
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
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F1F8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.namKh,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Chi tiết',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary.withValues(alpha: 0.9),
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary.withValues(alpha: 0.8)),
                              ],
                            ),
                          ],
                        ),
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