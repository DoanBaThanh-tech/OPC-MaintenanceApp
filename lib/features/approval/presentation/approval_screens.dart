import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_detail_ui.dart';
import '../../../core/network/api_exception.dart';
import '../data/approval_logic.dart';
import '../../work_order/data/services/work_order_service.dart';
import '../../work_order/data/models/work_order_models.dart';
import '../../work_order/presentation/work_order_repair_screens.dart';

// ═══════════════════════════════════════════════════════════════
// UI chung Giám đốc — xanh chủ đạo, hiện đại, có hiệu ứng
// ═══════════════════════════════════════════════════════════════

class _GdUi {
  static const bg = Color(0xFFF0F6FB);
  static const primary = Color(0xFF0068A9);
  static const gradient = LinearGradient(
    colors: [Color(0xFF004E80), Color(0xFF0068A9), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color mauTrangThai(String tt) {
    switch (tt) {
      case 'Chờ duyệt':
      case 'Chờ GĐ duyệt':
      case 'Chờ gửi':
        return AppColors.warning;
      case 'Đã duyệt':
        return const Color(0xFF0284C7);
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return primary;
      case 'Đã hoàn thành':
      case 'Xác nhận':
      case 'Đã xem':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.blueGrey;
    }
  }

  static Widget header({
    required BuildContext context,
    required String title,
    String? subtitle,
    List<Widget>? actions,
    bool showBack = true,
  }) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(showBack ? 8 : 20, top + 8, 12, 20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            )
          else
            const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) ...actions,
        ],
      ),
    );
  }

  static Widget sectionLabel(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
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
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget listCard({
    required int index,
    required Color accent,
    required String title,
    required List<Widget> lines,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index % 8) * 40),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
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
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (trailing != null) trailing,
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...lines,
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget emptyState({
    required IconData icon,
    required String message,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
      ],
    );
  }
}

// ============ MÀN 1: DANH SÁCH HỒ SƠ BẢO TRÌ ============

class ApprovalBaoTriListScreen extends StatefulWidget {
  const ApprovalBaoTriListScreen({super.key});
  @override
  State<ApprovalBaoTriListScreen> createState() => _ApprovalBaoTriListScreenState();
}

class _ApprovalBaoTriListScreenState extends State<ApprovalBaoTriListScreen> {
  final _controller = ApprovalBaoTriListController();

  @override
  void initState() {
    super.initState();
    _controller.taiDanhSachChoDuyet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _filterNamBtn() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final namHienTai = _controller.namLoc;
        return PopupMenuButton<int>(
          tooltip: 'Lọc theo năm',
          offset: const Offset(0, 48),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (value) {
            _controller.datNamLoc(value == -1 ? null : value);
          },
          itemBuilder: (context) {
            final nams = _controller.cacNamCoDuLieu;
            return [
              PopupMenuItem<int>(
                value: -1,
                child: Text(
                  'Tất cả năm',
                  style: TextStyle(
                    fontWeight:
                    namHienTai == null ? FontWeight.w800 : FontWeight.w500,
                    color: namHienTai == null ? _GdUi.primary : null,
                  ),
                ),
              ),
              ...nams.map(
                    (n) => PopupMenuItem<int>(
                  value: n,
                  child: Text(
                    'Năm $n',
                    style: TextStyle(
                      fontWeight:
                      namHienTai == n ? FontWeight.w800 : FontWeight.w500,
                      color: namHienTai == n ? _GdUi.primary : null,
                    ),
                  ),
                ),
              ),
            ];
          },
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list_rounded,
                    size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  namHienTai == null ? 'Năm' : '$namHienTai',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _GdUi.bg,
      body: Column(
        children: [
          _GdUi.header(
            context: context,
            title: 'Duyệt hồ sơ bảo trì',
            subtitle: 'Theo dõi từ chờ duyệt đến hoàn thành',
            actions: [
              _filterNamBtn(),
              IconButton(
                onPressed: _controller.taiDanhSachChoDuyet,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.dangTai) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: _GdUi.primary, strokeWidth: 3),
                  );
                }
                if (_controller.loi != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_controller.loi!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _controller.taiDanhSachChoDuyet,
                          style: FilledButton.styleFrom(
                              backgroundColor: _GdUi.primary),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                final cho = _controller.choDuyet;
                final theoDoi = _controller.dangTheoDoi;
                if (cho.isEmpty && theoDoi.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _controller.taiDanhSachChoDuyet,
                    color: _GdUi.primary,
                    child: _GdUi.emptyState(
                      icon: Icons.fact_check_outlined,
                      message: _controller.namLoc == null
                          ? 'Chưa có hồ sơ bảo trì để theo dõi'
                          : 'Không có hồ sơ trong năm ${_controller.namLoc}',
                    ),
                  );
                }
                var idx = 0;
                return RefreshIndicator(
                  onRefresh: _controller.taiDanhSachChoDuyet,
                  color: _GdUi.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      if (cho.isNotEmpty) ...[
                        _GdUi.sectionLabel(
                            'Chờ duyệt', cho.length, AppColors.warning),
                        ...cho.map((hs) {
                          final i = idx++;
                          final mau = _GdUi.mauTrangThai(hs.trangThai);
                          return _GdUi.listCard(
                            index: i,
                            accent: mau,
                            title: hs.tenThietBi,
                            trailing: _GdUi.statusChip(hs.trangThai, mau),
                            lines: [
                              Text(
                                'Người lập: ${hs.tenNguoiLap ?? '—'}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Tạo ${_fmt(hs.ngayTao)} · KH ${hs.nam}${hs.namTuKeHoach ? '' : ' (đột xuất)'}',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 11.5),
                              ),
                            ],
                            onTap: () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ApprovalBaoTriDetailScreen(
                                      maHoSoBaoTri: hs.maHoSoBaoTri),
                                ),
                              );
                              if (changed == true) {
                                _controller.taiDanhSachChoDuyet();
                              }
                            },
                          );
                        }),
                        const SizedBox(height: 10),
                      ],
                      if (theoDoi.isNotEmpty) ...[
                        _GdUi.sectionLabel('Đã duyệt · theo dõi tiến độ',
                            theoDoi.length, _GdUi.primary),
                        ...theoDoi.map((hs) {
                          final i = idx++;
                          final mau = _GdUi.mauTrangThai(hs.trangThai);
                          return _GdUi.listCard(
                            index: i,
                            accent: mau,
                            title: hs.tenThietBi,
                            trailing: _GdUi.statusChip(hs.trangThai, mau),
                            lines: [
                              Text(
                                'Người lập: ${hs.tenNguoiLap ?? '—'}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Tạo ${_fmt(hs.ngayTao)} · KH ${hs.nam}${hs.namTuKeHoach ? '' : ' (đột xuất)'}',
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 11.5),
                              ),
                            ],
                            onTap: () async {
                              final changed = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ApprovalBaoTriDetailScreen(
                                      maHoSoBaoTri: hs.maHoSoBaoTri),
                                ),
                              );
                              if (changed == true) {
                                _controller.taiDanhSachChoDuyet();
                              }
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============ MÀN 2: CHI TIẾT + PHÊ DUYỆT / TỪ CHỐI ============

class ApprovalBaoTriDetailScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  const ApprovalBaoTriDetailScreen({super.key, required this.maHoSoBaoTri});
  @override
  State<ApprovalBaoTriDetailScreen> createState() => _ApprovalBaoTriDetailScreenState();
}

class _ApprovalBaoTriDetailScreenState extends State<ApprovalBaoTriDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFF0F6FB);
  static const _primary = Color(0xFF0068A9);

  late final ApprovalBaoTriDetailController _controller;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _controller = ApprovalBaoTriDetailController(widget.maHoSoBaoTri);
    _controller.taiChiTiet();
  }

  @override
  void dispose() {
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtThoiGianDuKien(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final v = raw.trim();
    if (v.toLowerCase().endsWith('p')) {
      return '${v.substring(0, v.length - 1)} phút';
    }
    if (v.contains('giờ') || v.contains('phút')) return v;
    return '$v giờ';
  }

  Color _mauTrangThai(String tt) {
    switch (tt) {
      case 'Chờ duyệt':
      case 'Chờ GĐ duyệt':
        return AppColors.warning;
      case 'Đã duyệt':
        return const Color(0xFF0284C7);
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return AppColors.primary;
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _duyet() async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xác nhận phê duyệt'),
        content:
        const Text('Bạn chắc chắn muốn phê duyệt hồ sơ bảo trì này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Phê duyệt'),
          ),
        ],
      ),
    );
    if (xacNhan != true) return;

    final ok = await _controller.xuLy(quyetDinh: 'Duyệt');
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _tuChoi() async {
    final lyDoController = TextEditingController();
    final lyDo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Từ chối hồ sơ'),
        content: TextField(
          controller: lyDoController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            border: OutlineInputBorder(),
            hintText: 'VD: Nội dung công việc chưa rõ ràng...',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, lyDoController.text.trim()),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (lyDo == null || lyDo.isEmpty) return;

    final ok = await _controller.xuLy(quyetDinh: 'Từ chối', lyDo: lyDo);
    if (ok && mounted) Navigator.pop(context, true);
  }

  Widget _headerBar({
    required double top,
    required String title,
    String? subtitle,
  }) =>
      ModernDetailUi.headerBar(
        context: context,
        topPadding: top,
        title: title,
        subtitle: subtitle,
      );

  Widget _softCard({required Widget child}) =>
      ModernDetailUi.softCard(child: child);

  Widget _row(String nhan, String giaTri) =>
      ModernDetailUi.infoRow(nhan, giaTri);

  Widget _fadeSlide({required int delayMs, required Widget child}) =>
      ModernDetailUi.fadeSlide(delayMs: delayMs, child: child);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.dangTai) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: CircularProgressIndicator(color: _primary, strokeWidth: 3),
            ),
          );
        }
        if (_controller.hoSo == null) {
          return Scaffold(
            backgroundColor: _bg,
            body: Column(
              children: [
                _headerBar(top: top, title: 'Chi tiết hồ sơ BT'),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_controller.loi ?? 'Không tải được hồ sơ'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _controller.taiChiTiet,
                          style: FilledButton.styleFrom(
                              backgroundColor: _primary),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final hs = _controller.hoSo!;
        final mauTt = _mauTrangThai(hs.trangThai);

        return Scaffold(
          backgroundColor: _bg,
          body: Column(
            children: [
              _headerBar(
                top: top,
                title: 'Hồ sơ BT #${hs.maHoSoBaoTri}',
                subtitle: hs.trangThai,
              ),
              Expanded(
                child: FadeTransition(
                  opacity:
                  CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      // Hero — đồng bộ ModernDetailUi
                      _fadeSlide(
                        delayMs: 0,
                        child: ModernDetailUi.heroCard(
                          icon: Icons.precision_manufacturing_rounded,
                          title: hs.tenThietBi,
                          statusLabel: hs.trangThai,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Thông tin
                      _fadeSlide(
                        delayMs: 60,
                        child: _softCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 18,
                                      color: _primary.withValues(alpha: 0.95)),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Thông tin hồ sơ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: mauTt.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      hs.trangThai,
                                      style: TextStyle(
                                        color: mauTt,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _row('Người lập', hs.tenNguoiLap ?? '—'),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row('Ngày tạo', _fmt(hs.ngayTao)),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row(
                                  'Ngày dự kiến BT',
                                  _fmt(hs.ngayDuKienBaoTri)),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row(
                                'Thời gian dự kiến',
                                _fmtThoiGianDuKien(hs.thoiGianDuKien),
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row('Giờ bắt đầu', hs.gioBatDauDuKien ?? '—'),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _row('Giờ kết thúc', hs.gioKetThucDuKien ?? '—'),
                              if (hs.nam > 0) ...[
                                Divider(height: 1, color: Colors.grey.shade200),
                                _row(
                                  'Kế hoạch năm',
                                  '${hs.nam}${hs.namTuKeHoach ? '' : ' (đột xuất)'}',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Nội dung CV
                      _fadeSlide(
                        delayMs: 120,
                        child: _softCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.description_outlined,
                                      size: 18, color: _primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Nội dung công việc',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                hs.noiDungCongViec ?? '—',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (hs.lyDoTuChoi != null &&
                          hs.lyDoTuChoi!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _fadeSlide(
                          delayMs: 150,
                          child: _softCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.report_outlined,
                                        size: 18, color: AppColors.danger),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lý do từ chối',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hs.lyDoTuChoi!,
                                  style: const TextStyle(
                                    height: 1.4,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (_controller.loi != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _controller.loi!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Hành động
                      _fadeSlide(
                        delayMs: 180,
                        child: hs.choDuyet
                            ? (_controller.dangXuLy
                            ? const Center(
                          child: CircularProgressIndicator(
                              color: _primary),
                        )
                            : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(
                                      color: AppColors.danger),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                    Icons.close_rounded),
                                label: const Text('Từ chối'),
                                onPressed: _tuChoi,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF15803D),
                                      Color(0xFF22C55E),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                    onTap: _duyet,
                                    child: const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Phê duyệt',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                            FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ))
                            : Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: mauTt.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: mauTt.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hs.daHoanThanh
                                    ? Icons.verified_rounded
                                    : hs.biTuChoi
                                    ? Icons.cancel_outlined
                                    : Icons.timeline_rounded,
                                color: mauTt,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  hs.daHoanThanh
                                      ? 'Hồ sơ đã hoàn thành — chỉ theo dõi, không cần duyệt lại.'
                                      : hs.biTuChoi
                                      ? 'Hồ sơ đã từ chối — chỉ xem lại.'
                                      : 'Hồ sơ đang ở trạng thái «${hs.trangThai}» — theo dõi tiến độ.',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade800,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
// ============ LỊCH SỬ PHÊ DUYỆT (Giám đốc) ============

class LichSuPheDuyetScreen extends StatefulWidget {
  const LichSuPheDuyetScreen({super.key});

  @override
  State<LichSuPheDuyetScreen> createState() => _LichSuPheDuyetScreenState();
}

class _LichSuPheDuyetScreenState extends State<LichSuPheDuyetScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = LichSuPheDuyetController();
  late TabController _tabCtrl;

  static const _tabs = ['Bảo trì', 'Sửa chữa'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _ctrl.doiTab(_tabs[_tabCtrl.index]);
      }
    });
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String _fmtNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtGio(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch sử phê duyệt'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0068A9), Color(0xFF0284C7), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Bảo trì'),
            Tab(text: 'Sửa chữa'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildYearFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildYearFilter() {
    final years = _ctrl.cacNam;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lọc theo năm',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _yearChip('Tất cả', null),
                ...years.map((y) => _yearChip('$y', y)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearChip(String label, int? value) {
    final selected = _ctrl.namLoc == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _ctrl.datNam(value),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.dangTai) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ctrl.loi != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.danger.withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              Text(_ctrl.loi!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _ctrl.tai, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_ctrl.danhSach.isEmpty) {
      return RefreshIndicator(
        onRefresh: _ctrl.tai,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử phê duyệt\n${_ctrl.tabLoai.toLowerCase()}'
                  '${_ctrl.namLoc != null ? ' năm ${_ctrl.namLoc}' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _ctrl.tai,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _ctrl.danhSach.length,
        itemBuilder: (context, i) {
          final item = _ctrl.danhSach[i];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 280 + (i % 6) * 40),
            curve: Curves.easeOutCubic,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
            ),
            child: _LichSuCard(
              item: item,
              fmtNgay: _fmtNgay,
              fmtGio: _fmtGio,
            ),
          );
        },
      ),
    );
  }
}

class _LichSuCard extends StatelessWidget {
  final LichSuPheDuyetItem item;
  final String Function(DateTime) fmtNgay;
  final String Function(DateTime) fmtGio;

  const _LichSuCard({
    required this.item,
    required this.fmtNgay,
    required this.fmtGio,
  });

  @override
  Widget build(BuildContext context) {
    final daDuyet = item.daDuyet;
    final mau = daDuyet ? AppColors.success : AppColors.danger;
    final nhanTrangThai = daDuyet ? 'Đã duyệt' : 'Từ chối';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mau.withValues(alpha: 0.12), mau.withValues(alpha: 0.03)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: mau.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        daDuyet ? Icons.check_circle_rounded : Icons.cancel_rounded,
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
                            item.tenThietBi ?? 'Hồ sơ #${item.maHoSo ?? '—'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.loai} · HS #${item.maHoSo ?? '—'} · ${fmtNgay(item.ngayDuyet)} ${fmtGio(item.ngayDuyet)}',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: mau.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        nhanTrangThai,
                        style: TextStyle(color: mau, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.person_outline, 'Người lập', item.tenNguoiLap ?? '—'),
                    const SizedBox(height: 8),
                    _infoRow(Icons.verified_user_outlined, 'Người duyệt', item.tenNguoiDuyet ?? '—'),
                    if (item.noiDung != null && item.noiDung!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow(Icons.notes_rounded, 'Nội dung', item.noiDung!),
                    ],
                    if (item.tuChoi && item.lyDo != null && item.lyDo!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.danger.withValues(alpha: 0.9)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lý do từ chối: ${item.lyDo}',
                                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.35),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ============ DUYỆT HỒ SƠ SỬA CHỮA (Giám đốc xem sau khi NVKT Hoàn thành) ============

class ApprovalSuaChuaListScreen extends StatefulWidget {
  const ApprovalSuaChuaListScreen({super.key});

  @override
  State<ApprovalSuaChuaListScreen> createState() =>
      _ApprovalSuaChuaListScreenState();
}

class _ApprovalSuaChuaListScreenState extends State<ApprovalSuaChuaListScreen> {
  List<HoSoSuaChua> _list = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      // Toàn bộ hồ sơ SC — GĐ theo dõi từ chờ duyệt → hoàn thành (không mất sau khi duyệt)
      final all = await WorkOrderService.layDanhSachHoSoSuaChua();
      final list = all
          .where((h) =>
      h.trangThai == 'Chờ duyệt' ||
          h.trangThai == 'Đã duyệt' ||
          h.trangThai == 'Đang thực hiện' ||
          h.trangThai == 'Chờ xác nhận' ||
          h.trangThai == 'Đã hoàn thành' ||
          h.trangThai == 'Từ chối')
          .toList()
        ..sort((a, b) {
          int rank(String tt) {
            switch (tt) {
              case 'Chờ duyệt':
                return 0;
              case 'Đang thực hiện':
              case 'Chờ xác nhận':
                return 1;
              case 'Đã duyệt':
                return 2;
              case 'Đã hoàn thành':
                return 3;
              case 'Từ chối':
                return 4;
              default:
                return 5;
            }
          }

          final r = rank(a.trangThai).compareTo(rank(b.trangThai));
          if (r != 0) return r;
          return b.ngayTao.compareTo(a.ngayTao);
        });
      if (!mounted) return;
      setState(() {
        _list = list;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e is ApiException ? e.message : '$e';
        _dangTai = false;
        _list = [];
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Color _mau(String tt) {
    switch (tt) {
      case 'Chờ duyệt':
        return AppColors.warning;
      case 'Đã duyệt':
        return const Color(0xFF0284C7);
      case 'Đang thực hiện':
      case 'Chờ xác nhận':
        return AppColors.primary;
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final choDuyet =
    _list.where((h) => h.trangThai == 'Chờ duyệt').toList();
    final theoDoi = _list.where((h) => h.trangThai != 'Chờ duyệt').toList();

    return Scaffold(
      backgroundColor: _GdUi.bg,
      body: Column(
        children: [
          _GdUi.header(
            context: context,
            title: 'Duyệt hồ sơ sửa chữa',
            subtitle: 'Theo dõi từ chờ duyệt đến hoàn thành',
            actions: [
              IconButton(
                onPressed: _tai,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              ),
            ],
          ),
          Expanded(
            child: _dangTai
                ? const Center(
              child: CircularProgressIndicator(
                  color: _GdUi.primary, strokeWidth: 3),
            )
                : _loi != null
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loi!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _tai,
                    style: FilledButton.styleFrom(
                        backgroundColor: _GdUi.primary),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _tai,
              color: _GdUi.primary,
              child: _list.isEmpty
                  ? _GdUi.emptyState(
                icon: Icons.handyman_outlined,
                message:
                'Chưa có hồ sơ sửa chữa để theo dõi',
              )
                  : ListView(
                padding:
                const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  if (choDuyet.isNotEmpty) ...[
                    _GdUi.sectionLabel('Chờ duyệt',
                        choDuyet.length, AppColors.warning),
                    ...choDuyet.asMap().entries.map((e) {
                      final hs = e.value;
                      final mau =
                      _GdUi.mauTrangThai(hs.trangThai);
                      return _GdUi.listCard(
                        index: e.key,
                        accent: mau,
                        title: hs.tenThietBi,
                        trailing: _GdUi.statusChip(
                            hs.trangThai, mau),
                        lines: [
                          Text(
                            'HS SC #${hs.maHoSoSuaChua} · ${_fmt(hs.ngayTao)}',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12),
                          ),
                          if (hs.moTaHuHong != null &&
                              hs.moTaHuHong!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              hs.moTaHuHong!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12.5,
                                  height: 1.3),
                            ),
                          ],
                        ],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChiTietHoSoSuaChuaScreen(
                                    maHoSo: hs.maHoSoSuaChua,
                                  ),
                            ),
                          );
                          _tai();
                        },
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                  if (theoDoi.isNotEmpty) ...[
                    _GdUi.sectionLabel(
                        'Đã duyệt · theo dõi tiến độ',
                        theoDoi.length,
                        _GdUi.primary),
                    ...theoDoi.asMap().entries.map((e) {
                      final hs = e.value;
                      final mau =
                      _GdUi.mauTrangThai(hs.trangThai);
                      return _GdUi.listCard(
                        index: e.key + choDuyet.length,
                        accent: mau,
                        title: hs.tenThietBi,
                        trailing: _GdUi.statusChip(
                            hs.trangThai, mau),
                        lines: [
                          Text(
                            'HS SC #${hs.maHoSoSuaChua} · ${_fmt(hs.ngayTao)}',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12),
                          ),
                          if (hs.moTaHuHong != null &&
                              hs.moTaHuHong!
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              hs.moTaHuHong!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12.5,
                                  height: 1.3),
                            ),
                          ],
                        ],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChiTietHoSoSuaChuaScreen(
                                    maHoSo: hs.maHoSoSuaChua,
                                  ),
                            ),
                          );
                          _tai();
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}