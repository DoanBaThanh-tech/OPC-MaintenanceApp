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
      appBar: AppBar(
        title: const Text('Tạo hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ResponsiveCenteredContent(
        maxContentWidth: 500,
        padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    const Icon(Icons.precision_manufacturing_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(widget.tenThietBi, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
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
                builder: (context, _) => Row(
                  children: [
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
                  ],
                ),
              ),
            ],
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

  void _moBoLocNam(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final nams = _controller.cacNamCoKeHoach;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text('Lọc theo năm kế hoạch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Chỉ hiển thị những năm đã có kế hoạch bảo trì được lập',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  if (nams.isEmpty)
                    const Text('Chưa có kế hoạch bảo trì nào được lập', style: TextStyle(color: Colors.grey))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chipNam(context, nhan: 'Tất cả', giaTri: null),
                        for (final n in nams) _chipNam(context, nhan: 'Năm $n', giaTri: n),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _chipNam(BuildContext context, {required String nhan, required int? giaTri}) {
    final dangChon = _controller.namLoc == giaTri;
    return ChoiceChip(
      label: Text(nhan),
      selected: dangChon,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: dangChon ? Colors.white : Colors.black87,
        fontWeight: dangChon ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: dangChon ? AppColors.primary : Colors.grey.shade300),
      ),
      onSelected: (_) {
        _controller.datNamLoc(giaTri);
        Navigator.pop(context);
      },
    );
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
      appBar: AppBar(
        title: const Text('Hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => IconButton(
              icon: Badge(
                isLabelVisible: _controller.namLoc != null,
                label: Text('${_controller.namLoc}', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.filter_alt_rounded),
              ),
              onPressed: () => _moBoLocNam(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: _tabs.map((e) => Tab(text: e)).toList(),
        ),
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
                        subtitle: Row(
                          children: [
                            Text('#${hs.maHoSoBaoTri} · ${hs.ngayTao.day}/${hs.ngayTao.month}/${hs.ngayTao.year}'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'KH ${hs.nam}${hs.namTuKeHoach ? '' : ' (đột xuất)'}',
                                style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
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
                        _dong('Ngày bảo trì dự kiến', _fmt(hs.ngayDuKienBaoTri)),
                        if (hs.thoiGianDuKien != null) ...[
                          const Divider(height: 20),
                          _dong('Thời gian dự kiến', '${hs.thoiGianDuKien} giờ'),
                        ],
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

                // Lý do từ chối (chỉ hiện khi bị từ chối)
                if (hs.biTuChoi && hs.lyDoTuChoi != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: AppColors.danger.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lý do từ chối',
                              style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(hs.lyDoTuChoi!, style: const TextStyle(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Nút hành động
                if (hs.daDuyetChuaPhanCong)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('Phân công nhân viên'),
                    onPressed: () async {
                      final ok = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PhanCongBaoTriScreen(maHoSoBaoTri: hs.maHoSoBaoTri)),
                      );
                      if (ok == true && mounted) Navigator.pop(context, true);
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

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _chonGio({required bool isBatDau}) async {
    final initial = isBatDau ? _controller.gioBatDau : _controller.gioKetThuc;
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
    if (picked != null) {
      if (isBatDau) {
        _controller.datGioBatDau(picked);
      } else {
        _controller.datGioKetThuc(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân công công việc'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== Người phân công =====
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: const Text('Người phân công', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(
                      _controller.tenNguoiPhanCong ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Nhân viên thực hiện =====
                const Text('Nhân viên thực hiện', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),

                if (_controller.dsNhanVien.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          _controller.loi ?? 'Không có nhân viên kỹ thuật nào trong hệ thống.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ],
                    ),
                  )
                else
                  ..._controller.dsNhanVien.map((nv) {
                    final dangChon = _controller.chon?.maNhanVien == nv.maNhanVien;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: dangChon ? 2 : 0,
                      color: dangChon ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: dangChon ? AppColors.primary : Colors.grey.shade200,
                          width: dangChon ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: dangChon ? AppColors.primary : Colors.grey.shade300,
                          child: Text(
                            nv.hoTen.isNotEmpty ? nv.hoTen[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: dangChon ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(nv.hoTen, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          [
                            if (nv.chucVu != null && nv.chucVu!.isNotEmpty) nv.chucVu!,
                            if (nv.soDienThoai != null && nv.soDienThoai!.isNotEmpty) nv.soDienThoai!,
                          ].join(' · '),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        trailing: dangChon
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : const Icon(Icons.circle_outlined, color: Colors.grey),
                        onTap: () => _controller.chonNhanVien(nv),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                // ===== Thời gian (chỉ giờ) =====
                const Text('Thời gian thực hiện', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PickerField(
                        label: 'Giờ bắt đầu',
                        value: _fmtTime(_controller.gioBatDau),
                        icon: Icons.access_time_rounded,
                        onTap: () => _chonGio(isBatDau: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerField(
                        label: 'Giờ kết thúc',
                        value: _fmtTime(_controller.gioKetThuc),
                        icon: Icons.access_time_rounded,
                        onTap: () => _chonGio(isBatDau: false),
                      ),
                    ),
                  ],
                ),

                if (_controller.loi != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                  ),
                ],

                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _controller.dangLuu ? null : _xacNhan,
                  child: _controller.dangLuu
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Xác nhận phân công', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: Icon(icon, size: 18),
        ),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}