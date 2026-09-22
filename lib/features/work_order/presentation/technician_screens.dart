import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/technician_logic.dart';
import '../data/models/work_order_models.dart';   // ← thêm
import '../data/services/work_order_service.dart'; // ← thêm

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
      MaterialPageRoute(builder: (_) => ChiTietYeuCauScreen(yeuCau: y)),
    );
    if (changed == true) _ctrl.tai();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý yêu cầu'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
      body: _ctrl.dangTai
          ? const Center(child: CircularProgressIndicator())
          : _ctrl.loi != null
          ? Center(
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
      )
          : RefreshIndicator(
        onRefresh: _ctrl.tai,
        child: _buildList(),
      ),
    );
  }

  Widget _buildList() {
    final choXn = _ctrl.choXacNhan;
    final khac = _ctrl.khac;
    if (choXn.isEmpty && khac.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (choXn.isNotEmpty) ...[
          _sectionHeader('Chờ xác nhận', choXn.length, AppColors.warning),
          const SizedBox(height: 8),
          ...choXn.map((y) => _YeuCauCard(yeuCau: y, onTap: () => _moChiTiet(y))),
          const SizedBox(height: 16),
        ],
        if (khac.isNotEmpty) ...[
          _sectionHeader('Đã xử lý', khac.length, AppColors.primary),
          const SizedBox(height: 8),
          ...khac.map((y) => _YeuCauCard(yeuCau: y, onTap: () => _moChiTiet(y))),
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
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ],
    );
  }
}

class _YeuCauCard extends StatelessWidget {
  final YeuCauPhanCong yeuCau;
  final VoidCallback onTap;
  const _YeuCauCard({required this.yeuCau, required this.onTap});

  Color _statusColor(String tt) {
    switch (tt) {
      case 'Chờ xác nhận':
      case 'Đã phân công':
        return AppColors.warning;
      case 'Xác nhận':
        return AppColors.success;
      case 'Từ chối':
      case 'Đã hủy':
        return AppColors.danger;
      case 'Hoàn thành':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _statusColor(yeuCau.trangThaiPhanCong);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        yeuCau.laBaoTri ? Icons.build_circle_outlined : Icons.handyman_outlined,
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
                            yeuCau.tenThietBi ?? 'Thiết bị #${yeuCau.maThietBi ?? '—'}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${yeuCau.loai} · HS #${yeuCau.maHoSo ?? '—'}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        yeuCau.trangThaiPhanCong,
                        style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 11),
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
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        yeuCau.tenNhanVienPhanCong ?? '—',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _fmt(yeuCau.ngayPhanCong),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
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

  Future<void> _xacNhan() async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;
    setState(() => _dangXuLy = true);
    try {
      if (y.laBaoTri) {
        await WorkOrderService.nhanVienXacNhanBaoTri(y.maHoSo!);
      } else {
        await WorkOrderService.nhanVienXacNhanSuaChua(y.maHoSo!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận nhận việc'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  Future<void> _tuChoi() async {
    final lyDoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Từ chối nhận việc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nhập lý do từ chối. Tổ trưởng cơ điện sẽ thấy trong Lịch sử phân công.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lyDoCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Lý do từ chối...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (lyDoCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Gửi từ chối'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final lyDo = lyDoCtrl.text.trim();
    if (lyDo.isEmpty || widget.yeuCau.maHoSo == null) return;

    setState(() => _dangXuLy = true);
    try {
      if (widget.yeuCau.laBaoTri) {
        await WorkOrderService.nhanVienTuChoiBaoTri(maHoSo: widget.yeuCau.maHoSo!, lyDo: lyDo);
      } else {
        await WorkOrderService.nhanVienTuChoiSuaChua(maHoSo: widget.yeuCau.maHoSo!, lyDo: lyDo);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi từ chối'), backgroundColor: AppColors.warning),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final y = widget.yeuCau;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(y.laBaoTri ? 'Yêu cầu bảo trì' : 'Yêu cầu sửa chữa'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.14),
                            AppColors.primary.withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              y.laBaoTri ? Icons.precision_manufacturing_rounded : Icons.handyman_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  y.tenThietBi ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Hồ sơ #${y.maHoSo ?? '—'} · Phân công #${y.maPhanCong}',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoCard([
                      _row('Loại', y.loai),
                      _row('Trạng thái phân công', y.trangThaiPhanCong),
                      _row('Trạng thái hồ sơ', y.trangThaiHoSo ?? '—'),
                      _row('Người phân công', y.tenNhanVienPhanCong ?? '—'),
                      _row('Ngày phân công', _fmtDt(y.ngayPhanCong)),
                      if (y.ngayDuKienBaoTri != null)
                        _row('Ngày dự kiến BT', _fmtDt(y.ngayDuKienBaoTri!)),
                      if (y.thoiGianDuKien != null) _row('Thời gian dự kiến', '${y.thoiGianDuKien} giờ'),
                      if (y.ngayBatDauDuKien != null)
                        _row('Giờ bắt đầu dự kiến', _fmtGio(y.ngayBatDauDuKien!)),
                      if (y.ngayKetThucDuKien != null)
                        _row('Giờ kết thúc dự kiến', _fmtGio(y.ngayKetThucDuKien!)),
                    ]),
                    if (y.noiDung != null && y.noiDung!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _infoCard([
                        const Text('Nội dung công việc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(y.noiDung!, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
                      ]),
                    ],
                    if (y.lyDoTuChoi != null && y.lyDoTuChoi!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lý do từ chối', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
                            const SizedBox(height: 6),
                            Text(y.lyDoTuChoi!),
                          ],
                        ),
                      ),
                    ],
                    if (y.daHuy) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.block_rounded, color: AppColors.danger),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Yêu cầu bảo trì này được hủy bởi tổ trưởng kỹ thuật',
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
                  ],
                ),
              ),
            ),
            // Không còn Xác nhận / Từ chối — chỉ xem. Khi đang thực hiện → nút Hoàn thành bảo trì.
            if (!y.daHuy &&
                y.maHoSo != null &&
                (y.trangThaiPhanCong == 'Đã phân công' ||
                    y.trangThaiPhanCong == 'Xác nhận' ||
                    y.trangThaiPhanCong == 'Đang thực hiện' ||
                    y.trangThaiHoSo == 'Đang thực hiện') &&
                y.trangThaiPhanCong != 'Hoàn thành')
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: _dangXuLy ? null : () async {
                    setState(() => _dangXuLy = true);
                    try {
                      await WorkOrderService.nhanVienHoanThanhBaoTri(y.maHoSo!);
                      if (mounted) Navigator.pop(context, true);
                    } on ApiException catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _dangXuLy = false);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _dangXuLy
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Hoàn thành bảo trì'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _fmtDt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtGio(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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

  Future<void> _submit() async {
    // maNhanVien: service fallback nếu 0 — nhưng cố gắng gửi hợp lệ
    const maNv = 0;
    final ok = await _ctrl.xacNhanHoanThanh(maNhanVienGhiNhan: maNv);
    if (!mounted) return;
    if (ok) {
      _ghiChuCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận hoàn thành. Hồ sơ → Đã hoàn thành, thiết bị → Sản xuất'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (_ctrl.loi != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_ctrl.loi!), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // Không cho chọn ngày/tháng trước ngày dự kiến bảo trì trong hồ sơ
    DateTime firstDate = DateTime(now.year - 2);
    DateTime lastDate = DateTime(now.year + 2);
    DateTime initial = _ctrl.ngayGhiNhan ?? now;

    final dk = _ctrl.chon?.ngayDuKienBaoTri;
    if (dk != null) {
      // firstDate = đúng ngày dự kiến bảo trì (không cho chọn trước)
      firstDate = DateTime(dk.year, dk.month, dk.day);
      // Chỉ cho chọn trong tháng dự kiến bảo trì
      lastDate = DateTime(dk.year, dk.month + 1, 0); // ngày cuối tháng dự kiến
      // initialDate phải nằm trong [firstDate, lastDate]
      if (initial.isBefore(firstDate)) {
        initial = firstDate;
      } else if (initial.isAfter(lastDate)) {
        initial = lastDate;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Chọn ngày ghi nhận (không trước ngày dự kiến bảo trì)',
    );
    if (picked != null) _ctrl.datNgayGhiNhan(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kết quả thực hiện'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _ctrl.dangTai
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chỉ hiển thị yêu cầu đã xác nhận nhận việc',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Combobox hồ sơ
              Text('Hồ sơ bảo trì / sửa chữa', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<YeuCauPhanCong?>(
                    isExpanded: true,
                    value: _ctrl.chon,
                    hint: const Text('Chọn hồ sơ đã xác nhận'),
                    items: [
                      const DropdownMenuItem<YeuCauPhanCong?>(
                        value: null,
                        child: Text('— Chọn —'),
                      ),
                      ..._ctrl.dsXacNhan.map(
                            (y) => DropdownMenuItem(
                          value: y,
                          child: Text(
                            '${y.tenThietBi ?? 'TB'} · HS #${y.maHoSo} (${y.loai})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _ctrl.chonYeuCau(v);
                      _ghiChuCtrl.clear();
                      _ctrl.ghiChu = '';
                    },
                  ),
                ),
              ),
              if (_ctrl.dsXacNhan.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Không có yêu cầu ở trạng thái Xác nhận',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
              if (_ctrl.chon != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thiết bị: ${_ctrl.chon!.tenThietBi ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (_ctrl.chon!.ngayDuKienBaoTri != null)
                        Text(
                          'Ngày dự kiến bảo trì: ${_ctrl.chon!.ngayDuKienBaoTri!.day.toString().padLeft(2, '0')}/${_ctrl.chon!.ngayDuKienBaoTri!.month.toString().padLeft(2, '0')}/${_ctrl.chon!.ngayDuKienBaoTri!.year}',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('Ngày ghi nhận', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _ctrl.loiNgay != null ? AppColors.danger : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, color: AppColors.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _ctrl.ngayGhiNhan == null
                                ? 'Chọn ngày ghi nhận'
                                : '${_ctrl.ngayGhiNhan!.day.toString().padLeft(2, '0')}/${_ctrl.ngayGhiNhan!.month.toString().padLeft(2, '0')}/${_ctrl.ngayGhiNhan!.year}',
                            style: TextStyle(
                              color: _ctrl.ngayGhiNhan == null ? Colors.grey.shade500 : Colors.black87,
                              fontWeight: _ctrl.ngayGhiNhan == null ? FontWeight.w400 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_ctrl.loiNgay != null) ...[
                const SizedBox(height: 6),
                Text(
                  _ctrl.loiNgay!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 20),
              Text('Ghi chú', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              TextField(
                controller: _ghiChuCtrl,
                maxLines: 4,
                onChanged: (v) => _ctrl.ghiChu = v,
                decoration: InputDecoration(
                  hintText: 'Ghi chú kết quả thực hiện (không bắt buộc)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _ctrl.dangLuu ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _ctrl.dangLuu
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Xác nhận hoàn thành', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}