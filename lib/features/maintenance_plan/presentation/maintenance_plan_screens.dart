import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/maintenance_plan_logic.dart';

const _tenThangNgan = [
  '', 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12',
];
const _tenThang = [
  '',
  'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
  'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
];

// ============ MÀN 1: LỊCH 12 THÁNG (dạng cuốn lịch) ============

class MaintenancePlanListScreen extends StatefulWidget {
  const MaintenancePlanListScreen({super.key});
  @override
  State<MaintenancePlanListScreen> createState() => _MaintenancePlanListScreenState();
}

class _MaintenancePlanListScreenState extends State<MaintenancePlanListScreen> {
  final _controller = MaintenancePlanListController();

  @override
  void initState() {
    super.initState();
    _controller.taiDanhSach();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _moMenuTaoKeHoach() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Lập kế hoạch bảo trì', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _MenuOption(
                icon: Icons.build_circle_outlined,
                color: AppColors.primary,
                title: 'Lập bảo trì cho thiết bị',
                subtitle: 'Thêm thiết bị vào 1 tháng cụ thể của năm ${_controller.namDangChon}',
                onTap: () => Navigator.pop(ctx, 'thietBi'),
              ),
              const SizedBox(height: 10),
              _MenuOption(
                icon: Icons.calendar_month_rounded,
                color: AppColors.success,
                title: 'Lập kế hoạch theo năm',
                subtitle: 'Tạo khung kế hoạch trống cho 1 năm mới',
                onTap: () => Navigator.pop(ctx, 'namMoi'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    if (action == 'namMoi') {
      final ok = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreateYearPlanScreen(namDaCo: _controller.danhSachNam)),
      );
      if (ok == true) await _controller.taiDanhSach();
    } else {
      final ok = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreateMaintenancePlanScreen(nam: _controller.namDangChon)),
      );
      if (ok == true) await _controller.taiDanhSach();
    }
  }

  void _moChiTietThang(int thang) {
    final mucs = _controller.mucTrongThang(thang);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaintenanceMonthDetailScreen(
          nam: _controller.namDangChon,
          thang: thang,
          mucBanDau: mucs,
        ),
      ),
    ).then((_) => _controller.taiDanhSach());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _moMenuTaoKeHoach,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Lập kế hoạch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_controller.loi != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(_controller.loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _controller.taiDanhSach, child: const Text('Thử lại')),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.event_note_rounded, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Lịch kế hoạch bảo trì',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _controller.namDangChon,
                            items: _controller.danhSachNam
                                .map((n) => DropdownMenuItem(value: n, child: Text('$n', style: const TextStyle(fontWeight: FontWeight.w700))))
                                .toList(),
                            onChanged: (n) {
                              if (n != null) _controller.doiNam(n);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,           // ← đổi từ 3 sang 4 tháng/hàng
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,       // cao hơn để chứa danh sách thiết bị
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final thang = index + 1;
                      final mucs = _controller.mucTrongThang(thang);
                      final isCurrent = thang == DateTime.now().month && _controller.namDangChon == DateTime.now().year;
                      return _OThangLich(thang: thang, mucs: mucs, isCurrent: isCurrent, onTap: () => _moChiTietThang(thang));
                    },
                    childCount: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CreateYearPlanScreen extends StatefulWidget {
  final List<int> namDaCo;
  const CreateYearPlanScreen({super.key, required this.namDaCo});
  @override
  State<CreateYearPlanScreen> createState() => _CreateYearPlanScreenState();
}

class _CreateYearPlanScreenState extends State<CreateYearPlanScreen> {
  late final CreateYearPlanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateYearPlanController(widget.namDaCo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _luu() async {
    final ok = await _controller.luu();
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lập kế hoạch theo năm'), backgroundColor: AppColors.success, foregroundColor: Colors.white),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 56, color: AppColors.success),
                  const SizedBox(height: 16),
                  const Text('Năm áp dụng', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(counterText: '', border: OutlineInputBorder(), hintText: 'VD: 2028'),
                    onChanged: _controller.datNam,
                  ),
                  if (_controller.loi != null) ...[
                    const SizedBox(height: 8),
                    Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: _controller.dangLuu ? null : _luu,
                    child: _controller.dangLuu
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Tạo kế hoạch năm', style: TextStyle(fontWeight: FontWeight.w700)),
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
class _MenuOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _OThangLich extends StatelessWidget {
  final int thang;
  final List<MucThietBiTrongThang> mucs;
  final bool isCurrent;
  final VoidCallback onTap;

  const _OThangLich({required this.thang, required this.mucs, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final coDuLieu = mucs.isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isCurrent ? 3 : 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isCurrent ? AppColors.primary : Colors.grey.shade200, width: isCurrent ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header giống cuốn lịch — dải màu trên cùng
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.primary : Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    _tenThangNgan[thang],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isCurrent ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: coDuLieu
                      ? ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final m in mucs.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            m.chiTiet.tenThietBi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (mucs.length > 3)
                        Text('+${mucs.length - 3} khác', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  )
                      : Center(child: Text('Trống', style: TextStyle(fontSize: 11, color: Colors.grey.shade400))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ MÀN CHI TIẾT THEO THÁNG (chỉ thiết bị đúng tháng) ============

class MaintenanceMonthDetailScreen extends StatefulWidget {
  final int nam;
  final int thang;
  final List<MucThietBiTrongThang> mucBanDau;

  const MaintenanceMonthDetailScreen({
    super.key,
    required this.nam,
    required this.thang,
    required this.mucBanDau,
  });

  @override
  State<MaintenanceMonthDetailScreen> createState() => _MaintenanceMonthDetailScreenState();
}

class _MaintenanceMonthDetailScreenState extends State<MaintenanceMonthDetailScreen> {
  late final MaintenancePlanMonthDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MaintenancePlanMonthDetailController(
      nam: widget.nam,
      thang: widget.thang,
      mucBanDau: widget.mucBanDau,
    );
    _controller.khoiTao();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Color _mauTT(String tt) {
    switch (phanLoaiTrangThai(tt)) {
      case TrangThaiKeHoach.choDuyet:
        return AppColors.warning;
      case TrangThaiKeHoach.daDuyet:
        return const Color(0xFF0068A9);
      case TrangThaiKeHoach.tuChoi:
        return AppColors.danger;
      case TrangThaiKeHoach.dangThucHien:
        return const Color(0xFF1D4ED8);
      case TrangThaiKeHoach.daHoanThanh:
        return AppColors.success;
      case TrangThaiKeHoach.chuaTao:
        return Colors.grey;
      case TrangThaiKeHoach.choXuLy:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_tenThang[widget.thang]} · ${widget.nam}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = _controller.danhSach;
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có thiết bị nào trong ${_tenThang[widget.thang].toLowerCase()}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dùng nút "+" → Lập bảo trì cho thiết bị',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final muc = list[i];
              final ct = muc.chiTiet;
              // Ưu tiên trạng thái HỒ SƠ bảo trì (giống màn hồ sơ), không dùng trạng thái kế hoạch năm
              final nhanTT = ct.nhanTrangThaiHienThi;
              final mau = _mauTT(nhanTT);
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 0.8,
                shadowColor: Colors.black26,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border(left: BorderSide(color: mau, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ct.tenThietBi,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: mau.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              nhanTT,
                              style: TextStyle(color: mau, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Dự kiến: ${_fmt(ct.ngayDuKienBaoTri)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      if (muc.keHoach.tenChuKy != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          muc.keHoach.tenChuKy!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                      // Trạng thái hồ sơ (đã gom tạo hồ sơ vào "Lập bảo trì cho thiết bị" — không còn nút tạo riêng)
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: mau.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ct.daTaoHoSo
                                  ? (ct.trangThaiHoSo == 'Đã duyệt' ||
                                  ct.trangThaiHoSo == 'Hoàn thành' ||
                                  ct.trangThaiHoSo == 'Đã hoàn thành'
                                  ? Icons.check_circle
                                  : ct.trangThaiHoSo == 'Từ chối'
                                  ? Icons.cancel
                                  : Icons.info_outline)
                                  : Icons.schedule_outlined,
                              size: 16,
                              color: mau,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ct.daTaoHoSo ? 'Hồ sơ: $nhanTT' : nhanTT,
                              style: TextStyle(
                                color: mau,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============ MÀN LẬP KẾ HOẠCH ============

class CreateMaintenancePlanScreen extends StatefulWidget {
  final int nam;
  const CreateMaintenancePlanScreen({super.key, required this.nam});
  @override
  State<CreateMaintenancePlanScreen> createState() => _CreateMaintenancePlanScreenState();
}

class _CreateMaintenancePlanScreenState extends State<CreateMaintenancePlanScreen> {
  late final CreateMaintenancePlanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateMaintenancePlanController(nam: widget.nam);
    _controller.taiDuLieuBanDau();
  }

  @override
  void dispose() {
    _controller.noiDungCongViecController.dispose();
    _controller.thoiGianTextController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chonNgay() async {
    var first = _controller.ngayDuKienToiThieu;
    final last = _controller.ngayKetThuc;
    if (first.isAfter(last)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tháng này không còn ngày hợp lệ (phải sau ngày lập kế hoạch). Chọn tháng khác.',
          ),
        ),
      );
      return;
    }
    var initial = _controller.chiTietChon?.ngayDuKienBaoTri ?? first;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final ngay = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (ngay != null) _controller.datNgayDuKien(ngay);
  }

  Future<void> _luu() async {
    final ok = await _controller.luuKeHoach();
    if (ok && mounted) Navigator.pop(context, true);
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Lập bảo trì cho thiết bị · Năm ${widget.nam}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Tìm theo tên thiết bị hoặc danh mục',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _controller.datTuKhoaTimKiem,
                    ),
                    const SizedBox(height: 12),
                    const Text('Danh mục thiết bị', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _controller.danhMucChon,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      hint: const Text('Tất cả danh mục'),
                      items: _controller.danhSachDanhMuc.map((dm) {
                        return DropdownMenuItem(
                          value: dm,
                          child: Text(dm, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _controller.chonDanhMuc,
                    ),
                    const SizedBox(height: 16),
                    const Text('Thiết bị', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ThietBiRutGon>(
                      value: _controller.thietBiChon,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                      ),
                      hint: Text(
                        _controller.danhMucChon == null
                            ? 'Chọn danh mục trước (khuyến nghị)'
                            : 'Chọn thiết bị',
                      ),
                      items: _controller.dsThietBiDaLoc.map((tb) {
                        return DropdownMenuItem(
                          value: tb,
                          child: Text(tb.tenThietBi, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _controller.chonThietBi,
                    ),
                    const SizedBox(height: 16),
                    const Text('Tháng', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _controller.thang,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_view_month),
                      ),
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(value: m, child: Text('Tháng $m')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) _controller.doiThang(v);
                      },
                    ),
                    if (_controller.chuKyCoDinh != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Chu kỳ đề xuất: ${_controller.chuKyCoDinh!.soThangChuKyDeXuat} tháng/lần',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                    if (_controller.chiTietChon != null) ...[
                      const SizedBox(height: 20),
                      const Text('Ngày dự kiến bảo trì', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          title: Text(_controller.chiTietChon!.thietBi.tenThietBi),
                          subtitle: Text('Dự kiến: ${_fmt(_controller.chiTietChon!.ngayDuKienBaoTri)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_calendar),
                            onPressed: _chonNgay,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text('Nội dung công việc', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller.noiDungCongViecController,
                      maxLines: 3,
                      readOnly: false,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Mô tả công việc cần bảo trì...',
                        filled: false,
                        fillColor: null,
                        suffixIcon: null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Giờ dự kiến bảo trì (số giờ)', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller.thoiGianTextController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                      readOnly: false,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        suffixText: 'giờ',
                        helperText: 'Trong ngày — lớn hơn 0 và tối đa 24 giờ',
                        errorText: _controller.loiThoiGianDuKien,
                        filled: false,
                        fillColor: null,
                      ),
                      onChanged: _controller.datThoiGianDuKienTuChuoi,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _controller.gioBatDau ?? TimeOfDay.now(),
                              );
                              if (t != null) _controller.datGioBatDau(t);
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Giờ bắt đầu',
                                border: const OutlineInputBorder(),
                                filled: false,
                                fillColor: null,
                              ),
                              child: Text(_controller.gioBatDau?.format(context) ?? 'Chọn giờ'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Giờ kết thúc (tự tính)',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _controller.gioKetThucTuTinh?.format(context) ?? '—',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_controller.loi != null) ...[
                      const SizedBox(height: 12),
                      Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _controller.dangLuu ? null : _luu,
                      child: _controller.dangLuu
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Gửi bảo trì', style: TextStyle(fontWeight: FontWeight.w700)),
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