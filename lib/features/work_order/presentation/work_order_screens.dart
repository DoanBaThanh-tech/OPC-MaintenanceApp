import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';

// ============ MÀN 1: TẠO HỒ SƠ BẢO TRÌ (từ 1 dòng chi tiết kế hoạch) ============

class CreateWorkOrderBaoTriScreen extends StatefulWidget {
  final int maChiTietKeHoach;
  final int maThietBi;
  final String tenThietBi;
  const CreateWorkOrderBaoTriScreen({
    super.key,
    required this.maChiTietKeHoach,
    required this.maThietBi,
    required this.tenThietBi,
  });

  @override
  State<CreateWorkOrderBaoTriScreen> createState() => _CreateWorkOrderBaoTriScreenState();
}

class _CreateWorkOrderBaoTriScreenState extends State<CreateWorkOrderBaoTriScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noiDungController = TextEditingController();
  final _thoiGianController = TextEditingController(text: '4');
  bool _dangLuu = false;
  String? _loi;

  Future<void> _luu(bool guiDuyet) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _dangLuu = true; _loi = null; });
    try {
      await WorkOrderService.taoHoSoBaoTri(
        maChiTietKeHoach: widget.maChiTietKeHoach,
        maThietBi: widget.maThietBi,
        noiDungCongViec: _noiDungController.text.trim(),
        thoiGianDuKien: _thoiGianController.text.trim(),
        guiDuyet: guiDuyet,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  @override
  void dispose() {
    _noiDungController.dispose();
    _thoiGianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo hồ sơ bảo trì'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: Responsive(
        builder: (context, info) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: info.isMobile ? double.infinity : 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.precision_manufacturing_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(widget.tenThietBi, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _noiDungController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Nội dung công việc', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập nội dung công việc' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _thoiGianController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Thời gian dự kiến (giờ)', border: OutlineInputBorder()),
                      validator: (v) => (v == null || int.tryParse(v) == null) ? 'Vui lòng nhập số giờ hợp lệ' : null,
                    ),
                    if (_loi != null) ...[
                      const SizedBox(height: 12),
                      Text(_loi!, style: const TextStyle(color: AppColors.danger)),
                    ],
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _dangLuu ? null : () => _luu(false),
                          child: const Text('Lưu nháp'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _dangLuu ? null : () => _luu(true),
                          child: _dangLuu
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Tạo & Gửi duyệt'),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ MÀN 2: DANH SÁCH HỒ SƠ BẢO TRÌ (có tab lọc trạng thái) ============

class WorkOrderBaoTriListScreen extends StatefulWidget {
  const WorkOrderBaoTriListScreen({super.key});
  @override
  State<WorkOrderBaoTriListScreen> createState() => _WorkOrderBaoTriListScreenState();
}

class _WorkOrderBaoTriListScreenState extends State<WorkOrderBaoTriListScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<List<HoSoBaoTri>> _future;

  final _tabs = const ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Đang thực hiện', 'Từ chối'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _future = WorkOrderService.layDanhSachHoSoBaoTri();
  }

  void _taiLai() => setState(() => _future = WorkOrderService.layDanhSachHoSoBaoTri());

  Color _mau(String tt) {
    switch (tt) {
      case 'Đã duyệt': return const Color(0xFF0068A9);
      case 'Đang thực hiện': return const Color(0xFF1D4ED8);
      case 'Đã hoàn thành': return AppColors.success;
      case 'Từ chối': return AppColors.danger;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tab,
        isScrollable: true,
        labelColor: AppColors.primary,
        indicatorColor: AppColors.primary,
        tabs: _tabs.map((e) => Tab(text: e)).toList(),
      ),
      body: FutureBuilder<List<HoSoBaoTri>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
          final all = snap.data ?? [];

          return TabBarView(
            controller: _tab,
            children: _tabs.map((tab) {
              final list = tab == 'Tất cả' ? all : all.where((h) => h.trangThai == tab).toList();
              if (list.isEmpty) return const Center(child: Text('Không có hồ sơ nào'));
              return RefreshIndicator(
                onRefresh: () async => _taiLai(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final hs = list[i];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: _mau(hs.trangThai), width: 3, style: BorderStyle.solid),
                      ),
                      child: ListTile(
                        title: Text(hs.tenThietBi, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('#${hs.maHoSoBaoTri} · ${hs.ngayTao.day}/${hs.ngayTao.month}/${hs.ngayTao.year}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _mau(hs.trangThai).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text(hs.trangThai, style: TextStyle(color: _mau(hs.trangThai), fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ),
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => WorkOrderBaoTriDetailScreen(maHoSoBaoTri: hs.maHoSoBaoTri)),
                          );
                          if (changed == true) _taiLai();
                        },
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ============ MÀN 3: CHI TIẾT HỒ SƠ BẢO TRÌ + PHÂN CÔNG (khi đã duyệt) ============

class WorkOrderBaoTriDetailScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  const WorkOrderBaoTriDetailScreen({super.key, required this.maHoSoBaoTri});
  @override
  State<WorkOrderBaoTriDetailScreen> createState() => _WorkOrderBaoTriDetailScreenState();
}

class _WorkOrderBaoTriDetailScreenState extends State<WorkOrderBaoTriDetailScreen> {
  late Future<HoSoBaoTri> _future;

  @override
  void initState() {
    super.initState();
    _future = WorkOrderService.layChiTietHoSoBaoTri(widget.maHoSoBaoTri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hồ sơ bảo trì'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: FutureBuilder<HoSoBaoTri>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
          final hs = snap.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(hs.tenThietBi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('#${hs.maHoSoBaoTri} · ${hs.trangThai}', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nội dung công việc', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(hs.noiDungCongViec ?? '—'),
                        const SizedBox(height: 12),
                        Text('Thời gian dự kiến: ${hs.thoiGianDuKien ?? '—'} giờ'),
                        if (hs.lyDoTuChoi != null) ...[
                          const SizedBox(height: 12),
                          Text('Lý do từ chối: ${hs.lyDoTuChoi}', style: const TextStyle(color: AppColors.danger)),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (hs.daDuyetChuaPhanCong)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('Phân công nhân viên'),
                    onPressed: () async {
                      final ok = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PhanCongBaoTriScreen(maHoSoBaoTri: hs.maHoSoBaoTri)),
                      );
                      if (ok == true && mounted) Navigator.pop(context, true);
                    },
                  )
                else if (hs.choDuyet)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Đang chờ Giám đốc/Phó giám đốc duyệt')),
                    ]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============ MÀN 4: PHÂN CÔNG NHÂN VIÊN ============

class PhanCongBaoTriScreen extends StatefulWidget {
  final int maHoSoBaoTri;
  const PhanCongBaoTriScreen({super.key, required this.maHoSoBaoTri});
  @override
  State<PhanCongBaoTriScreen> createState() => _PhanCongBaoTriScreenState();
}

class _PhanCongBaoTriScreenState extends State<PhanCongBaoTriScreen> {
  List<NhanVienRutGon> _dsNhanVien = [];
  NhanVienRutGon? _chon;
  DateTime _ngayBatDau = DateTime.now();
  DateTime _ngayKetThuc = DateTime.now().add(const Duration(days: 1));
  bool _dangTai = true;
  bool _dangLuu = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _taiNhanVien();
  }

  Future<void> _taiNhanVien() async {
    try {
      final ds = await WorkOrderService.layDanhSachNhanVienKyThuat();
      setState(() { _dsNhanVien = ds; _dangTai = false; });
    } catch (e) {
      setState(() { _loi = 'Không tải được danh sách nhân viên'; _dangTai = false; });
    }
  }

  Future<void> _xacNhan() async {
    if (_chon == null) {
      setState(() => _loi = 'Vui lòng chọn nhân viên thực hiện');
      return;
    }
    setState(() { _dangLuu = true; _loi = null; });
    try {
      await WorkOrderService.phanCongBaoTri(
        maHoSoBaoTri: widget.maHoSoBaoTri,
        maNhanVienThucHien: _chon!.maNhanVien,
        ngayBatDau: _ngayBatDau,
        ngayKetThuc: _ngayKetThuc,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _loi = e.message);
    } finally {
      if (mounted) setState(() => _dangLuu = false);
    }
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phân công công việc'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: _dangTai
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Chọn nhân viên thực hiện', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ..._dsNhanVien.map((nv) => Card(
                        color: _chon?.maNhanVien == nv.maNhanVien ? AppColors.primary.withValues(alpha: 0.08) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: _chon?.maNhanVien == nv.maNhanVien ? AppColors.primary : Colors.transparent),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(nv.hoTen.isNotEmpty ? nv.hoTen[0] : '?')),
                          title: Text(nv.hoTen),
                          trailing: _chon?.maNhanVien == nv.maNhanVien ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                          onTap: () => setState(() => _chon = nv),
                        ),
                      )),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _ngayBatDau, firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (d != null) setState(() => _ngayBatDau = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Bắt đầu dự kiến', border: OutlineInputBorder()),
                          child: Text(_fmt(_ngayBatDau)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: _ngayKetThuc, firstDate: DateTime(2020), lastDate: DateTime(2100));
                          if (d != null) setState(() => _ngayKetThuc = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Kết thúc dự kiến', border: OutlineInputBorder()),
                          child: Text(_fmt(_ngayKetThuc)),
                        ),
                      ),
                    ),
                  ]),
                  if (_loi != null) ...[
                    const SizedBox(height: 12),
                    Text(_loi!, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _dangLuu ? null : _xacNhan,
                    child: _dangLuu
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Xác nhận phân công'),
                  ),
                ],
              ),
            ),
    );
  }
}