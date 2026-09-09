import 'package:flutter/material.dart';
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
  final _controller = CreateWorkOrderBaoTriController();
  final _formKey = GlobalKey<FormState>();
  final _noiDungController = TextEditingController();
  final _thoiGianController = TextEditingController(text: '4');

  @override
  void dispose() {
    _controller.dispose();
    _noiDungController.dispose();
    _thoiGianController.dispose();
    super.dispose();
  }

  Future<void> _luu(bool guiDuyet) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _controller.luu(
      maChiTietKeHoach: widget.maChiTietKeHoach,
      maThietBi: widget.maThietBi,
      noiDungCongViec: _noiDungController.text.trim(),
      thoiGianDuKien: _thoiGianController.text.trim(),
      guiDuyet: guiDuyet,
    );
    if (ok && mounted) Navigator.pop(context, true);
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
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        if (_controller.loi == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _controller.dangLuu ? null : () => _luu(false),
                            child: const Text('Lưu nháp'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _controller.dangLuu ? null : () => _luu(true),
                            child: _controller.dangLuu
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Tạo & Gửi duyệt'),
                          ),
                        ),
                      ]),
                    ),
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
  final _controller = WorkOrderBaoTriListController();
  late TabController _tab;

  final _tabs = const ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Đang thực hiện', 'Từ chối'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _controller.taiDanhSach();
  }

  @override
  void dispose() {
    _tab.dispose();
    _controller.dispose();
    super.dispose();
  }

  Color _mau(TrangThaiHoSoBaoTri tt) {
    switch (tt) {
      case TrangThaiHoSoBaoTri.daDuyet:
        return const Color(0xFF0068A9);
      case TrangThaiHoSoBaoTri.dangThucHien:
        return const Color(0xFF1D4ED8);
      case TrangThaiHoSoBaoTri.daHoanThanh:
        return AppColors.success;
      case TrangThaiHoSoBaoTri.tuChoi:
        return AppColors.danger;
      case TrangThaiHoSoBaoTri.choDuyet:
      case TrangThaiHoSoBaoTri.khac:
        return AppColors.warning;
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
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) return const Center(child: CircularProgressIndicator());
          if (_controller.loi != null) return Center(child: Text(_controller.loi!));

          return TabBarView(
            controller: _tab,
            children: _tabs.map((tab) {
              final list = _controller.locTheoTab(tab);
              if (list.isEmpty) return const Center(child: Text('Không có hồ sơ nào'));
              return RefreshIndicator(
                onRefresh: _controller.taiDanhSach,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final hs = list[i];
                    final mau = _mau(phanLoaiTrangThaiHoSo(hs.trangThai));
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: mau, width: 3, style: BorderStyle.solid),
                      ),
                      child: ListTile(
                        title: Text(hs.tenThietBi, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('#${hs.maHoSoBaoTri} · ${hs.ngayTao.day}/${hs.ngayTao.month}/${hs.ngayTao.year}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: mau.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text(hs.trangThai, style: TextStyle(color: mau, fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ),
                        onTap: () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => WorkOrderBaoTriDetailScreen(maHoSoBaoTri: hs.maHoSoBaoTri)),
                          );
                          if (changed == true) _controller.taiDanhSach();
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
  late final WorkOrderBaoTriDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WorkOrderBaoTriDetailController(widget.maHoSoBaoTri);
    _controller.taiChiTiet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết hồ sơ bảo trì'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) return const Center(child: CircularProgressIndicator());
          if (_controller.loi != null) return Center(child: Text(_controller.loi!));
          final hs = _controller.hoSo!;

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
  final _controller = PhanCongBaoTriController();

  @override
  void initState() {
    super.initState();
    _controller.taiNhanVien();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _xacNhan() async {
    final ok = await _controller.xacNhan(widget.maHoSoBaoTri);
    if (ok && mounted) Navigator.pop(context, true);
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phân công công việc'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.dangTai) return const Center(child: CircularProgressIndicator());
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Chọn nhân viên thực hiện', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ..._controller.dsNhanVien.map((nv) => Card(
                      color: _controller.chon?.maNhanVien == nv.maNhanVien ? AppColors.primary.withValues(alpha: 0.08) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _controller.chon?.maNhanVien == nv.maNhanVien ? AppColors.primary : Colors.transparent),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(nv.hoTen.isNotEmpty ? nv.hoTen[0] : '?')),
                        title: Text(nv.hoTen),
                        trailing: _controller.chon?.maNhanVien == nv.maNhanVien ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                        onTap: () => _controller.chonNhanVien(nv),
                      ),
                    )),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _controller.ngayBatDau,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) _controller.datNgayBatDau(d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Bắt đầu dự kiến', border: OutlineInputBorder()),
                        child: Text(_fmt(_controller.ngayBatDau)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _controller.ngayKetThuc,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) _controller.datNgayKetThuc(d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Kết thúc dự kiến', border: OutlineInputBorder()),
                        child: Text(_fmt(_controller.ngayKetThuc)),
                      ),
                    ),
                  ),
                ]),
                if (_controller.loi != null) ...[
                  const SizedBox(height: 12),
                  Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _controller.dangLuu ? null : _xacNhan,
                  child: _controller.dangLuu
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Xác nhận phân công'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}