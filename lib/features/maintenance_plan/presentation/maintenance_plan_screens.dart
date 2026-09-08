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
  late Future<List<KeHoachBaoTri>> _future;

  @override
  void initState() {
    super.initState();
    _future = MaintenancePlanService.layDanhSachKeHoach();
  }

  Future<void> _taiLai() async {
    final future = MaintenancePlanService.layDanhSachKeHoach();
    setState(() => _future = future);
    await future;
  }

  Color _mauTrangThai(String tt) {
    switch (tt) {
      case 'Đã duyệt': return AppColors.success;
      case 'Từ chối': return AppColors.danger;
      default: return AppColors.warning;
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
          if (ok == true && mounted) await _taiLai();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<KeHoachBaoTri>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snap.error}'));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Chưa có kế hoạch bảo trì nào'));
          }
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
                    mau: _mauTrangThai(kh.trangThai),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MaintenancePlanDetailScreen(maKeHoach: kh.maKeHoach)),
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
                child: Text(keHoach.trangThai,
                    style: TextStyle(color: mau, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ MÀN 2: LẬP KẾ HOẠCH MỚI ============

class CreateMaintenancePlanScreen extends StatefulWidget {
  const CreateMaintenancePlanScreen({super.key});
  @override
  State<CreateMaintenancePlanScreen> createState() => _CreateMaintenancePlanScreenState();
}

class _CreateMaintenancePlanScreenState extends State<CreateMaintenancePlanScreen> {
  List<ChuKyBaoTriModel> _dsChuKy = [];
  ChuKyBaoTriModel? _chuKyChon;
  List<ThietBiRutGon> _dsThietBi = [];
  ThietBiRutGon? _thietBiChon;
  ChiTietKeHoachInput? _chiTietChon;

  int _nam = DateTime.now().year;
  DateTime _ngayBatDau = DateTime(DateTime.now().year, 1, 1);
  DateTime _ngayKetThuc = DateTime(DateTime.now().year, 12, 31);

  bool _dangTaiChuKy = true;
  bool _dangTaiThietBi = true;
  bool _dangLuu = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _taiChuKy();
  }

  Future<void> _taiChuKy() async {
    try {
      final results = await Future.wait([
        MaintenancePlanService.layDanhSachChuKy(),
        MaintenancePlanService.layDanhSachThietBi(),
      ]);
      setState(() {
        _dsChuKy = results[0] as List<ChuKyBaoTriModel>;
        _dsThietBi = results[1] as List<ThietBiRutGon>;
        _dangTaiChuKy = false;
        _dangTaiThietBi = false;
      });
    } catch (e) {
      setState(() { _loi = 'Không tải được danh sách chu kỳ'; _dangTaiChuKy = false; });
    }
  }

  void _chonThietBi(ThietBiRutGon? thietBi) {
    if (thietBi == null) return;
    setState(() {
      _thietBiChon = thietBi;
      _chuKyChon = null;
      _chiTietChon = null;
      _loi = null;
    });
  }

  List<ChuKyBaoTriModel> _chuKyPhuHop(ThietBiRutGon thietBi) {
    final cungLoai = _dsChuKy
        .where((chuKy) => chuKy.loaiThietBi == thietBi.loaiThietBi)
        .toList();
    return cungLoai.isEmpty ? _dsChuKy : cungLoai;
  }

  void _chonChuKy(ChuKyBaoTriModel? chuKy) {
    final thietBi = _thietBiChon;
    if (thietBi == null || chuKy == null) return;
    setState(() {
      _chuKyChon = chuKy;
      _chiTietChon = ChiTietKeHoachInput(
        thietBi: thietBi,
        ngayDuKienBaoTri: DateTime(_nam, 1, 1),
      );
      _loi = null;
    });
  }

  void _doiNam(String value) {
    final nam = int.tryParse(value);
    if (nam == null || nam < 2000 || nam > 2100) return;
    setState(() {
      _nam = nam;
      _ngayBatDau = DateTime(nam, 1, 1);
      _ngayKetThuc = DateTime(nam, 12, 31);
      if (_chiTietChon != null) _chiTietChon!.ngayDuKienBaoTri = DateTime(nam, 1, 1);
    });
  }

  Future<void> _chonNgayDuKien() async {
    final item = _chiTietChon;
    if (item == null) return;
    final ngay = await showDatePicker(
      context: context,
      initialDate: item.ngayDuKienBaoTri,
      firstDate: _ngayBatDau,
      lastDate: _ngayKetThuc,
    );
    if (ngay != null) setState(() => item.ngayDuKienBaoTri = ngay);
  }

  Future<void> _luuKeHoach() async {
    if (_chuKyChon == null) {
      setState(() => _loi = 'Vui lòng chọn chu kỳ bảo trì');
      return;
    }
    if (_chiTietChon == null || _thietBiChon == null) {
      setState(() => _loi = 'Vui lòng chọn thiết bị');
      return;
    }
    setState(() { _dangLuu = true; _loi = null; });
    try {
      await MaintenancePlanService.taoKeHoach(
        maChuKy: _chuKyChon!.maChuKy,
        nam: _nam,
        danhSachThietBi: [_chiTietChon!],
      );
      if (!mounted) return;
      Navigator.pop(context, true);
        } catch (e) {
      debugPrint('LỖI LƯU KẾ HOẠCH: $e'); // thêm dòng này
      setState(() {
        _loi = 'Đã có lỗi xảy ra ở hệ thống, vui lòng thử lại sau hoặc liên hệ quản trị viên.';
      });
    }
  }

  String _formatNgay(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lập kế hoạch bảo trì'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: _dangTaiChuKy
          ? const Center(child: CircularProgressIndicator())
          : Responsive(
              builder: (context, info) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: info.isMobile ? double.infinity : 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Thiết bị', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ThietBiRutGon>(
                        initialValue: _thietBiChon,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        hint: const Text('Chọn thiết bị cần lập kế hoạch'),
                        items: _dsThietBi
                            .map((tb) => DropdownMenuItem(value: tb, child: Text(tb.tenThietBi)))
                            .toList(),
                        onChanged: _chonThietBi,
                      ),
                      const SizedBox(height: 16),
                      const Text('Chu kỳ bảo trì', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ChuKyBaoTriModel>(
                        initialValue: _chuKyChon,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        hint: Text(_thietBiChon == null ? 'Chọn thiết bị trước' : 'Chu kỳ theo thiết bị'),
                        items: _thietBiChon == null
                            ? const []
                            : _chuKyPhuHop(_thietBiChon!)
                                .map((chuKy) => DropdownMenuItem(
                                      value: chuKy,
                                      child: Text(chuKy.nhan),
                                    ))
                                .toList(),
                        onChanged: _thietBiChon == null ? null : _chonChuKy,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _nam.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Năm áp dụng', border: OutlineInputBorder()),
                              onChanged: _doiNam,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              label: 'Bắt đầu kế hoạch',
                              value: _ngayBatDau,
                              onPick: (d) => setState(() => _ngayBatDau = DateTime(_nam, d.month, d.day)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DatePickerField(
                              label: 'Kết thúc kế hoạch',
                              value: _ngayKetThuc,
                              onPick: (d) => setState(() => _ngayKetThuc = DateTime(_nam, d.month, d.day)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Chọn thiết bị đưa vào kế hoạch',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (_dangTaiThietBi)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                      else if (_thietBiChon == null)
                        const Text('Chọn thiết bị trước để lập kế hoạch', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      if (_chiTietChon != null) ...[
                        const Divider(),
                        const Text('Ngày dự kiến bảo trì', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Ngày này luôn thuộc năm đã chọn ở trên.',
                            style: TextStyle(fontSize: 11.5, color: AppColors.warning)),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            title: Text(_chiTietChon!.thietBi.tenThietBi),
                            subtitle: Text('Dự kiến: ${_formatNgay(_chiTietChon!.ngayDuKienBaoTri)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_calendar, size: 20),
                              onPressed: _chonNgayDuKien,
                            ),
                          ),
                        ),
                      ],
                      if (_loi != null) ...[
                        const SizedBox(height: 12),
                        Text(_loi!, style: const TextStyle(color: AppColors.danger)),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _dangLuu ? null : _luuKeHoach,
                        child: _dangLuu
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Lưu kế hoạch'),
                      ),
                    ],
                  ),
                ),
              ),
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
        final d = await showDatePicker(
          context: context, initialDate: value,
          firstDate: DateTime(2020), lastDate: DateTime(2100),
        );
        if (d != null) onPick(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text('${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'),
      ),
    );
  }
}

// ============ MÀN 3: CHI TIẾT KẾ HOẠCH — bấm vào 1 thiết bị chưa có hồ sơ để tạo hồ sơ bảo trì ============

class MaintenancePlanDetailScreen extends StatefulWidget {
  final int maKeHoach;
  const MaintenancePlanDetailScreen({super.key, required this.maKeHoach});
  @override
  State<MaintenancePlanDetailScreen> createState() => _MaintenancePlanDetailScreenState();
}

class _MaintenancePlanDetailScreenState extends State<MaintenancePlanDetailScreen> {
  late Future<List<ChiTietKeHoach>> _future;

  @override
  void initState() {
    super.initState();
    _future = MaintenancePlanService.layChiTietKeHoach(widget.maKeHoach);
  }

  void _taiLai() => setState(() => _future = MaintenancePlanService.layChiTietKeHoach(widget.maKeHoach));

  String _formatNgay(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết kế hoạch'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: FutureBuilder<List<ChiTietKeHoach>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final ct = list[i];
              return Card(
                child: ListTile(
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
                            if (ok == true) _taiLai();
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