import 'package:flutter/material.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../data/maintenance_plan_logic.dart';
import '../../work_order/presentation/work_order_screens.dart';

// ============ MÀN 1: DANH SÁCH KẾ HOẠCH ============

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateMaintenancePlanScreen()),
          );
          if (ok == true) await _controller.taiDanhSach();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) return const Center(child: CircularProgressIndicator());
          if (_controller.loi != null) return Center(child: Text(_controller.loi!));
          final list = _controller.danhSach;
          if (list.isEmpty) return const Center(child: Text('Chưa có kế hoạch bảo trì nào'));
          return Responsive(
            builder: (context, info) {
              final soCot = info.isDesktop ? 3 : (info.isTablet ? 2 : 1);
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: soCot,
                  mainAxisExtent: 110,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final kh = list[i];
                  return _CardKeHoach(
                    keHoach: kh,
                    mau: _mau(phanLoaiTrangThai(kh.trangThai)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Truyền thêm maChuKy — Chi tiết kế hoạch cần nó để tính
                        // ngày gợi ý cho nút "Thêm lần bảo trì"
                        builder: (_) => MaintenancePlanDetailScreen(
                          maKeHoach: kh.maKeHoach,
                          maChuKy: kh.maChuKy,
                          nam: kh.nam,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CardKeHoach extends StatelessWidget {
  final KeHoachBaoTri keHoach;
  final Color mau;
  final VoidCallback onTap;
  const _CardKeHoach({required this.keHoach, required this.mau, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: mau, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${keHoach.tenThietBi ?? 'Thiết bị chưa xác định'} · ${keHoach.nam}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(keHoach.tenChuKy ?? 'Chu kỳ #${keHoach.maChuKy}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: mau.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(keHoach.trangThai, style: TextStyle(color: mau, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ MÀN 2: LẬP KẾ HOẠCH MỚI (không đổi) ============

class CreateMaintenancePlanScreen extends StatefulWidget {
  const CreateMaintenancePlanScreen({super.key});
  @override
  State<CreateMaintenancePlanScreen> createState() => _CreateMaintenancePlanScreenState();
}

class _CreateMaintenancePlanScreenState extends State<CreateMaintenancePlanScreen> {
  final _controller = CreateMaintenancePlanController();

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lập kế hoạch bảo trì'),
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
            child: SingleChildScrollView(          // ← đã thêm để hết overflow
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  const Text('Chu kỳ bảo trì của thiết bị này',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _controller.thietBiChon == null
                              ? Icons.hourglass_empty
                              : Icons.event_repeat,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _controller.thietBiChon == null
                                ? 'Chọn thiết bị bên trên để xem chu kỳ'
                                : (_controller.chuKyCoDinh != null
                                    ? '${_controller.thietBiChon!.tenThietBi} · ${_controller.chuKyCoDinh!.soThangChuKyDeXuat} tháng/lần'
                                    : 'Thiết bị "${_controller.thietBiChon!.tenThietBi}" chưa được gán chu kỳ trong hệ thống'),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _controller.chuKyCoDinh != null
                                  ? Colors.black87
                                  : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_controller.chuKyCoDinh != null)
                    Text(
                      'Chu kỳ này lấy theo đúng thiết bị bạn chọn, không thể sửa tay ở đây — mỗi thiết bị có chu kỳ riêng, muốn thay đổi phải cập nhật ở "Danh sách thiết bị".',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),

                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _controller.nam.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Năm áp dụng',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _controller.doiNam,
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'Bắt đầu kế hoạch',
                          value: _controller.ngayBatDau,
                          onPick: _controller.datNgayBatDau,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerField(
                          label: 'Kết thúc kế hoạch',
                          value: _controller.ngayKetThuc,
                          onPick: _controller.datNgayKetThuc,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  if (_controller.chiTietChon != null) ...[
                    const Divider(),
                    const Text('Ngày dự kiến bảo trì',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text(
                      'Ngày này luôn thuộc năm đã chọn ở trên.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.warning),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        title: Text(_controller.chiTietChon!.thietBi.tenThietBi),
                        subtitle: Text(
                            'Dự kiến: ${_formatNgay(_controller.chiTietChon!.ngayDuKienBaoTri)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_calendar, size: 20),
                          onPressed: _chonNgayDuKien,
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      'Chọn thiết bị và chu kỳ trước để lập kế hoạch',
                      style: TextStyle(color: Colors.grey),
                    ),

                  if (_controller.loi != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _controller.loi!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _controller.dangLuu ? null : _luu,
                    child: _controller.dangLuu
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Lưu kế hoạch'),
                  ),
                  const SizedBox(height: 16), // khoảng trống cuối
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final void Function(DateTime) onPick;
  const _DatePickerField({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text('${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'),
      ),
    );
  }
}

// ============ MÀN 3: CHI TIẾT KẾ HOẠCH (đã thêm nút "+ Thêm lần bảo trì") ============

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

  String _formatNgay(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _themLanBaoTri() async {
    final goiY = _controller.ngayGoiYLanTiepTheo;
    if (goiY == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa đủ dữ liệu chu kỳ để gợi ý ngày, vui lòng chọn thủ công')),
      );
    }
    final ngay = await showDatePicker(
      context: context,
      initialDate: goiY ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1, 1, 1),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      helpText: goiY != null ? 'Chọn ngày cho lần bảo trì tiếp theo (gợi ý: ${_formatNgay(goiY)})' : 'Chọn ngày cho lần bảo trì tiếp theo',
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
      appBar: AppBar(title: const Text('Chi tiết kế hoạch'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
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
            return const Center(child: Text('Chưa có lần bảo trì nào — bấm "Thêm lần bảo trì" để bắt đầu'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final ct = list[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(ct.tenThietBi, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Dự kiến bảo trì: ${_formatNgay(ct.ngayDuKienBaoTri)}'),
                  trailing: ct.daTaoHoSo
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
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