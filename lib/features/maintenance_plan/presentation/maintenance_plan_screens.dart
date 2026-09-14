import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../data/maintenance_plan_logic.dart';
import '../../work_order/presentation/work_order_screens.dart';

const _tenThang = [
  '',
  'Tháng 1',
  'Tháng 2',
  'Tháng 3',
  'Tháng 4',
  'Tháng 5',
  'Tháng 6',
  'Tháng 7',
  'Tháng 8',
  'Tháng 9',
  'Tháng 10',
  'Tháng 11',
  'Tháng 12',
];

// ============ MÀN 1: LỊCH KẾ HOẠCH THEO NĂM → 12 THÁNG ============

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

  Color _mau(TrangThaiKeHoach tt) {
    switch (tt) {
      case TrangThaiKeHoach.daDuyet:
        return AppColors.success;
      case TrangThaiKeHoach.tuChoi:
        return AppColors.danger;
      case TrangThaiKeHoach.choXuLy:
        return AppColors.warning;
    }
  }

  Future<void> _moMenuTaoKeHoach() async {
    final cheDo = await showModalBottomSheet<CheDoLapKeHoach>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Lập kế hoạch bảo trì', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.calendar_view_month, color: AppColors.primary),
                ),
                title: const Text('Theo tháng', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Chọn tháng → kế hoạch hiện đúng tháng đó'),
                onTap: () => Navigator.pop(ctx, CheDoLapKeHoach.theoThang),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.calendar_month, color: AppColors.success),
                ),
                title: const Text('Theo năm', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Lập cho cả năm (12 tháng)'),
                onTap: () => Navigator.pop(ctx, CheDoLapKeHoach.theoNam),
              ),
            ],
          ),
        ),
      ),
    );
    if (cheDo == null || !mounted) return;
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMaintenancePlanScreen(cheDo: cheDo),
      ),
    );
    if (ok == true) await _controller.taiDanhSach();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _moMenuTaoKeHoach,
        child: const Icon(Icons.add, color: Colors.white),
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
                    Text(_controller.loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _controller.taiDanhSach, child: const Text('Thử lại')),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Chọn năm
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text('Năm', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _controller.namDangChon,
                            isExpanded: true,
                            items: _controller.danhSachNam
                                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                                .toList(),
                            onChanged: (n) {
                              if (n != null) _controller.doiNam(n);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final thang = index + 1;
                    final mucs = _controller.mucTrongThang(thang);
                    final soLuong = mucs.length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: soLuong > 0
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          child: Text(
                            '$thang',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: soLuong > 0 ? AppColors.primary : Colors.grey,
                            ),
                          ),
                        ),
                        title: Text(
                          _tenThang[thang],
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                        ),
                        subtitle: Text(
                          soLuong == 0 ? 'Chưa có kế hoạch' : '$soLuong thiết bị / lần bảo trì',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        children: soLuong == 0
                            ? [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Chưa có thiết bị nào trong tháng này',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ),
                        ]
                            : mucs.map((muc) {
                          final tt = phanLoaiTrangThai(muc.keHoach.trangThai);
                          final mau = _mau(tt);
                          final d = muc.chiTiet.ngayDuKienBaoTri;
                          final ngayStr =
                              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            leading: Container(
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                color: mau,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            title: Text(
                              muc.chiTiet.tenThietBi,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                            subtitle: Text(
                              'Dự kiến: $ngayStr · ${muc.keHoach.trangThai}',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                            trailing: muc.chiTiet.daTaoHoSo
                                ? Icon(Icons.check_circle, size: 18, color: AppColors.success)
                                : const Icon(Icons.chevron_right, size: 20),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MaintenancePlanDetailScreen(
                                    maKeHoach: muc.keHoach.maKeHoach,
                                    maChuKy: muc.keHoach.maChuKy,
                                    nam: muc.keHoach.nam,
                                  ),
                                ),
                              );
                              await _controller.taiDanhSach();
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============ MÀN 2: LẬP KẾ HOẠCH (THEO THÁNG / THEO NĂM) ============

class CreateMaintenancePlanScreen extends StatefulWidget {
  final CheDoLapKeHoach cheDo;
  const CreateMaintenancePlanScreen({super.key, this.cheDo = CheDoLapKeHoach.theoNam});

  @override
  State<CreateMaintenancePlanScreen> createState() => _CreateMaintenancePlanScreenState();
}

class _CreateMaintenancePlanScreenState extends State<CreateMaintenancePlanScreen> {
  late final CreateMaintenancePlanController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateMaintenancePlanController(cheDo: widget.cheDo);
    _controller.taiDuLieuBanDau();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chonNgayDuKien() async {
    final ngay = await showDatePicker(
      context: context,
      initialDate: _controller.ngayDuKienKhoiTao(),
      firstDate: _controller.ngayBatDau,
      lastDate: _controller.ngayKetThuc,
      helpText: 'Ngày dự kiến trong kế hoạch (không phải ngày bảo trì thực tế)',
    );
    if (ngay != null) _controller.datNgayDuKien(ngay);
  }

  Future<void> _luu() async {
    final ok = await _controller.luuKeHoach();
    if (ok && mounted) Navigator.pop(context, true);
  }

  String _formatNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final laTheoThang = widget.cheDo == CheDoLapKeHoach.theoThang;
    return Scaffold(
      appBar: AppBar(
        title: Text(laTheoThang ? 'Lập kế hoạch theo tháng' : 'Lập kế hoạch theo năm'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) {
            return const Center(child: CircularProgressIndicator());
          }

          return ResponsiveCenteredContent(
            maxContentWidth: 700,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ghi chú nghiệp vụ ngắn
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: const Text(
                      'Ngày lập kế hoạch = hôm nay (tự ghi). '
                          'Ngày dự kiến dưới đây chỉ để xếp lịch tháng. '
                          'Ngày bảo trì thực tế do xưởng chốt — chọn khi Tạo hồ sơ bảo trì.',
                      style: TextStyle(fontSize: 12.5, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Thiết bị', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ThietBiRutGon>(
                    initialValue: _controller.thietBiChon,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    hint: const Text('Chọn thiết bị cần lập kế hoạch'),
                    items: _controller.dsThietBi
                        .map((tb) => DropdownMenuItem(value: tb, child: Text(tb.tenThietBi)))
                        .toList(),
                    onChanged: _controller.chonThietBi,
                  ),

                  const SizedBox(height: 16),
                  const Text('Chu kỳ bảo trì', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      _controller.thietBiChon == null
                          ? 'Chọn thiết bị để xem chu kỳ'
                          : (_controller.chuKyCoDinh != null
                          ? '${_controller.thietBiChon!.tenThietBi} · ${_controller.chuKyCoDinh!.soThangChuKyDeXuat} tháng/lần'
                          : 'Thiết bị chưa được gán chu kỳ'),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _controller.chuKyCoDinh != null ? Colors.black87 : AppColors.danger,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Năm
                  DropdownButtonFormField<int>(
                    value: _controller.nam,
                    decoration: const InputDecoration(
                      labelText: 'Năm áp dụng',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(6, (i) {
                      final y = DateTime.now().year - 1 + i;
                      return DropdownMenuItem(value: y, child: Text('$y'));
                    }),
                    onChanged: (v) {
                      if (v != null) _controller.doiNam(v);
                    },
                  ),

                  if (laTheoThang) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _controller.thang,
                      decoration: const InputDecoration(
                        labelText: 'Tháng áp dụng',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        12,
                            (i) => DropdownMenuItem(value: i + 1, child: Text(_tenThang[i + 1])),
                      ),
                      onChanged: (v) {
                        if (v != null) _controller.doiThang(v);
                      },
                    ),
                  ],

                  const SizedBox(height: 20),
                  if (_controller.chiTietChon != null) ...[
                    const Divider(),
                    const Text('Ngày dự kiến (xếp lịch)', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      laTheoThang
                          ? 'Phải nằm trong tháng ${_controller.thang}/${_controller.nam}. Không trùng ngày lập kế hoạch.'
                          : 'Phải thuộc năm ${_controller.nam}. Không trùng ngày lập kế hoạch.',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.warning),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        title: Text(_controller.chiTietChon!.thietBi.tenThietBi),
                        subtitle: Text('Dự kiến: ${_formatNgay(_controller.chiTietChon!.ngayDuKienBaoTri)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_calendar, size: 20),
                          onPressed: _chonNgayDuKien,
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      'Chọn thiết bị trước để lập kế hoạch',
                      style: TextStyle(color: Colors.grey),
                    ),

                  if (_controller.loi != null) ...[
                    const SizedBox(height: 12),
                    Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _controller.dangLuu ? null : _luu,
                    child: _controller.dangLuu
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Lưu kế hoạch'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============ MÀN 3: CHI TIẾT KẾ HOẠCH ============

class MaintenancePlanDetailScreen extends StatefulWidget {
  final int maKeHoach;
  final int maChuKy;
  final int nam;

  const MaintenancePlanDetailScreen({
    super.key,
    required this.maKeHoach,
    required this.maChuKy,
    required this.nam,
  });

  @override
  State<MaintenancePlanDetailScreen> createState() => _MaintenancePlanDetailScreenState();
}

class _MaintenancePlanDetailScreenState extends State<MaintenancePlanDetailScreen> {
  late final MaintenancePlanDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MaintenancePlanDetailController(
      widget.maKeHoach,
      widget.maChuKy,
      widget.nam,
    );
    _controller.taiChiTiet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _themLanBaoTri() async {
    final goiY = _controller.ngayGoiYLanTiepTheo;
    final ngay = await showDatePicker(
      context: context,
      initialDate: goiY ?? DateTime(widget.nam, DateTime.now().month, DateTime.now().day),
      firstDate: DateTime(widget.nam, 1, 1),
      lastDate: DateTime(widget.nam, 12, 31),
      helpText: goiY != null
          ? 'Ngày dự kiến lần tiếp theo (gợi ý: ${_formatNgay(goiY)})'
          : 'Chọn ngày dự kiến lần bảo trì tiếp theo',
    );
    if (ngay == null) return;

    final ok = await _controller.themLanBaoTri(ngay);
    if (!mounted) return;
    if (!ok && _controller.loi != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_controller.loi!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết KH · ${widget.nam}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: _controller.dangThem ? null : _themLanBaoTri,
          icon: _controller.dangThem
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : const Icon(Icons.add, color: Colors.white),
          label: const Text('Thêm lần bảo trì', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) return const Center(child: CircularProgressIndicator());
          if (_controller.loi != null && _controller.danhSach.isEmpty) {
            return Center(child: Text(_controller.loi!));
          }
          final list = _controller.danhSach;
          if (list.isEmpty) {
            return const Center(child: Text('Chưa có lần bảo trì — bấm "Thêm lần bảo trì"'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final ct = list[i];
              return Card(
                elevation: 0.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  title: Text(ct.tenThietBi, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Dự kiến: ${_formatNgay(ct.ngayDuKienBaoTri)}'),
                  trailing: ct.daTaoHoSo
                      ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Đã tạo hồ sơ', style: TextStyle(color: AppColors.success, fontSize: 11)),
                  )
                      : ElevatedButton(
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: () async {
                      final ok = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateWorkOrderBaoTriScreen(
                            maChiTietKeHoach: ct.maChiTietKeHoach,
                            maThietBi: ct.maThietBi,
                            tenThietBi: ct.tenThietBi,
                          ),
                        ),
                      );
                      if (ok == true) _controller.taiChiTiet();
                    },
                    child: const Text('Tạo hồ sơ'),
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