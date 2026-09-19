import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/work_order_logic.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_exception.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo hồ sơ bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 500,
                    minWidth: constraints.maxWidth > 500 ? 0 : constraints.maxWidth - 40,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.14),
                                AppColors.primary.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.precision_manufacturing_rounded, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thiết bị',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.tenThietBi,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: const Text(
                            'Ngày bảo trì thực tế do xưởng chốt đã nằm trong kế hoạch. '
                                'Khi phân công công việc bạn sẽ chọn khung giờ thực hiện chi tiết.',
                            style: TextStyle(fontSize: 12.5, height: 1.35),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Nội dung công việc', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noiDungController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Mô tả công việc bảo trì…',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập nội dung công việc' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('Thời gian dự kiến (giờ)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _thoiGianController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                          decoration: const InputDecoration(
                            hintText: 'Ví dụ: 4',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.schedule),
                            suffixText: 'giờ',
                          ),
                          // Chỉ cho số dương; chữ / ký tự đặc biệt / số âm → báo lỗi đỏ ngay dưới ô
                          validator: (v) {
                            final raw = v?.trim() ?? '';
                            if (raw.isEmpty) {
                              return 'Vui lòng nhập giờ dự kiến bảo trì';
                            }
                            // Chỉ chấp nhận chuỗi toàn chữ số (không dấu âm, không chữ, không ký tự đặc biệt)
                            if (!RegExp(r'^\d+$').hasMatch(raw)) {
                              return 'Chỉ được nhập số dương (không chữ, không ký tự đặc biệt)';
                            }
                            final so = int.tryParse(raw);
                            if (so == null || so <= 0) {
                              return 'Giờ dự kiến phải là số dương lớn hơn 0';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        const SizedBox(height: 28),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _controller.dangLuu ? null : () => _luu(false),
                                    child: const Text('Lưu nháp', maxLines: 1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _controller.dangLuu ? null : () => _luu(true),
                                    child: _controller.dangLuu
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                        : const Text('Gửi duyệt', maxLines: 1),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: MediaQuery.viewInsetsOf(context).bottom + 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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

  final _tabs = const ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Đang thực hiện','Đã hoàn thành','Từ chối'];

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
                        title: Text(
                          hs.tenThietBi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '#${hs.maHoSoBaoTri} · ${hs.ngayTao.day}/${hs.ngayTao.month}/${hs.ngayTao.year}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'KH ${hs.nam}${hs.namTuKeHoach ? '' : ' (đột xuất)'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: mau.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              hs.trangThai,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: mau, fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                          ),
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

  String? _vaiTro;

  bool get _laToTruong =>
      _vaiTro == 'Tổ trưởng kỹ thuật' || _vaiTro == 'Tổ trưởng';
  bool get _laNvkt => _vaiTro == 'Nhân viên kỹ thuật';

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
                // Nút hành động theo trạng thái + vai trò
                if (hs.daDuyetChuaPhanCong && _laToTruong)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('Phân công nhân viên'),
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
                      child: const Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Đã phân công — chờ nhân viên kỹ thuật xác nhận nhận việc'),
                          ),
                        ],
                      ),
                    )
                  else if (hs.biTuChoi && _laToTruong)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Chỉnh sửa & gửi lại duyệt'),
                        onPressed: () async {
                          final ok = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SuaHoSoBiTuChoiScreen(hoSo: hs),
                            ),
                          );
                          if (ok == true && mounted) {
                            await _controller.taiChiTiet();
                          }
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

  bool get _choPhepChonGioBatDau =>
      _loiThoiGian == null &&
          _thoiGian.text.trim().isNotEmpty &&
          (int.tryParse(_thoiGian.text.trim()) ?? 0) > 0;

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
    _controller.khoiTao(widget.maHoSoBaoTri);
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

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '—';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Phân công công việc'),
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

          final hs = _controller.hoSo;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // ===== Header hồ sơ =====
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.precision_manufacturing_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hs?.tenThietBi ?? 'Thiết bị',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Hồ sơ #${widget.maHoSoBaoTri}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Người phân công: ${_controller.tenNguoiPhanCong ?? '—'}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Khung giờ từ hồ sơ (chỉ đọc) =====
                    Container(
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
                          Row(
                            children: [
                              Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Khung giờ theo hồ sơ',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Giờ lấy đúng từ hồ sơ bảo trì đã tạo — không chỉnh tại đây',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeInfoChip(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Ngày bảo trì',
                                  value: _fmtDate(_controller.ngayDuKien),
                                  color: const Color(0xFF0068A9),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeInfoChip(
                                  icon: Icons.play_circle_rounded,
                                  label: 'Giờ bắt đầu',
                                  value: _fmtTime(_controller.gioBatDau),
                                  color: const Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TimeInfoChip(
                                  icon: Icons.stop_circle_rounded,
                                  label: 'Giờ kết thúc',
                                  value: _fmtTime(_controller.gioKetThuc),
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ===== Chọn NVKT =====
                    const Text(
                      'Chọn nhân viên thực hiện',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Có thể chọn mọi NVKT. Hệ thống chỉ chặn khi trùng khung giờ (phía server).',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),

                    if (_controller.dsNhanVien.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _controller.loi ?? 'Không có nhân viên kỹ thuật trong hệ thống.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._controller.dsNhanVien.map((nv) {
                        final dangChon = _controller.chon?.maNhanVien == nv.maNhanVien;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: dangChon
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => _controller.chonNhanVien(nv), // luôn cho chọn
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: dangChon ? AppColors.primary : Colors.grey.shade200,
                                    width: dangChon ? 1.6 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor:
                                      dangChon ? AppColors.primary : Colors.grey.shade200,
                                      child: Text(
                                        nv.hoTen.isNotEmpty ? nv.hoTen[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: dangChon ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nv.hoTen,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            [
                                              if (nv.chucVu != null && nv.chucVu!.isNotEmpty) nv.chucVu!,
                                              if (nv.soDienThoai != null && nv.soDienThoai!.isNotEmpty)
                                                nv.soDienThoai!,
                                              if (nv.soCongViecDangLam > 0)
                                                'Đang làm ${nv.soCongViecDangLam} việc',
                                            ].where((s) => s.isNotEmpty).join(' · '),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (dangChon)
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.primary, size: 26)
                                    else
                                      Icon(Icons.circle_outlined, color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                    if (_controller.loi != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_controller.loi!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ],
                ),
              ),

              // ===== Nút xác nhận cố định dưới =====
              Container(
                padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _controller.dangLuu ? null : _xacNhan,
                    icon: _controller.dangLuu
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.assignment_ind_rounded),
                    label: Text(
                      _controller.dangLuu ? 'Đang phân công...' : 'Xác nhận phân công',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
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

class _TimeInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimeInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
        ],
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

// ============ MÀN 5: LỊCH SỬ PHÂN CÔNG ============

class LichSuPhanCongScreen extends StatefulWidget {
  const LichSuPhanCongScreen({super.key});

  @override
  State<LichSuPhanCongScreen> createState() => _LichSuPhanCongScreenState();
}

class _LichSuPhanCongScreenState extends State<LichSuPhanCongScreen> {
  final _controller = LichSuPhanCongController();

  @override
  void initState() {
    super.initState();
    _controller.tai();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmtNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtGio(DateTime? d) {
    if (d == null) return '—';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _huyPhanCong(LichSuPhanCong item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy phân công?'),
        content: Text(
          'Phân công #${item.maPhanCong} sẽ bị xóa.\n'
              'Hồ sơ bảo trì/sửa chữa sẽ về trạng thái Đã duyệt và có thể phân công lại.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy phân công'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _controller.huyPhanCong(item.maPhanCong);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã hủy phân công. Có thể phân công lại trên hồ sơ.' : (_controller.loi ?? 'Lỗi')),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Color _mauTrangThai(String tt) {
    switch (tt) {
      case 'Hoàn thành':
        return AppColors.success;
      case 'Xác nhận':
        return AppColors.success;
      case 'Đã phân công':
      case 'Chờ xác nhận':
        return AppColors.warning;
      case 'Từ chối':
        return AppColors.danger;
      case 'Đang thực hiện':
        return const Color(0xFF7C3AED);
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
                  Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(_controller.loi!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _controller.tai,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        if (_controller.danhSach.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('Chưa có lần phân công nào', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.tai,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: _controller.danhSach.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = _controller.danhSach[i];
              final mau = _mauTrangThai(item.trangThai);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [mau.withValues(alpha: 0.12), mau.withValues(alpha: 0.04)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: mau.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.assignment_ind_rounded, color: mau, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phân công #${item.maPhanCong}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ngày phân công: ${_fmtNgay(item.ngayPhanCong)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: mau.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.trangThai,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: mau, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        children: [
                          _HistoryRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Người phân công',
                            value: item.tenNhanVienPhanCong ?? '—',
                          ),
                          const SizedBox(height: 10),
                          _HistoryRow(
                            icon: Icons.engineering_rounded,
                            label: 'Nhân viên thực hiện',
                            value: item.tenNhanVienThucHien ?? '—',
                          ),
                          if (item.tenThietBi != null && item.tenThietBi!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _HistoryRow(
                              icon: Icons.precision_manufacturing_outlined,
                              label: 'Thiết bị',
                              value: item.tenThietBi!,
                            ),
                          ],
                          if (item.lyDoTuChoi != null && item.lyDoTuChoi!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _HistoryRow(
                              icon: Icons.info_outline_rounded,
                              label: 'Lý do từ chối',
                              value: item.lyDoTuChoi!,
                            ),
                          ],
                          const Divider(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeChip(
                                  icon: Icons.play_circle_outline_rounded,
                                  label: 'Giờ bắt đầu',
                                  value: _fmtGio(item.gioBatDau),
                                  color: const Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TimeChip(
                                  icon: Icons.stop_circle_outlined,
                                  label: 'Giờ kết thúc',
                                  value: _fmtGio(item.gioKetThuc),
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          if (item.trangThai == 'Chờ xác nhận' ||
                              item.trangThai == 'Từ chối') ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _controller.dangHuy ? null : () => _huyPhanCong(item),
                                icon: const Icon(Icons.cancel_outlined, size: 18),
                                label: const Text('Hủy phân công'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HistoryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _TimeChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}