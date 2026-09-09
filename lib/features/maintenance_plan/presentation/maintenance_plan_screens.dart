import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/maintenance_plan_logic.dart';

// ============ BƯỚC 1: Đăng ký ngày muốn bảo trì cho 1 thiết bị ============

class DangKyNgayBaoTriScreen extends StatefulWidget {
  const DangKyNgayBaoTriScreen({super.key});
  @override State<DangKyNgayBaoTriScreen> createState()=>_DangKyNgayBaoTriScreenState();
}

class _DangKyNgayBaoTriScreenState extends State<DangKyNgayBaoTriScreen> {
  List<ThietBiRutGon> _dsThietBi = [];
  ThietBiRutGon? _thietBiChon;
  int _nam = DateTime.now().year;
  DateTime _ngayBaoTri = DateTime.now();
  bool _dangTai = true, _dangLuu = false;
  String? _loi;

  @override
  void initState() { super.initState(); _taiThietBi(); }

  Future<void> _taiThietBi() async {
    try {
      final ds = await MaintenancePlanService.layDanhSachThietBi();
      if (!mounted) return;
      setState(() { _dsThietBi = ds; _dangTai = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _dangTai = false; _loi = 'Không tải được danh sách thiết bị.'; });
    }
  }

  Future<void> _dangKy() async {
    if (_thietBiChon == null) { setState(() => _loi = 'Vui lòng chọn thiết bị.'); return; }
    setState(() { _dangLuu = true; _loi = null; });
    try {
      await MaintenancePlanService.taoYeuCauNgayBaoTri(
        maThietBi: _thietBiChon!.maThietBi, nam: _nam, ngayBaoTri: _ngayBaoTri,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _loi = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  String _formatNgay(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký ngày bảo trì'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: _dangTai ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Thiết bị', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<ThietBiRutGon>(
            initialValue: _thietBiChon,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: const Text('Chọn thiết bị cần bảo trì'),
            items: _dsThietBi.map((tb) => DropdownMenuItem(value: tb, child: Text(tb.tenThietBi))).toList(),
            onChanged: (v) => setState(() => _thietBiChon = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _nam.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Năm', border: OutlineInputBorder()),
            onChanged: (v) { final y = int.tryParse(v); if (y != null) setState(() => _nam = y); },
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _ngayBaoTri, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (d != null) setState(() => _ngayBaoTri = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Ngày muốn bảo trì', border: OutlineInputBorder()),
              child: Text(_formatNgay(_ngayBaoTri)),
            ),
          ),
          if (_loi != null) ...[
            const SizedBox(height: 12),
            Text(_loi!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _dangLuu ? null : _dangKy,
            child: _dangLuu
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Đăng ký'),
          ),
        ]),
      ),
    );
  }
}

// ============ BƯỚC 2: Lập kế hoạch từ 1 yêu cầu đã đăng ký ============

class LapKeHoachTuYeuCauScreen extends StatefulWidget {
  const LapKeHoachTuYeuCauScreen({super.key});
  @override State<LapKeHoachTuYeuCauScreen> createState()=>_LapKeHoachTuYeuCauScreenState();
}

class _LapKeHoachTuYeuCauScreenState extends State<LapKeHoachTuYeuCauScreen> {
  late Future<List<YeuCauNgayBaoTri>> _future;
  bool _dangLap = false;
  String? _loi;

  @override
  void initState() { super.initState(); _future = MaintenancePlanService.layYeuCauChoLapKeHoach(); }

  void _taiLai() => setState(() => _future = MaintenancePlanService.layYeuCauChoLapKeHoach());

  String _formatNgay(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  Future<void> _lapKeHoach(YeuCauNgayBaoTri yc) async {
    setState(() { _dangLap = true; _loi = null; });
    try {
      await MaintenancePlanService.lapKeHoachTuYeuCau(maYeuCauNgayBaoTri: yc.maYeuCauNgayBaoTri, nam: yc.nam);
      if (!mounted) return;
      Navigator.pop(context, true); // báo màn Quản lý kế hoạch tự tải lại
    } catch (e) {
      setState(() => _loi = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _dangLap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lập kế hoạch bảo trì'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: Column(children: [
        if (_loi != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.danger.withValues(alpha: .08),
            child: Text(_loi!, style: const TextStyle(color: AppColors.danger)),
          ),
        Expanded(
          child: FutureBuilder<List<YeuCauNgayBaoTri>>(
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
                return const Center(child: Text('Không có yêu cầu nào đang chờ lập kế hoạch.\nHãy đăng ký ngày bảo trì trước.', textAlign: TextAlign.center));
              }
              return RefreshIndicator(
                onRefresh: () async => _taiLai(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final yc = list[i];
                    return Card(
                      child: ListTile(
                        title: Text(yc.tenThietBi, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${yc.loaiThietBi ?? ""} · Chu kỳ ${yc.soThangChuKy} tháng · Dự kiến ${_formatNgay(yc.ngayBaoTri)}'),
                        trailing: ElevatedButton(
                          onPressed: _dangLap ? null : () => _lapKeHoach(yc),
                          child: const Text('Lập KH'),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}