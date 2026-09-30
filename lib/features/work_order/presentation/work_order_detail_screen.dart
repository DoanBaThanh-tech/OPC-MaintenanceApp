import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/work_order_logic.dart';
import '../data/work_order_validators.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';
import '../data/services/work_order_service.dart';
import 'work_order_assign_screen.dart';

// ============ MÀN 3: CHI TIẾT HỒ SƠ BẢO TRÌ + PHÂN CÔNG (khi đã duyệt) ============

class WorkOrderBaoTriDetailScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  const WorkOrderBaoTriDetailScreen({super.key, required this.maHoSoBaoTri});
  @override
  State<WorkOrderBaoTriDetailScreen> createState() => _WorkOrderBaoTriDetailScreenState();
}

class _WorkOrderBaoTriDetailScreenState extends State<WorkOrderBaoTriDetailScreen> {
  late final WorkOrderBaoTriDetailController _controller;
  final _xuongCtrl = XuongChinhSuaHoSoController();

  final _noiDungXuongCtrl = TextEditingController();
  final _thoiGianXuongCtrl = TextEditingController();

  /// Quy trình / vật tư NVKT đã gửi (hiển thị dưới thông tin hồ sơ khi Đang thực hiện).
  HoSoVatTuItem? _hoSoVatTu;
  bool _dangTaiQuyTrinh = false;
  String? _loiQuyTrinh;

  bool get _laToTruong => _controller.laToTruong;
  bool get _laNvkt => _controller.laNvkt;
  bool get _laXuong => _controller.laXuong;

  // Alias UI bindings → logic Xưởng
  bool get _dangChinhSuaXuong => _xuongCtrl.dangChinhSua;
  bool get _dangLuuXuong => _xuongCtrl.dangLuu;
  String? get _loiThoiGianXuong => _xuongCtrl.loiThoiGian;
  bool get _thoiGianXuongHopLe => _xuongCtrl.thoiGianHopLe;
  TimeOfDay? get _gioBatDauXuong => _xuongCtrl.gioBatDau;
  TimeOfDay? get _gioKetThucXuong => _xuongCtrl.gioKetThuc;
  DateTime? get _ngayDuKienXuong => _xuongCtrl.ngayDuKien;

  @override
  void initState() {
    super.initState();
    _controller = WorkOrderBaoTriDetailController(widget.maHoSoBaoTri);
    _controller.taiChiTiet().then((_) {
      if (!mounted) return;
      setState(() {});
      final hs = _controller.hoSo;
      // Xưởng: xem quy trình khi Đang thực hiện / chờ duyệt / đã xong
      // Tổ trưởng & vai trò khác: chỉ khi Đã hoàn thành
      if (hs != null &&
          (hs.daHoanThanh ||
              (_laXuong &&
                  (hs.choXacNhanKetQua || hs.dangThucHien)))) {
        _taiQuyTrinhVatTu();
      }
    });
    _xuongCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _taiQuyTrinhVatTu() async {
    setState(() {
      _dangTaiQuyTrinh = true;
      _loiQuyTrinh = null;
    });
    try {
      final hs = await MaterialUsageService.layHoSoTheoCongViec(
        maHoSoBaoTri: widget.maHoSoBaoTri,
      );
      if (!mounted) return;
      setState(() {
        _hoSoVatTu = hs;
        _dangTaiQuyTrinh = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loiQuyTrinh = e is ApiException ? e.message : '$e';
        _dangTaiQuyTrinh = false;
      });
    }
  }

  @override
  void dispose() {
    _noiDungXuongCtrl.dispose();
    _thoiGianXuongCtrl.dispose();
    _xuongCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  String? _fmtGio(TimeOfDay? t) => _xuongCtrl.fmtGio(t);

  void _onThoiGianXuongChanged(String v) {
    _xuongCtrl.datThoiGianTuChuoi(v);
  }

  void _batDauChinhSuaXuong(HoSoBaoTri hs) {
    _noiDungXuongCtrl.text = hs.noiDungCongViec ?? '';
    // Giữ chuỗi gốc ("15p" / "4") để nhận đúng đơn vị phút/giờ
    final raw = (hs.thoiGianDuKien ?? '').trim();
    final chiSo = raw.replaceAll(RegExp(r'[^0-9]'), '');
    _thoiGianXuongCtrl.text = chiSo;
    _xuongCtrl.batDauChinhSua(hs, thoiGianText: raw.isEmpty ? chiSo : raw);
  }

  void _huyChinhSuaXuong() {
    _xuongCtrl.huyChinhSua();
  }

  Future<void> _luuChinhSuaXuong(HoSoBaoTri hs) async {
    final ok = await _xuongCtrl.luu(
      maHoSoBaoTri: hs.maHoSoBaoTri,
      noiDungCongViec: _noiDungXuongCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu chỉnh sửa.')),
      );
      await _controller.taiChiTiet();
      setState(() {});
    } else if (_xuongCtrl.loi != null) {
      // Thông báo đỏ — không cho lưu khi sai nghiệp vụ (đổi sang tháng khác, …)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_xuongCtrl.loi!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _dong(String nhan, String giaTri) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(nhan, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
          Flexible(
            child: Text(
              giaTri,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Color _mauTrangThai(String tt) {
    switch (tt) {
      case 'Đã duyệt':
        return AppColors.primary;
      case 'Đang thực hiện':
        return const Color(0xFF1D4ED8);
      case 'Đã hoàn thành':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      case 'Chờ duyệt':
      case 'Chờ xưởng':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  static const _btBg = Color(0xFFF0F6FB);
  static const _btPrimary = Color(0xFF0068A9);

  Widget _cardBox({required List<Widget> children, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _btPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _btHeaderBar({
    required double top,
    required String title,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 4, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF004E80),
            Color(0xFF0068A9),
            Color(0xFF0EA5E9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: _btPrimary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.dangTai) {
          return const Scaffold(
            backgroundColor: _btBg,
            body: Center(
              child: CircularProgressIndicator(
                  color: _btPrimary, strokeWidth: 3),
            ),
          );
        }
        if (_controller.loi != null || _controller.hoSo == null) {
          return Scaffold(
            backgroundColor: _btBg,
            body: Column(
              children: [
                _btHeaderBar(top: top, title: 'Chi tiết hồ sơ BT'),
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
                              backgroundColor: _btPrimary),
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
        final tenTt = (hs.trangThai == 'Chờ xưởng')
            ? 'Chờ duyệt'
            : (hs.trangThai == 'Chờ GĐ duyệt'
            ? 'Chờ GĐ duyệt'
            : hs.trangThai);

        return Scaffold(
          backgroundColor: _btBg,
          body: Column(
            children: [
              _btHeaderBar(
                top: top,
                title: 'Hồ sơ BT #${hs.maHoSoBaoTri}',
                subtitle: tenTt,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await _controller.taiChiTiet();
                    final h = _controller.hoSo;
                    if (h != null &&
                        (h.daHoanThanh ||
                            (_laXuong &&
                                (h.choXacNhanKetQua || h.dangThucHien)))) {
                      await _taiQuyTrinhVatTu();
                    }
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      // Hero card — đồng bộ giao diện SC
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 480),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 18 * (1 - t)),
                            child: child,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(18),
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
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _btPrimary.withValues(alpha: 0.32),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                    Icons.precision_manufacturing_rounded,
                                    color: Colors.white,
                                    size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hs.tenThietBi,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16.5,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tenTt,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Thông tin hồ sơ
                      _cardBox(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.9)),
                              const SizedBox(width: 8),
                              const Text(
                                'Thông tin hồ sơ',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A)),
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
                                  tenTt,
                                  style: TextStyle(
                                      color: mauTt,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _dong('Người lập', hs.tenNhanVienTao ?? '—'),
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          _dong('Ngày tạo', _fmt(hs.ngayTao)),
                          if (hs.ngayDuyet != null) ...[
                            const Divider(
                                height: 18, color: Color(0xFFE8EEF4)),
                            _dong('Ngày duyệt', _fmt(hs.ngayDuyet)),
                          ],
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          _dong('Ngày bảo trì dự kiến',
                              _fmt(hs.ngayDuKienBaoTri)),
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          _dong(
                            'Thời gian dự kiến',
                            (hs.thoiGianDuKien == null ||
                                hs.thoiGianDuKien!.trim().isEmpty)
                                ? '?'
                                : formatThoiGianDuKienHienThi(hs.thoiGianDuKien),
                          ),
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          _dong(
                            'Giờ bắt đầu',
                            (hs.gioBatDauDuKien == null ||
                                hs.gioBatDauDuKien!.trim().isEmpty)
                                ? '?'
                                : hs.gioBatDauDuKien!,
                          ),
                          const Divider(height: 18, color: Color(0xFFE8EEF4)),
                          _dong(
                            'Giờ kết thúc',
                            (hs.gioKetThucDuKien == null ||
                                hs.gioKetThucDuKien!.trim().isEmpty)
                                ? '?'
                                : hs.gioKetThucDuKien!,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Nội dung công việc
                      _cardBox(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 18, color: _btPrimary),
                              SizedBox(width: 8),
                              Text(
                                'Nội dung công việc',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hs.noiDungCongViec ?? '—',
                            style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),

                      // Chỉ hiện khi hồ sơ Đã hoàn thành — danh sách NV đã bảo trì thiết bị
                      if (hs.daHoanThanh) ...[
                        const SizedBox(height: 12),
                        _cardBox(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.groups_rounded,
                                    size: 18,
                                    color: AppColors.success.withValues(alpha: 0.95)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Nhân viên đã bảo trì',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    hs.maNhanVienHoanThanhs.isEmpty
                                        ? '0 người'
                                        : '${hs.maNhanVienHoanThanhs.length} người',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (hs.tenNhanVienHoanThanhs != null &&
                                hs.tenNhanVienHoanThanhs!.trim().isNotEmpty)
                              ...hs.tenNhanVienHoanThanhs!
                                  .split(',')
                                  .map((s) => s.trim())
                                  .where((s) => s.isNotEmpty)
                                  .map(
                                    (ten) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.success
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          ten[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.success,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          ten,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.5,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.check_circle_rounded,
                                          size: 18, color: AppColors.success),
                                    ],
                                  ),
                                ),
                              )
                            else if (hs.tenNhanVienThucHien != null &&
                                hs.tenNhanVienThucHien!.trim().isNotEmpty)
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                    AppColors.success.withValues(alpha: 0.15),
                                    child: Text(
                                      hs.tenNhanVienThucHien![0].toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      hs.tenNhanVienThucHien!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.check_circle_rounded,
                                      size: 18, color: AppColors.success),
                                ],
                              )
                            else
                              Text(
                                'Chưa có thông tin nhân viên thực hiện',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ],

                      // Lý do từ chối hồ sơ (GĐ từ chối duyệt)
                      if (hs.biTuChoi && hs.lyDoTuChoi != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          color: AppColors.danger.withValues(alpha: 0.06),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Lý do từ chối (duyệt hồ sơ)',
                                    style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(hs.lyDoTuChoi!, style: const TextStyle(color: AppColors.danger)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // NVKT từ chối nhận phân công — tông cam nhạt, dễ nhìn
                      if (hs.phanCongBiTuChoi) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF5C896)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEDD5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.person_off_outlined, size: 14, color: Color(0xFFC2410C)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Phân công: Từ chối',
                                          style: TextStyle(
                                            color: Color(0xFFC2410C),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _dong('Nhân viên từ chối', hs.tenNhanVienThucHien ?? '—'),
                              if (hs.ngayPhanCong != null) ...[
                                const Divider(height: 20, color: Color(0xFFF5C896)),
                                _dong('Ngày phân công', _fmt(hs.ngayPhanCong)),
                              ],
                              const Divider(height: 20, color: Color(0xFFF5C896)),
                              const Text(
                                'Lý do từ chối nhận việc',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF9A3412),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (hs.lyDoTuChoiPhanCong != null && hs.lyDoTuChoiPhanCong!.isNotEmpty)
                                    ? hs.lyDoTuChoiPhanCong!
                                    : '—',
                                style: const TextStyle(
                                  color: Color(0xFF431407),
                                  height: 1.4,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Xưởng — Đang thực hiện: quy trình + duyệt; Đã hoàn thành: xem lại
                      if (_laXuong &&
                          (hs.choXacNhanKetQua ||
                              hs.dangThucHien ||
                              hs.daHoanThanh))
                        _buildXuongQuyTrinhVaDuyet(hs)
                      // Tổ trưởng (và vai trò khác): chỉ xem quy trình khi Đã hoàn thành
                      else if (!_laXuong && hs.daHoanThanh)
                        _buildQuyTrinhChiXemKhiHoanThanh(hs)
                      // Xưởng: còn chỉnh sửa/gửi HOẶC đã gửi → chỉ hiện chờ GĐ
                      else if (_laXuong && hs.choXuong)
                          _buildXuongActions(hs)
                        else if (_laXuong && hs.daGuiGiamDoc)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 22),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Đã gửi Giám đốc — đang chờ duyệt. Không thể chỉnh sửa hay gửi lại.',
                                      style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if ((hs.daDuyetChuaPhanCong || hs.phanCongBiTuChoi) && _laToTruong)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.groups_rounded),
                                label: Text(hs.phanCongBiTuChoi ? 'Phân công lại nhân viên khác' : 'Phân công nhân viên'),
                                onPressed: () async {
                                  final ok = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PhanCongBaoTriScreen(maHoSoBaoTri: hs.maHoSoBaoTri),
                                    ),
                                  );
                                  if (ok == true && mounted) {
                                    await _controller.taiChiTiet();
                                  }
                                },
                              )
                            else if (hs.coTheCapNhatPhanCong && _laToTruong)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if ((hs.tenNhanVienThucHiens ?? hs.tenNhanVienThucHien) != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.07),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.people_alt_rounded, size: 20, color: AppColors.primary),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Đang phân công: ${hs.tenNhanVienThucHiens ?? hs.tenNhanVienThucHien}',
                                                style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.manage_accounts_rounded),
                                      label: const Text('Cập nhật phân công'),
                                      onPressed: () async {
                                        final ok = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PhanCongBaoTriScreen(
                                              maHoSoBaoTri: hs.maHoSoBaoTri,
                                              isCapNhat: true,
                                            ),
                                          ),
                                        );
                                        if (ok == true && mounted) {
                                          await _controller.taiChiTiet();
                                        }
                                      },
                                    ),
                                  ],
                                )
                              else if (hs.dangThucHien && _laNvkt)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.task_alt_rounded),
                                    label: const Text('Hoàn thành bảo trì'),
                                    onPressed: () async {
                                      final ok = await _controller.nhanVienHoanThanhBaoTri();
                                      if (!mounted) return;
                                      if (ok) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Đã hoàn thành. Đồng bộ trạng thái hồ sơ và kế hoạch bảo trì.')),
                                        );
                                        setState(() {});
                                      } else if (_controller.loi != null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(_controller.loi!)),
                                        );
                                      }
                                    },
                                  )
                                else if (hs.biTuChoi && _laXuong)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.edit_rounded),
                                      label: const Text('Chỉnh sửa & gửi lại duyệt'),
                                      onPressed: () async {
                                        final ok = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SuaHoSoBiTuChoiScreen(hoSo: hs),
                                          ),
                                        );
                                        if (ok == true && mounted) {
                                          await _controller.taiChiTiet();
                                        }
                                      },
                                    )
                                  else if (hs.choDuyet)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.hourglass_top_rounded,
                                                color: AppColors.warning, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                                child: Text(
                                                    'Đang chờ Giám đốc/Phó giám đốc duyệt')),
                                          ],
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

  /// Tổ trưởng / vai trò khác: chỉ xem quy trình khi hồ sơ Đã hoàn thành
  /// (không hiện ở tab Đang thực hiện — chỉ Xưởng được xem lúc đó).
  Widget _buildQuyTrinhChiXemKhiHoanThanh(HoSoBaoTri hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border:
            Border.all(color: AppColors.success.withValues(alpha: 0.35)),
          ),
          child: const Text(
            'Xưởng đã xác nhận — hồ sơ Đã hoàn thành. Quy trình / vật tư bên dưới (chỉ xem).',
            style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              'Quy trình',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.45)),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildQuyTrinhDuoiThongTin(),
      ],
    );
  }

  /// Trạng thái hiển thị quy trình cho Xưởng (dưới thông tin hồ sơ).
  String _nhanTrangThaiQuyTrinh(HoSoBaoTri hs) {
    if (hs.daHoanThanh || hs.trangThaiPhanCong == 'Hoàn thành') {
      return 'Xác nhận';
    }
    if (hs.trangThaiPhanCong == 'Từ chối') return 'Từ chối';
    if (hs.choXacNhanKetQua) return 'Chờ xác nhận';
    if (hs.dangThucHien) return 'Đang thực hiện';
    return hs.trangThaiPhanCong ?? hs.trangThai;
  }

  Color _mauTrangThaiQuyTrinh(String nhan) {
    switch (nhan) {
      case 'Xác nhận':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      case 'Chờ xác nhận':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildXuongQuyTrinhVaDuyet(HoSoBaoTri hs) {
    final nhanTt = _nhanTrangThaiQuyTrinh(hs);
    final mauTt = _mauTrangThaiQuyTrinh(nhanTt);
    final choDuyet = hs.choXacNhanKetQua;
    final biTuChoiPc = hs.trangThaiPhanCong == 'Từ chối' && hs.dangThucHien;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (choDuyet)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
            ),
            child: const Text(
              'NVKT đã gửi kết quả quy trình. Xưởng kiểm tra từng bước / vật tư rồi Xác nhận (→ Đã hoàn thành) hoặc Từ chối (quy trình giữ nguyên, vẫn Đang thực hiện để NVKT chỉnh lại).',
              style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          )
        else if (biTuChoiPc)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Text(
              (hs.lyDoTuChoiPhanCong != null &&
                  hs.lyDoTuChoiPhanCong!.isNotEmpty)
                  ? 'Đã từ chối quy trình — hồ sơ vẫn Đang thực hiện. Lý do: ${hs.lyDoTuChoiPhanCong}'
                  : 'Đã từ chối quy trình — hồ sơ vẫn Đang thực hiện. Chờ NVKT chỉnh sửa và gửi lại.',
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          )
        else if (hs.daHoanThanh)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: AppColors.success.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'Đã xác nhận quy trình — hồ sơ Đã hoàn thành.',
                style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
              ),
            ),
        const SizedBox(height: 12),
        // Badge trạng thái quy trình
        Row(
          children: [
            const Text(
              'Quy trình',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: mauTt.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mauTt.withValues(alpha: 0.45)),
              ),
              child: Text(
                nhanTt,
                style: TextStyle(
                  color: mauTt,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Quy trình / vật tư — luôn giữ khi từ chối, không xóa
        _buildQuyTrinhDuoiThongTin(),
        if (choDuyet) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success),
                  onPressed: () async {
                    try {
                      await WorkOrderService.xuongXacNhanKetQua(
                        maHoSoBaoTri: hs.maHoSoBaoTri,
                        xacNhan: true,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Đã xác nhận — hồ sơ chuyển Đã hoàn thành'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      await _controller.taiChiTiet();
                      await _taiQuyTrinhVatTu();
                      setState(() {});
                    } on ApiException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Xác nhận'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger),
                  onPressed: () async {
                    final lyDoCtrl = TextEditingController();
                    final lyDo = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Từ chối kết quả'),
                        content: TextField(
                          controller: lyDoCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Lý do để NVKT chỉnh sửa…',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Hủy')),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(ctx, lyDoCtrl.text.trim()),
                            child: const Text('Từ chối'),
                          ),
                        ],
                      ),
                    );
                    if (lyDo == null || lyDo.isEmpty) return;
                    try {
                      await WorkOrderService.xuongXacNhanKetQua(
                        maHoSoBaoTri: hs.maHoSoBaoTri,
                        xacNhan: false,
                        lyDo: lyDo,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Đã từ chối — quy trình giữ nguyên, hồ sơ vẫn Đang thực hiện'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      await _controller.taiChiTiet();
                      await _taiQuyTrinhVatTu();
                      setState(() {});
                    } on ApiException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(e.message),
                            backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Từ chối'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Hiển thị quy trình bảo trì / vật tư ngay dưới thông tin hồ sơ.
  Widget _buildQuyTrinhDuoiThongTin() {
    if (_dangTaiQuyTrinh) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_loiQuyTrinh != null) {
      return _cardBox(children: [
        const Text('Quy trình bảo trì',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        Text(_loiQuyTrinh!, style: TextStyle(color: Colors.grey.shade700)),
        TextButton(onPressed: _taiQuyTrinhVatTu, child: const Text('Thử lại')),
      ]);
    }
    final hsVt = _hoSoVatTu;
    if (hsVt == null || hsVt.chiTiet.isEmpty) {
      return _cardBox(children: [
        const Text('Quy trình bảo trì',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          'Chưa có dữ liệu bước/vật tư (có thể không dùng vật tư).',
          style: TextStyle(
              color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      ]);
    }

    final map = <int, List<ChiTietVatTuSuDung>>{};
    for (final c in hsVt.chiTiet) {
      map.putIfAbsent(c.soBuoc, () => []).add(c);
    }
    final keys = map.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardBox(children: [
          Row(
            children: [
              Icon(Icons.account_tree_rounded,
                  size: 18, color: AppColors.primary.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              const Text('Quy trình bảo trì',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF0F172A))),
              const Spacer(),
              Text(
                '${keys.length} bước',
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        for (final k in keys)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$k',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Bước $k',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
                if (map[k]!.any((e) => e.moTaBuoc.trim().isNotEmpty)) ...[
                  const SizedBox(height: 6),
                  Text(
                    map[k]!
                        .map((e) => e.moTaBuoc.trim())
                        .where((s) => s.isNotEmpty)
                        .toSet()
                        .join(' · '),
                    style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.35,
                        fontSize: 13),
                  ),
                ],
                const SizedBox(height: 6),
                for (final c in map[k]!)
                  if (c.tenVatTu.isNotEmpty && c.soLuong > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 15, color: Color(0xFF0068A9)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${c.tenVatTu} × ${c.soLuong}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildXuongActions(HoSoBaoTri hs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.factory_outlined, color: AppColors.primary.withValues(alpha: 0.9)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _dangChinhSuaXuong
                      ? 'Đang chỉnh sửa — sửa xong bấm Lưu. Bấm Hủy để bỏ thay đổi.'
                      : 'Xưởng xem lịch bảo trì. Bấm Chỉnh sửa nếu cần đổi ngày/nội dung, hoặc xác nhận gửi Giám đốc.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_dangChinhSuaXuong) ...[
          _cardBox(
            children: [
              const Text('Nội dung công việc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _noiDungXuongCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Mô tả công việc...',
                ),
              ),
              const SizedBox(height: 14),
              const Text('Ngày dự kiến bảo trì', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  // Từ tháng kế hoạch gốc → hết năm (T10 → T10–T12 cùng năm)
                  final goc = _xuongCtrl.ngayDuKienGoc ??
                      _ngayDuKienXuong ??
                      DateTime.now();
                  final firstOfRange = DateTime(goc.year, goc.month, 1);
                  final lastOfRange = DateTime(goc.year, 12, 31);
                  var initial = _ngayDuKienXuong ?? firstOfRange;
                  if (initial.isBefore(firstOfRange)) initial = firstOfRange;
                  if (initial.isAfter(lastOfRange)) initial = lastOfRange;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: firstOfRange,
                    lastDate: lastOfRange,
                    helpText:
                    'Từ tháng ${goc.month}/${goc.year} đến hết năm ${goc.year}',
                    cancelText: 'Hủy',
                    confirmText: 'Chọn',
                  );
                  if (picked != null) {
                    _xuongCtrl.datNgayDuKien(picked);
                    // Cảnh báo nếu tháng đã có lịch BT
                    final hs = _controller.hoSo;
                    if (hs != null) {
                      try {
                        final thangCo =
                        await WorkOrderService.layThangCoBaoTri(
                          hs.maThietBi,
                          nam: goc.year,
                        );
                        if (thangCo.contains(picked.month) &&
                            picked.month != goc.month &&
                            mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Lưu ý: tháng ${picked.month}/${goc.year} thiết bị này đã có lịch bảo trì.',
                              ),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                      } catch (_) {}
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.event_available_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    errorText: (_xuongCtrl.loi != null &&
                        (_xuongCtrl.loi!.contains('tháng') ||
                            _xuongCtrl.loi!.contains('ngày dự kiến') ||
                            _xuongCtrl.loi!.contains('Ngày dự kiến')))
                        ? _xuongCtrl.loi
                        : null,
                    errorMaxLines: 4,
                    helperText: _xuongCtrl.ngayDuKienGoc != null
                        ? 'Từ tháng ${_xuongCtrl.ngayDuKienGoc!.month}/${_xuongCtrl.ngayDuKienGoc!.year} trở đi trong năm ${_xuongCtrl.ngayDuKienGoc!.year}'
                        : 'Chọn từ tháng kế hoạch trở đi trong cùng năm',
                    helperMaxLines: 2,
                  ),
                  child: Text(
                    _ngayDuKienXuong == null ? 'Chọn ngày' : _fmt(_ngayDuKienXuong),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _ngayDuKienXuong == null ? Colors.grey : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              if (_xuongCtrl.loi != null &&
                  !(_xuongCtrl.loi!.contains('tháng') ||
                      _xuongCtrl.loi!.contains('ngày dự kiến') ||
                      _xuongCtrl.loi!.contains('Ngày dự kiến'))) ...[
                const SizedBox(height: 8),
                Text(
                  _xuongCtrl.loi!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12.5, height: 1.3),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.9)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thời gian dự kiến / bắt đầu / kết thúc không chỉnh tại đây. '
                            'Hệ thống ghi nhận khi NVKT bấm Tiến hành quy trình và khi hoàn thành.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _dangLuuXuong ? null : _huyChinhSuaXuong,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: _dangLuuXuong
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.save_rounded),
                  label: Text(_dangLuuXuong ? 'Đang lưu…' : 'Lưu'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _dangLuuXuong ? null : () => _luuChinhSuaXuong(hs),
                ),
              ),
            ],
          ),
        ] else ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Chỉnh sửa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _batDauChinhSuaXuong(hs),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            icon: const Icon(Icons.send_rounded),
            label: const Text('Xác nhận lịch · gửi Giám đốc'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final (ok, msg) = await _controller.xuongGuiGiamDoc(
                noiDungCongViec: hs.noiDungCongViec,
                thoiGianDuKien: hs.thoiGianDuKien,
                gioBatDauDuKien: hs.gioBatDauDuKien,
                gioKetThucDuKien: hs.gioKetThucDuKien,
              );
              if (!mounted) return;
              if (ok) {
                _xuongCtrl.huyChinhSua();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi Giám đốc. Hồ sơ chuyển sang Chờ GĐ duyệt.'),
                  ),
                );
                setState(() {});
              } else if (msg != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
          ),
        ],
      ],
    );
  }


}
// ============ MÀN: SỬA HỒ SƠ BỊ TỪ CHỐI ============

class SuaHoSoBiTuChoiScreen extends StatefulWidget {
  final HoSoBaoTri hoSo;
  const SuaHoSoBiTuChoiScreen({super.key, required this.hoSo});

  @override
  State<SuaHoSoBiTuChoiScreen> createState() => _SuaHoSoBiTuChoiScreenState();
}

class _SuaHoSoBiTuChoiScreenState extends State<SuaHoSoBiTuChoiScreen> {
  final _controller = SuaHoSoBiTuChoiController();
  late final TextEditingController _noiDung;
  late final TextEditingController _thoiGian;
  DateTime? _ngayDuKien;
  TimeOfDay? _gioBatDau;
  TimeOfDay? _gioKetThuc;

  /// Giờ: 1–24 · Phút: 1–1440 (số nguyên dương). Dùng controller chung.
  bool get _choPhepChonGioBatDau => _controller.choPhepChonGioBatDau;
  String? get _loiThoiGian => _controller.loiThoiGianDuKien;

  @override
  void initState() {
    super.initState();
    _noiDung = TextEditingController(text: widget.hoSo.noiDungCongViec ?? '');
    // Giữ chuỗi gốc ("15p" / "4") để nhận đúng đơn vị; ô nhập chỉ hiện số
    final raw = (widget.hoSo.thoiGianDuKien ?? '').trim();
    final chiSo = raw.replaceAll(RegExp(r'[^0-9]'), '');
    _thoiGian = TextEditingController(text: chiSo);
    _ngayDuKien = widget.hoSo.ngayDuKienBaoTri;
    _gioBatDau = _parseTime(widget.hoSo.gioBatDauDuKien);
    _gioKetThuc = _parseTime(widget.hoSo.gioKetThucDuKien);
    _controller.khoiTaoTuHoSo(
      thoiGianDuKienStr: raw.isEmpty ? chiSo : raw,
      gioBatDauStr: widget.hoSo.gioBatDauDuKien,
      gioKetThucStr: widget.hoSo.gioKetThucDuKien,
      ngayDuKien: widget.hoSo.ngayDuKienBaoTri,
    );
    if (_gioBatDau != null) {
      _controller.gioBatDau = _gioBatDau;
      _controller.datThoiGianDuKienTuChuoi(raw.isEmpty ? chiSo : raw);
    }
    _gioKetThuc = _controller.gioKetThuc ?? _gioKetThuc;
  }

  @override
  void dispose() {
    _noiDung.dispose();
    _thoiGian.dispose();
    _controller.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? _fmtTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _onThoiGianChanged(String v) {
    _controller.datThoiGianDuKienTuChuoi(v);
    setState(() {
      _gioKetThuc = _controller.gioKetThuc;
    });
  }

  Future<void> _chonNgay() async {
    // Từ tháng kế hoạch gốc → hết năm
    final goc = widget.hoSo.ngayDuKienBaoTri ?? _ngayDuKien ?? DateTime.now();
    final firstOfRange = DateTime(goc.year, goc.month, 1);
    final lastOfRange = DateTime(goc.year, 12, 31);
    var initial = _ngayDuKien ?? firstOfRange;
    if (initial.isBefore(firstOfRange)) initial = firstOfRange;
    if (initial.isAfter(lastOfRange)) initial = lastOfRange;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstOfRange,
      lastDate: lastOfRange,
      helpText: 'Từ tháng ${goc.month}/${goc.year} đến hết năm ${goc.year}',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null) {
      setState(() {
        _ngayDuKien = picked;
        _controller.loi = null;
      });
      try {
        final thangCo = await WorkOrderService.layThangCoBaoTri(
          widget.hoSo.maThietBi,
          nam: goc.year,
        );
        if (thangCo.contains(picked.month) &&
            picked.month != goc.month &&
            mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lưu ý: tháng ${picked.month}/${goc.year} thiết bị này đã có lịch bảo trì.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _chonGioBatDau() async {
    if (!_choPhepChonGioBatDau) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _loiThoiGian ??
                'Nhập đúng thời gian dự kiến (giờ 1–24 hoặc phút 1–1440) trước khi chọn giờ bắt đầu',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    final initial = _gioBatDau ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    _controller.datGioBatDau(picked);
    setState(() {
      _gioBatDau = picked;
      _gioKetThuc = _controller.gioKetThuc;
    });
  }

  Future<void> _luu() async {
    // Validate lại theo đơn vị đang chọn (giờ ≤24 / phút ≤1440)
    _controller.datThoiGianDuKienTuChuoi(_thoiGian.text);
    if (_controller.loiThoiGianDuKien != null) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.loiThoiGianDuKien!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_gioBatDau == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn giờ bắt đầu'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    _controller.datGioBatDau(_gioBatDau!);
    _gioKetThuc = _controller.gioKetThuc;
    if (_gioKetThuc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.loiThoiGianDuKien ??
                'Chưa tính được giờ kết thúc (thời lượng có thể tràn sang ngày sau)',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final ok = await _controller.luu(
      maHoSoBaoTri: widget.hoSo.maHoSoBaoTri,
      noiDungCongViec: _noiDung.text,
      thoiGianDuKien: _controller.chuoiThoiGianLuu ?? _thoiGian.text.trim(),
      gioBatDauDuKien: _fmtTime(_gioBatDau),
      gioKetThucDuKien: _fmtTime(_gioKetThuc),
      ngayDuKienBaoTri: _ngayDuKien,
      ngayDuKienGoc: widget.hoSo.ngayDuKienBaoTri,
      ngayTao: widget.hoSo.ngayTao,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại hồ sơ để duyệt')),
      );
      Navigator.pop(context, true);
    } else if (_controller.loi != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.loi!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sửa hồ sơ bị từ chối'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (widget.hoSo.lyDoTuChoi != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.danger, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lý do từ chối',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: AppColors.danger,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.hoSo.lyDoTuChoi!,
                              style: TextStyle(color: Colors.red.shade800, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              _sectionCard(
                title: 'Nội dung công việc',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _noiDung,
                      maxLines: 4,
                      decoration: _inputDeco(
                        hint: 'Mô tả công việc bảo trì…',
                        icon: Icons.description_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Thời gian dự kiến / bắt đầu / kết thúc không nhập tại đây — hệ thống ghi nhận khi NVKT Tiến hành và khi hoàn thành.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _sectionCard(
                title: 'Lịch bảo trì dự kiến',

                child: Column(
                  children: [
                    _pickerTile(
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFF0068A9),
                      label: 'Ngày bảo trì dự kiến',
                      value: _ngayDuKien == null
                          ? 'Chạm để chọn ngày'
                          : '${_ngayDuKien!.day.toString().padLeft(2, '0')}/${_ngayDuKien!.month.toString().padLeft(2, '0')}/${_ngayDuKien!.year}',
                      onTap: _chonNgay,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.hoSo.ngayDuKienBaoTri != null
                          ? 'Chỉ được chọn ngày trong tháng ${widget.hoSo.ngayDuKienBaoTri!.month}/${widget.hoSo.ngayDuKienBaoTri!.year} '
                          '(theo kế hoạch Tổ trưởng). Không được đổi sang tháng trước/sau.'
                          : 'Chỉ được chọn ngày trong đúng tháng kế hoạch. Không được đổi sang tháng khác.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                    ),
                  ],
                ),
              ),

              if (_controller.loi != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _controller.loi!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _controller.dangLuu ? null : _luu,
                  icon: _controller.dangLuu
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _controller.dangLuu ? 'Đang gửi...' : 'Gửi lại duyệt',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    String? suffix,
    String? label,
    String? errorText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixText: suffix,
      errorText: errorText,
      errorMaxLines: 3,
      helperText: helperText,
      helperMaxLines: 2,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (showChevron)
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}