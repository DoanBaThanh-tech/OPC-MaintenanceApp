import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/technician_logic.dart';
import '../data/models/work_order_models.dart';
import '../data/services/work_order_service.dart';
import 'quy_trinh_thuc_hien_screen.dart';

// ============ QUẢN LÝ YÊU CẦU (NVKT) ============

class QuanLyYeuCauScreen extends StatefulWidget {
  const QuanLyYeuCauScreen({super.key});

  @override
  State<QuanLyYeuCauScreen> createState() => _QuanLyYeuCauScreenState();
}

class _QuanLyYeuCauScreenState extends State<QuanLyYeuCauScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = QuanLyYeuCauController();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _ctrl.doiTab(_tabCtrl.index == 0 ? 'Bảo trì' : 'Sửa chữa');
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

  Future<void> _moChiTiet(YeuCauPhanCong y) async {
    final changed = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ChiTietYeuCauScreen(yeuCau: y),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
    if (changed == true) _ctrl.tai();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0068A9), Color(0xFF004E80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Công việc của tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Xem chi tiết và hoàn thành khi xong việc — không cần xác nhận nhận việc',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  tabs: const [
                    Tab(text: 'Bảo trì'),
                    Tab(text: 'Sửa chữa'),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _ctrl.dangTai
                ? const Center(child: CircularProgressIndicator())
                : _ctrl.loi != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48,
                        color: AppColors.danger.withValues(alpha: 0.7)),
                    const SizedBox(height: 12),
                    Text(_ctrl.loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _ctrl.tai,
                        child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _ctrl.tai,
              color: AppColors.primary,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final canLam = _ctrl.canThucHien;
    final xong = _ctrl.daHoanThanh;
    final huy = _ctrl.danhSach.where((e) => e.daHuy || e.biTuChoi).toList();

    if (canLam.isEmpty && xong.isEmpty && huy.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Chưa có yêu cầu ${_ctrl.tabLoai.toLowerCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (canLam.isNotEmpty) ...[
          _sectionHeader('Cần thực hiện', canLam.length, const Color(0xFFD97706)),
          const SizedBox(height: 10),
          ...canLam.asMap().entries.map((e) => _YeuCauCard(
            yeuCau: e.value,
            index: e.key,
            onTap: () => _moChiTiet(e.value),
          )),
          const SizedBox(height: 18),
        ],
        if (xong.isNotEmpty) ...[
          _sectionHeader('Đã hoàn thành', xong.length, AppColors.success),
          const SizedBox(height: 10),
          ...xong.asMap().entries.map((e) => _YeuCauCard(
            yeuCau: e.value,
            index: e.key,
            onTap: () => _moChiTiet(e.value),
          )),
          const SizedBox(height: 18),
        ],
        if (huy.isNotEmpty) ...[
          _sectionHeader('Đã hủy / khác', huy.length, Colors.grey),
          const SizedBox(height: 10),
          ...huy.asMap().entries.map((e) => _YeuCauCard(
            yeuCau: e.value,
            index: e.key,
            onTap: () => _moChiTiet(e.value),
          )),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
                color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _YeuCauCard extends StatelessWidget {
  final YeuCauPhanCong yeuCau;
  final int index;
  final VoidCallback onTap;

  const _YeuCauCard({
    required this.yeuCau,
    required this.index,
    required this.onTap,
  });

  Color _statusColor(String tt) {
    switch (tt) {
      case 'Chờ xác nhận':
      case 'Đã phân công':
      case 'Xác nhận':
        return const Color(0xFFD97706);
      case 'Đang thực hiện':
        return AppColors.primary; // xanh đồng bộ
      case 'Từ chối':
      case 'Đã hủy':
        return AppColors.danger;
      case 'Hoàn thành':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(YeuCauPhanCong y) {
    if (y.daHoanThanhPc) return 'Hoàn thành';
    if (y.daHuy) return 'Đã hủy';
    if (y.biTuChoi) return 'Từ chối';
    if (y.canThucHien) return 'Cần làm';
    return y.trangThaiPhanCong;
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(yeuCau.trangThaiPhanCong);
    final label = _statusLabel(yeuCau);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 35),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - t)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          yeuCau.laBaoTri
                              ? Icons.precision_manufacturing_rounded
                              : Icons.handyman_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              yeuCau.tenThietBi ??
                                  'Thiết bị #${yeuCau.maThietBi ?? '—'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${yeuCau.loai} · HS #${yeuCau.maHoSo ?? '—'}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (yeuCau.noiDung != null && yeuCau.noiDung!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      yeuCau.noiDung!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          yeuCau.tenNhanVienPhanCong ?? '—',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (yeuCau.ngayDuKienBaoTri != null) ...[
                        Icon(Icons.event_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _fmt(yeuCau.ngayDuKienBaoTri!),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ] else ...[
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _fmt(yeuCau.ngayPhanCong),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded,
                          size: 20, color: Colors.grey.shade400),
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ============ CHI TIẾT YÊU CẦU ============

class ChiTietYeuCauScreen extends StatefulWidget {
  final YeuCauPhanCong yeuCau;
  const ChiTietYeuCauScreen({super.key, required this.yeuCau});

  @override
  State<ChiTietYeuCauScreen> createState() => _ChiTietYeuCauScreenState();
}

class _ChiTietYeuCauScreenState extends State<ChiTietYeuCauScreen> {
  bool _dangXuLy = false;

  String _fmtDt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtGio(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _tienHanh() async {
    final y = widget.yeuCau;
    // SC: bấm Tiến hành → đồng bộ HS = Đang thực hiện cho mọi vai trò
    if (!y.laBaoTri && y.maHoSo != null) {
      setState(() => _dangXuLy = true);
      try {
        await WorkOrderService.nhanVienTienHanhSuaChua(y.maHoSo!);
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _dangXuLy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() => _dangXuLy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
        );
        return;
      }
      if (mounted) setState(() => _dangXuLy = false);
    }

    final changed = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            QuyTrinhThucHienScreen(yeuCau: widget.yeuCau),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
    if (changed == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final y = widget.yeuCau;
    final top = MediaQuery.paddingOf(context).top;
    final showHoanThanh = !y.daHuy &&
        !y.daHoanThanhPc &&
        y.maHoSo != null &&
        y.canThucHien;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(8, top + 4, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(22)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        y.laBaoTri ? 'Chi tiết bảo trì' : 'Chi tiết sửa chữa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        y.tenThietBi ?? 'HS #${y.maHoSo ?? '—'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Device card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          y.laBaoTri
                              ? Icons.precision_manufacturing_rounded
                              : Icons.handyman_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              y.tenThietBi ?? '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hồ sơ #${y.maHoSo ?? '—'} · PC #${y.maPhanCong}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _infoCard([
                  _row('Loại', y.loai),
                  _row(
                      'Trạng thái',
                      y.daHoanThanhPc
                          ? 'Hoàn thành'
                          : (y.canThucHien ? 'Cần thực hiện' : y.trangThaiPhanCong)),
                  _row('Trạng thái hồ sơ', y.trangThaiHoSo ?? '—'),
                  _row('Người phân công', y.tenNhanVienPhanCong ?? '—'),
                  _row('Ngày phân công', _fmtDt(y.ngayPhanCong)),
                  if (y.ngayDuKienBaoTri != null)
                    _row('Ngày dự kiến BT', _fmtDt(y.ngayDuKienBaoTri!)),
                  if (y.thoiGianDuKien != null)
                    _row('Thời gian dự kiến', '${y.thoiGianDuKien} giờ'),
                  if (y.ngayBatDauDuKien != null)
                    _row('Giờ bắt đầu', _fmtGio(y.ngayBatDauDuKien!)),
                  if (y.ngayKetThucDuKien != null)
                    _row('Giờ kết thúc', _fmtGio(y.ngayKetThucDuKien!)),
                ]),

                if (y.noiDung != null && y.noiDung!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _infoCard([
                    const Text(
                      'Nội dung công việc',
                      style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      y.noiDung!,
                      style:
                      TextStyle(color: Colors.grey.shade800, height: 1.4),
                    ),
                  ]),
                ],

                if (y.daHuy) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.block_rounded, color: AppColors.danger),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Yêu cầu này đã được tổ trưởng hủy phân công',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (y.daHoanThanhPc) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Công việc đã hoàn thành',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Nút Tiến hành bảo trì / sửa chữa → trang quy trình từng bước
          if (showHoanThanh)
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _dangXuLy ? null : _tienHanh,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _dangXuLy
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_circle_outline_rounded,
                          size: 22),
                      const SizedBox(width: 8),
                      Text(
                        y.laBaoTri
                            ? 'Tiến hành bảo trì'
                            : 'Tiến hành sửa chữa',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ KẾT QUẢ THỰC HIỆN ============

class KetQuaThucHienScreen extends StatefulWidget {
  const KetQuaThucHienScreen({super.key});

  @override
  State<KetQuaThucHienScreen> createState() => _KetQuaThucHienScreenState();
}

class _KetQuaThucHienScreenState extends State<KetQuaThucHienScreen> {
  final _ctrl = KetQuaThucHienController();
  final _ghiChuCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
    _ctrl.tai();
  }

  @override
  void dispose() {
    _ghiChuCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _chonNgay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _ctrl.ngayGhiNhan ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) _ctrl.datNgayGhiNhan(picked);
  }

  Future<void> _luu() async {
    // Server tự lấy MaNhanVienThucHien nếu gửi 0
    _ctrl.ghiChu = _ghiChuCtrl.text;
    final ok = await _ctrl.xacNhanHoanThanh(maNhanVienGhiNhan: 0);
    if (ok && mounted) {
      _ghiChuCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã ghi nhận kết quả'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ghi nhận kết quả'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _ctrl.dangTai
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Chọn yêu cầu đã xác nhận',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (_ctrl.dsXacNhan.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Không có yêu cầu ở trạng thái Xác nhận',
                style: TextStyle(color: Color(0xFF9A3412)),
              ),
            )
          else
            DropdownButtonFormField<YeuCauPhanCong?>(
              value: _ctrl.chon,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                const DropdownMenuItem<YeuCauPhanCong?>(
                  value: null,
                  child: Text('— Chọn hồ sơ —'),
                ),
                ..._ctrl.dsXacNhan.map(
                      (y) => DropdownMenuItem(
                    value: y,
                    child: Text(
                      '${y.tenThietBi ?? 'HS #${y.maHoSo}'} · ${y.trangThaiPhanCong}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => _ctrl.chonYeuCau(v),
            ),
          const SizedBox(height: 16),
          const Text('Ngày ghi nhận',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _chonNgay,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _ctrl.ngayGhiNhan == null
                        ? 'Chọn ngày'
                        : '${_ctrl.ngayGhiNhan!.day.toString().padLeft(2, '0')}/${_ctrl.ngayGhiNhan!.month.toString().padLeft(2, '0')}/${_ctrl.ngayGhiNhan!.year}',
                  ),
                ],
              ),
            ),
          ),
          if (_ctrl.loiNgay != null) ...[
            const SizedBox(height: 6),
            Text(_ctrl.loiNgay!,
                style: const TextStyle(
                    color: AppColors.danger, fontSize: 12.5)),
          ],
          const SizedBox(height: 16),
          const Text('Ghi chú',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _ghiChuCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ghi chú kết quả thực hiện…',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_ctrl.loi != null) ...[
            const SizedBox(height: 12),
            Text(_ctrl.loi!,
                style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _ctrl.dangLuu ? null : _luu,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _ctrl.dangLuu
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Text(
                'Xác nhận hoàn thành',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}