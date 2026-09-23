import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
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
      if (mounted) setState(() {});
    });
    _xuongCtrl.addListener(() {
      if (mounted) setState(() {});
    });
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
    _thoiGianXuongCtrl.text =
        (hs.thoiGianDuKien ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    _xuongCtrl.batDauChinhSua(hs, thoiGianText: _thoiGianXuongCtrl.text);
  }

  void _huyChinhSuaXuong() {
    _xuongCtrl.huyChinhSua();
  }

  Future<void> _luuChinhSuaXuong(HoSoBaoTri hs) async {
    final ok = await _xuongCtrl.luu(
      maHoSoBaoTri: hs.maHoSoBaoTri,
      noiDungCongViec: _noiDungXuongCtrl.text,
      thoiGianText: _thoiGianXuongCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu chỉnh sửa.')),
      );
      await _controller.taiChiTiet();
      setState(() {});
    } else if (_xuongCtrl.loi != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_xuongCtrl.loi!)),
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

  Widget _cardBox({required List<Widget> children, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? const Color(0xFFE2EAF2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      appBar: AppBar(
        title: const Text('Chi tiết hồ sơ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (_controller.loi != null || _controller.hoSo == null) {
            return Center(child: Text(_controller.loi ?? 'Không tải được hồ sơ'));
          }
          final hs = _controller.hoSo!;
          final mauTt = _mauTrangThai(hs.trangThai);
          final tenTt = (hs.trangThai == 'Chờ xưởng')
              ? 'Chờ duyệt'
              : (hs.trangThai == 'Chờ GĐ duyệt' ? 'Chờ GĐ duyệt' : hs.trangThai);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _controller.taiChiTiet,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header gradient
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0068A9), Color(0xFF004E80), Color(0xFF0B3A5C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -24,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.07),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 40,
                            bottom: -30,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: const Icon(Icons.precision_manufacturing_rounded, color: Colors.white, size: 28),
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
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hồ sơ #${hs.maHoSoBaoTri}',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  tenTt,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Thông tin chung
                  _cardBox(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary.withValues(alpha: 0.9)),
                          const SizedBox(width: 8),
                          const Text('Thông tin hồ sơ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: mauTt.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(tenTt, style: TextStyle(color: mauTt, fontWeight: FontWeight.w700, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _dong('Người lập', hs.tenNhanVienTao ?? '—'),
                      const Divider(height: 18, color: Color(0xFFE8EEF4)),
                      _dong('Ngày tạo', _fmt(hs.ngayTao)),
                      if (hs.ngayDuyet != null) ...[
                        const Divider(height: 18, color: Color(0xFFE8EEF4)),
                        _dong('Ngày duyệt', _fmt(hs.ngayDuyet)),
                      ],
                      const Divider(height: 18, color: Color(0xFFE8EEF4)),
                      _dong('Ngày bảo trì dự kiến', _fmt(hs.ngayDuKienBaoTri)),
                      const Divider(height: 18, color: Color(0xFFE8EEF4)),
                      _dong(
                        'Thời gian dự kiến',
                        hs.thoiGianDuKien == null || hs.thoiGianDuKien!.isEmpty
                            ? '—'
                            : (hs.thoiGianDuKien!.contains('giờ')
                            ? hs.thoiGianDuKien!
                            : '${hs.thoiGianDuKien} giờ'),
                      ),
                      const Divider(height: 18, color: Color(0xFFE8EEF4)),
                      _dong('Giờ bắt đầu', hs.gioBatDauDuKien ?? '—'),
                      const Divider(height: 18, color: Color(0xFFE8EEF4)),
                      _dong('Giờ kết thúc', hs.gioKetThucDuKien ?? '—'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Nội dung công việc
                  _cardBox(
                    children: [
                      const Text('Nội dung công việc',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        hs.noiDungCongViec ?? '—',
                        style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF0F172A)),
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

                  // Xưởng: còn chỉnh sửa/gửi HOẶC đã gửi → chỉ hiện chờ GĐ
                  if (_laXuong && hs.choXuong)
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
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(child: Text('Đang chờ Giám đốc/Phó giám đốc duyệt')),
                                  ],
                                ),
                              ),
                ],
              ),
            ),
          );
        },
      ),
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
                  final now = DateTime.now();
                  final initial = _ngayDuKienXuong ?? now;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial.isBefore(now) ? now : initial,
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                    helpText: 'Chọn ngày dự kiến bảo trì',
                    cancelText: 'Hủy',
                    confirmText: 'Chọn',
                  );
                  if (picked != null) _xuongCtrl.datNgayDuKien(picked);
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.event_available_rounded),
                    filled: true,
                    fillColor: Colors.white,
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
              const SizedBox(height: 14),
              const Text('Số giờ dự kiến',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _thoiGianXuongCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
                onChanged: _onThoiGianXuongChanged,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixText: 'giờ',
                  hintText: 'Ví dụ: 2',
                  filled: true,
                  fillColor: Colors.white,
                  errorText: _loiThoiGianXuong,
                  errorMaxLines: 2,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: _thoiGianXuongHopLe ? 1 : 0.45,
                      child: InkWell(
                        onTap: !_thoiGianXuongHopLe
                            ? () {
                          _xuongCtrl.datThoiGianTuChuoi(
                              _thoiGianXuongCtrl.text);
                        }
                            : () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: _gioBatDauXuong ??
                                const TimeOfDay(hour: 8, minute: 0),
                            builder: (context, child) {
                              return MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                    alwaysUse24HourFormat: true),
                                child: child!,
                              );
                            },
                          );
                          if (t == null) return;
                          _xuongCtrl.datGioBatDau(t);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Giờ bắt đầu',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          child: Text(
                            _fmtGio(_gioBatDauXuong) ??
                                (_thoiGianXuongHopLe
                                    ? 'Chọn giờ'
                                    : 'Nhập số giờ hợp lệ trước'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _gioBatDauXuong == null
                                  ? Colors.grey
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Opacity(
                      opacity: _thoiGianXuongHopLe ? 1 : 0.45,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Giờ kết thúc (tự tính)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        child: Text(
                          _fmtGio(_gioKetThucXuong) ?? '—',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _gioKetThucXuong == null
                                ? Colors.grey
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
  String? _loiThoiGian; // lỗi đỏ dưới ô số giờ

  bool get _choPhepChonGioBatDau {
    if (_loiThoiGian != null) return false;
    final so = int.tryParse(_thoiGian.text.trim());
    return so != null && so > 0 && so <= 24;
  }

  @override
  void initState() {
    super.initState();
    _noiDung = TextEditingController(text: widget.hoSo.noiDungCongViec ?? '');
    _thoiGian = TextEditingController(text: widget.hoSo.thoiGianDuKien ?? '');
    _ngayDuKien = widget.hoSo.ngayDuKienBaoTri;
    _gioBatDau = _parseTime(widget.hoSo.gioBatDauDuKien);
    _gioKetThuc = _parseTime(widget.hoSo.gioKetThucDuKien);
    // Validate sẵn nếu đã có số giờ cũ
    if (_thoiGian.text.trim().isNotEmpty) {
      _validateThoiGian(_thoiGian.text);
      _tinhGioKetThuc();
    }
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

  /// Ràng buộc số giờ — dùng validator chung trong logic.
  void _validateThoiGian(String raw) {
    final kq = validateSoGioDuKien(raw);
    _loiThoiGian = kq.loi;
  }

  void _tinhGioKetThuc() {
    if (!_choPhepChonGioBatDau || _gioBatDau == null) {
      // Giữ null nếu chưa đủ dữ liệu hợp lệ
      if (!_choPhepChonGioBatDau) _gioKetThuc = null;
      return;
    }
    final soGio = int.parse(_thoiGian.text.trim());
    final tongPhut = _gioBatDau!.hour * 60 + _gioBatDau!.minute + soGio * 60;
    _gioKetThuc = TimeOfDay(hour: (tongPhut ~/ 60) % 24, minute: tongPhut % 60);
  }

  void _onThoiGianChanged(String v) {
    setState(() {
      _validateThoiGian(v);
      if (_loiThoiGian != null) {
        _gioKetThuc = null;
      } else {
        _tinhGioKetThuc();
      }
    });
  }

  Future<void> _chonNgay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _ngayDuKien ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _ngayDuKien = picked);
  }

  Future<void> _chonGioBatDau() async {
    if (!_choPhepChonGioBatDau) {
      setState(() {
        _loiThoiGian ??= 'Nhập đúng số giờ dự kiến trước khi chọn giờ bắt đầu';
      });
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
    setState(() {
      _gioBatDau = picked;
      _tinhGioKetThuc();
    });
  }

  Future<void> _luu() async {
    _validateThoiGian(_thoiGian.text);
    if (_loiThoiGian != null) {
      setState(() {});
      return;
    }
    if (_gioBatDau == null) {
      setState(() => _controller.loi = 'Vui lòng chọn giờ bắt đầu');
      // loi is on controller - need set via method; show local message:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giờ bắt đầu')),
      );
      return;
    }
    _tinhGioKetThuc();
    if (_gioKetThuc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa tính được giờ kết thúc')),
      );
      return;
    }

    final ok = await _controller.luu(
      maHoSoBaoTri: widget.hoSo.maHoSoBaoTri,
      noiDungCongViec: _noiDung.text,
      thoiGianDuKien: _thoiGian.text.trim(),
      gioBatDauDuKien: _fmtTime(_gioBatDau),
      gioKetThucDuKien: _fmtTime(_gioKetThuc),
      ngayDuKienBaoTri: _ngayDuKien,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại hồ sơ để duyệt')),
      );
      Navigator.pop(context, true);
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
                    const SizedBox(height: 14),
                    TextField(
                      controller: _thoiGian,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false,
                      ),
                      onChanged: _onThoiGianChanged,
                      decoration: _inputDeco(
                        hint: 'Ví dụ: 2',
                        icon: Icons.timelapse_rounded,
                        suffix: 'giờ',
                        label: 'Thời gian dự kiến',
                        errorText: _loiThoiGian,
                      ),
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
                      'Mỗi thiết bị chỉ 1 lần bảo trì trong 1 tháng. '
                          'Nếu tháng đích đã có kế hoạch/hồ sơ thì không đổi được sang tháng đó.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                    ),
                    const Divider(height: 20),
                    Opacity(
                      opacity: _choPhepChonGioBatDau ? 1 : 0.45,
                      child: _pickerTile(
                        icon: Icons.play_circle_outline_rounded,
                        iconColor: const Color(0xFF059669),
                        label: 'Thời gian bắt đầu',
                        value: _fmtTime(_gioBatDau) ??
                            (_choPhepChonGioBatDau
                                ? 'Chạm để chọn giờ'
                                : 'Nhập số giờ hợp lệ trước'),
                        onTap: _chonGioBatDau,
                      ),
                    ),
                    const Divider(height: 20),
                    // Chỉ hiển thị — không cho chọn tay
                    _pickerTile(
                      icon: Icons.stop_circle_outlined,
                      iconColor: const Color(0xFFDC2626),
                      label: 'Thời gian kết thúc (tự tính)',
                      value: _fmtTime(_gioKetThuc) ?? '—',
                      onTap: () {}, // không làm gì
                      showChevron: false,
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
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixText: suffix,
      errorText: errorText,
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