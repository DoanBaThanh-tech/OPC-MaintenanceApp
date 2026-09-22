import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_exception.dart';
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

  String? _vaiTro;

  bool get _laToTruong =>
      _vaiTro == 'Tổ trưởng cơ điện' ||
          _vaiTro == 'Tổ trưởng kỹ thuật' ||
          _vaiTro == 'Tổ trưởng';
  bool get _laNvkt => _vaiTro == 'Nhân viên kỹ thuật';
  bool get _laXuong => _vaiTro == 'Tổ trưởng sản xuất';

  @override
  void initState() {
    super.initState();
    _controller = WorkOrderBaoTriDetailController(widget.maHoSoBaoTri); // 1) gán trước
    _controller.taiChiTiet();                                           // 2) gọi sau
    TokenStorage.getVaiTro().then((v) {
      if (mounted) setState(() => _vaiTro = v);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _dong(String nhan, String giaTri) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(nhan, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
        Flexible(
          child: Text(giaTri,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) return const Center(child: CircularProgressIndicator());
          if (_controller.loi != null || _controller.hoSo == null) {
            return Center(child: Text(_controller.loi ?? 'Không tải được hồ sơ'));
          }
          final hs = _controller.hoSo!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(hs.tenThietBi,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(hs.trangThai,
                          style: const TextStyle(
                              color: AppColors.warning, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('#${hs.maHoSoBaoTri}', style: TextStyle(color: Colors.grey.shade600)),

                const SizedBox(height: 16),

                // Thông tin chung
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _dong('Người lập', hs.tenNhanVienTao ?? '—'),
                        const Divider(height: 20),
                        _dong('Ngày tạo', _fmt(hs.ngayTao)),
                        if (hs.ngayDuyet != null) ...[
                          const Divider(height: 20),
                          _dong('Ngày duyệt', _fmt(hs.ngayDuyet)),
                        ],
                        const Divider(height: 20),
                        if (_laXuong && _controller.cheDoChinhSua)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Ngày bảo trì dự kiến', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                            subtitle: Text(
                              _fmt(_controller.ngayDuKienChinhSua),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_calendar, color: AppColors.primary),
                              onPressed: () async {
                                final now = DateTime.now();
                                final first = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
                                final initial = _controller.ngayDuKienChinhSua ?? first;
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial.isBefore(first) ? first : initial,
                                  firstDate: first,
                                  lastDate: DateTime(now.year + 3),
                                );
                                if (picked != null) _controller.datNgayDuKienChinhSua(picked);
                              },
                            ),
                          )
                        else
                          _dong('Ngày bảo trì dự kiến', _fmt(hs.ngayDuKienBaoTri)),
                        const Divider(height: 20),
                        _dong(
                          'Thời gian dự kiến',
                          hs.thoiGianDuKien == null || hs.thoiGianDuKien!.isEmpty
                              ? '—'
                              : (hs.thoiGianDuKien!.contains('giờ')
                              ? hs.thoiGianDuKien!
                              : '${hs.thoiGianDuKien} giờ'),
                        ),
                        const Divider(height: 20),
                        _dong('Giờ bắt đầu', hs.gioBatDauDuKien ?? '—'),
                        const Divider(height: 20),
                        _dong('Giờ kết thúc', hs.gioKetThucDuKien ?? '—'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Nội dung công việc
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nội dung công việc',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(hs.noiDungCongViec ?? '—'),
                      ],
                    ),
                  ),
                ),

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

                // ===== XƯỞNG: Chỉnh sửa (chỉ ngày) / Lưu / Gửi Giám đốc =====
                if (_laXuong && _controller.xuongCoTheXuLy) ...[
                  if (_controller.loi != null) ...[
                    Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                    const SizedBox(height: 8),
                  ],
                  if (_controller.cheDoChinhSua) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _controller.dangLuu ? null : _controller.huyCheDoChinhSua,
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: _controller.dangLuu
                                ? null
                                : () async {
                              final ok = await _controller.luuNgayDuKien();
                              if (ok && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã lưu. Ngày dự kiến đã đồng bộ sang kế hoạch bảo trì.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            child: _controller.dangLuu
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Lưu'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Chỉnh sửa'),
                            onPressed: _controller.batCheDoChinhSua,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('Gửi'),
                            onPressed: _controller.dangLuu
                                ? null
                                : () async {
                              final ok = await _controller.guiGiamDoc();
                              if (ok && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã gửi hồ sơ cho Giám đốc / Phó giám đốc duyệt'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ]
                // Nút hành động theo trạng thái + vai trò (Tổ trưởng / NVKT)
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
                else if (hs.daDuyetChoXacNhan && _laNvkt)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Xác nhận nhận việc'),
                      onPressed: () async {
                        try {
                          await WorkOrderService.nhanVienXacNhanBaoTri(hs.maHoSoBaoTri);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xác nhận. Hồ sơ chuyển sang Đang thực hiện')),
                          );
                          await _controller.taiChiTiet();
                        } on ApiException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message)),
                          );
                        }
                      },
                    )
                  else if (hs.daDuyetChoXacNhan && _laToTruong)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hs.tenNhanVienThucHien != null
                                    ? 'Đã phân công ${hs.tenNhanVienThucHien} — chờ xác nhận nhận việc'
                                    : 'Đã phân công — chờ nhân viên kỹ thuật xác nhận nhận việc',
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (hs.biTuChoi && _laToTruong)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.danger, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Hồ sơ bị từ chối — xưởng sẽ chỉnh sửa ngày dự kiến và gửi lại Giám đốc duyệt.',
                                ),
                              ),
                            ],
                          ),
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
          );
        },
      ),
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

  void _validateThoiGian(String raw) {
    final v = raw.trim();
    if (v.isEmpty) {
      _loiThoiGian = 'Vui lòng nhập số giờ dự kiến';
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(v)) {
      _loiThoiGian = 'Chỉ được nhập số dương (không chữ, không ký tự đặc biệt)';
      return;
    }
    final so = int.tryParse(v);
    if (so == null || so <= 0) {
      _loiThoiGian = 'Giờ dự kiến phải lớn hơn 0';
      return;
    }
    if (so > 24) {
      _loiThoiGian = 'Bảo trì trong ngày — tối đa 24 giờ';
      return;
    }
    _loiThoiGian = null;
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