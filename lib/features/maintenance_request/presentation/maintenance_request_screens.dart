import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../equipment/data/equipment_logic.dart';
import '../data/maintenance_request_logic.dart';

// =============================================================================
// TTSX: Quản lý yêu cầu (Bảo trì / Sửa chữa) + nút +
// =============================================================================

class QuanLyYeuCauBaoTriScreen extends StatefulWidget {
  const QuanLyYeuCauBaoTriScreen({super.key});

  @override
  State<QuanLyYeuCauBaoTriScreen> createState() => _QuanLyYeuCauBaoTriScreenState();
}

class _QuanLyYeuCauBaoTriScreenState extends State<QuanLyYeuCauBaoTriScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _listCtrl = DanhSachYeuCauController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
    _listCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _listCtrl.tai();
  }

  @override
  void dispose() {
    _tab.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _moTaoYeuCau() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const TaoYeuCauBaoTriScreen(),
        fullscreenDialog: true,
      ),
    );
    if (created == true) {
      await _listCtrl.tai();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [
                Tab(text: 'Bảo trì'),
                Tab(text: 'Sửa chữa'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _DanhSachYeuCauBaoTriTab(controller: _listCtrl),
                const _PlaceholderSuaChuaTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton(
        onPressed: _moTaoYeuCau,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        child: const Icon(Icons.add_rounded, size: 28),
      )
          : null,
    );
  }
}

class _PlaceholderSuaChuaTab extends StatelessWidget {
  const _PlaceholderSuaChuaTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handyman_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Yêu cầu sửa chữa',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              'Chức năng đang được chuẩn bị.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DanhSachYeuCauBaoTriTab extends StatelessWidget {
  final DanhSachYeuCauController controller;
  const _DanhSachYeuCauBaoTriTab({required this.controller});

  Color _statusColor(String tt) {
    switch (tt) {
      case 'Chờ xác nhận':
        return AppColors.warning;
      case 'Đã xác nhận':
        return AppColors.success;
      case 'Từ chối':
        return AppColors.danger;
      case 'Đã tạo hồ sơ':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBoLoc() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Bộ lọc', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const Spacer(),
              if (controller.dangLoc)
                TextButton(
                  onPressed: controller.xoaLoc,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Xóa lọc', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Danh mục
          DropdownButtonFormField<String?>(
            value: controller.locDanhMuc,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Danh mục thiết bị',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Tất cả danh mục')),
              ...controller.cacDanhMuc.map(
                    (dm) => DropdownMenuItem(value: dm, child: Text(dm, overflow: TextOverflow.ellipsis)),
              ),
            ],
            onChanged: controller.datLocDanhMuc,
          ),
          const SizedBox(height: 10),
          // Thiết bị
          DropdownButtonFormField<int?>(
            value: controller.locMaThietBi,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Thiết bị',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Tất cả thiết bị')),
              ...controller.cacThietBi.map(
                    (t) => DropdownMenuItem(
                  value: t.ma,
                  child: Text(t.ten, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: controller.datLocThietBi,
          ),
          const SizedBox(height: 10),
          // Năm
          DropdownButtonFormField<int?>(
            value: controller.locNam,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Năm',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Tất cả năm')),
              ...controller.cacNam.map(
                    (n) => DropdownMenuItem(value: n, child: Text('$n')),
              ),
            ],
            onChanged: controller.datLocNam,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.dangTai) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.loi != null && controller.danhSachGoc.isEmpty) {
      return Center(child: Text(controller.loi!, style: const TextStyle(color: AppColors.danger)));
    }
    if (controller.danhSachGoc.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.tai,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Chưa có yêu cầu bảo trì',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Nhấn nút + để tạo yêu cầu mới',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final list = controller.danhSach;
    return RefreshIndicator(
      onRefresh: controller.tai,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
        itemCount: list.isEmpty ? 2 : list.length + 1, // +1 bộ lọc; +1 empty msg
        separatorBuilder: (context, i) {
          if (i == 0) return const SizedBox(height: 12);
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, i) {
          if (i == 0) return _buildBoLoc();
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'Không có yêu cầu khớp bộ lọc',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }
          final y = list[i - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCard(context, y),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, YeuCauBaoTriItem y) {
    final c = _statusColor(y.trangThai);
    final biTuChoi = y.trangThai == 'Từ chối';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  y.tenThietBi ?? 'Thiết bị #${y.maThietBi}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  y.trangThai,
                  style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'YC #${y.maYeuCauBaoTri} · ${y.danhMuc ?? '—'}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          Text(
            'Ngày BT: ${y.ngayBaoTri.day.toString().padLeft(2, '0')}/'
                '${y.ngayBaoTri.month.toString().padLeft(2, '0')}/'
                '${y.ngayBaoTri.year}'
                ' · ${y.thoiGianDuKien}h'
                '${y.gioBatDau != null ? ' · ${y.gioBatDau}–${y.gioKetThuc}' : ''}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (y.ghiChu != null && y.ghiChu!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              y.ghiChu!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
          ],
          if (y.lyDoTuChoi != null && y.lyDoTuChoi!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Lý do từ chối: ${y.lyDoTuChoi}',
              style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
            ),
          ],
          if (biTuChoi) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => TaoYeuCauBaoTriScreen(yeuCauSua: y),
                      fullscreenDialog: true,
                    ),
                  );
                  if (ok == true) await controller.tai();
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Chỉnh sửa & gửi lại xưởng',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// TTSX: Form tạo yêu cầu bảo trì (mở từ nút +)
// =============================================================================

class TaoYeuCauBaoTriScreen extends StatefulWidget {
  /// null = tạo mới; có giá trị = sửa yêu cầu bị từ chối
  final YeuCauBaoTriItem? yeuCauSua;

  const TaoYeuCauBaoTriScreen({super.key, this.yeuCauSua});

  @override
  State<TaoYeuCauBaoTriScreen> createState() => _TaoYeuCauBaoTriScreenState();
}

class _TaoYeuCauBaoTriScreenState extends State<TaoYeuCauBaoTriScreen> {
  final _c = TaoYeuCauBaoTriController();

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _init();
  }

  Future<void> _init() async {
    await _c.taiThietBi();
    if (widget.yeuCauSua != null) {
      await _c.napTuYeuCau(widget.yeuCauSua!);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    // Ngày bảo trì phải > ngày tạo yêu cầu (hôm nay)
    final minDay = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    var first = DateTime(_c.nam, _c.thang, 1);
    final last = DateTime(_c.nam, _c.thang + 1, 0);
    if (first.isBefore(minDay)) first = minDay;
    if (first.isAfter(last)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tháng đã chọn không còn ngày hợp lệ (phải sau ngày hôm nay).'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final initial = _c.ngayBaoTri != null && !_c.ngayBaoTri!.isBefore(first) ? _c.ngayBaoTri! : first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      _c.ngayBaoTri = picked;
      _c.notifyListeners();
    }
  }

  Future<void> _pickTime({required bool batDau}) async {
    if (!_c.thoiGianHopLe) return;
    final t = await showTimePicker(
      context: context,
      initialTime: batDau
          ? (_c.gioBatDau ?? const TimeOfDay(hour: 8, minute: 0))
          : (_c.gioKetThuc ?? const TimeOfDay(hour: 10, minute: 0)),
    );
    if (t == null) return;
    if (batDau) {
      _c.gioBatDau = t;
    } else {
      _c.gioKetThuc = t;
    }
    _c.notifyListeners();
  }

  Future<void> _gui() async {
    final ok = await _c.gui();
    if (!mounted) return;
    if (ok) {
      final msg = _c.dangSua
          ? 'Đã cập nhật và gửi lại yêu cầu cho xưởng.'
          : 'Đã gửi yêu cầu bảo trì.';
      _c.resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_c.loi ?? 'Không gửi được yêu cầu'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _fmtTime(TimeOfDay? t) =>
      t == null ? 'Chọn giờ' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_c.dangSua ? 'Sửa yêu cầu bảo trì' : 'Tạo yêu cầu bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _c.dangTai
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm thiết bị theo tên hoặc danh mục…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _c.setTimKiem,
          ),
          const SizedBox(height: 14),
          _card([
            const Text('Danh mục thiết bị', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _c.danhMucChon,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _c.cacDanhMuc
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: _c.chonDanhMuc,
              hint: const Text('Chọn danh mục'),
            ),
            const SizedBox(height: 14),
            const Text('Tên thiết bị', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ThietBiModel>(
              value: _c.thietBiChon,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _c.thietBiTheoDanhMuc
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.tenThietBi, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: _c.danhMucChon == null ? null : _c.chonThietBi,
              hint: Text(
                _c.danhMucChon == null ? 'Chọn danh mục trước' : 'Chọn thiết bị',
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _card([
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _c.thang,
                    decoration: const InputDecoration(
                      labelText: 'Tháng bảo trì',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text('Tháng $m')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _c.setThangNam(v, _c.nam);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _c.nam,
                    decoration: const InputDecoration(
                      labelText: 'Năm',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: [DateTime.now().year, DateTime.now().year + 1]
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _c.setThangNam(_c.thang, v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày bảo trì',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  child: Text(
                    _c.ngayBaoTri == null
                        ? 'Chọn ngày (sau ngày hôm nay)'
                        : '${_c.ngayBaoTri!.day.toString().padLeft(2, '0')}/'
                        '${_c.ngayBaoTri!.month.toString().padLeft(2, '0')}/'
                        '${_c.ngayBaoTri!.year}',
                    style: TextStyle(
                      color: _c.ngayBaoTri == null ? Colors.grey.shade600 : Colors.black87,
                      fontWeight: _c.ngayBaoTri == null ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ngày bảo trì phải sau ngày tạo yêu cầu.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c.thoiGianCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              ),
              decoration: InputDecoration(
                labelText: 'Thời gian dự kiến (giờ)',
                helperText: 'Số nguyên dương 1–24 (không thập phân)',
                border: const OutlineInputBorder(),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                errorText: _c.loiThoiGian,
                errorStyle: const TextStyle(fontSize: 12, height: 1.2),
                errorMaxLines: 2,
              ),
              onChanged: (_) {
                _c.validateThoiGian();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: _c.thoiGianHopLe ? 1 : 0.45,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                      _c.thoiGianHopLe ? () => _pickTime(batDau: true) : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(_fmtTime(_c.gioBatDau),
                          overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _c.thoiGianHopLe
                          ? () => _pickTime(batDau: false)
                          : null,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: Text(_fmtTime(_c.gioKetThuc),
                          overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_c.thoiGianHopLe)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Nhập số giờ nguyên hợp lệ (1–24) để chọn giờ bắt đầu / kết thúc.',
                  style: TextStyle(
                      fontSize: 11.5, color: Colors.grey.shade600, height: 1.3),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _c.ghiChuCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ]),
          if (_c.loi != null) ...[
            const SizedBox(height: 10),
            Text(_c.loi!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _c.dangGui ? null : _gui,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _c.dangGui
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Text(
              _c.dangSua ? 'Gửi lại yêu cầu cho xưởng' : 'Gửi yêu cầu bảo trì',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

// =============================================================================
// Xưởng (TTSX): Xác nhận yêu cầu bảo trì — Đồng ý / Từ chối
// =============================================================================

class XacNhanYeuCauBaoTriScreen extends StatefulWidget {
  const XacNhanYeuCauBaoTriScreen({super.key});

  @override
  State<XacNhanYeuCauBaoTriScreen> createState() => _XacNhanYeuCauBaoTriScreenState();
}

class _XacNhanYeuCauBaoTriScreenState extends State<XacNhanYeuCauBaoTriScreen> {
  final _c = XacNhanYeuCauController();

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _c.tai();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _dongY(YeuCauBaoTriItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đồng ý yêu cầu'),
        content: Text(
          'Đồng ý yêu cầu #${item.maYeuCauBaoTri} cho thiết bị '
              '"${item.tenThietBi ?? item.maThietBi}" '
              'ngày ${item.ngayBaoTri.day.toString().padLeft(2, '0')}/'
              '${item.ngayBaoTri.month.toString().padLeft(2, '0')}/'
              '${item.ngayBaoTri.year}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final success = await _c.xuLy(item.maYeuCauBaoTri, quyetDinh: 'Xác nhận');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã đồng ý yêu cầu.' : (_c.loi ?? 'Lỗi')),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  Future<void> _tuChoi(YeuCauBaoTriItem item) async {
    final lyDoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Từ chối yêu cầu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Từ chối YC #${item.maYeuCauBaoTri} — ${item.tenThietBi ?? item.maThietBi}. '
                  'Nhập lý do để Tổ trưởng cơ điện chỉnh sửa.',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lyDoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lý do từ chối *',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (lyDoCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    final lyDo = lyDoCtrl.text.trim();
    lyDoCtrl.dispose();
    if (ok != true || lyDo.isEmpty) return;

    final success = await _c.xuLy(item.maYeuCauBaoTri, quyetDinh: 'Từ chối', lyDo: lyDo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã từ chối yêu cầu.' : (_c.loi ?? 'Lỗi')),
        backgroundColor: success ? AppColors.warning : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_c.dangTai) return const Center(child: CircularProgressIndicator());
    if (_c.loi != null && _c.danhSach.isEmpty) {
      return Center(child: Text(_c.loi!, style: const TextStyle(color: AppColors.danger)));
    }
    if (_c.danhSach.isEmpty) {
      return RefreshIndicator(
        onRefresh: _c.tai,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(Icons.task_alt_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Không có yêu cầu chờ xác nhận',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _c.tai,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _c.danhSach.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final y = _c.danhSach[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.precision_manufacturing_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            y.tenThietBi ?? 'Thiết bị #${y.maThietBi}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'YC #${y.maYeuCauBaoTri} · ${y.danhMuc ?? '—'}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Chờ xác nhận',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.event_rounded,
                  'Ngày bảo trì: ${y.ngayBaoTri.day.toString().padLeft(2, '0')}/'
                      '${y.ngayBaoTri.month.toString().padLeft(2, '0')}/'
                      '${y.ngayBaoTri.year}',
                ),
                _infoRow(
                  Icons.schedule_rounded,
                  '${y.thoiGianDuKien} giờ'
                      '${y.gioBatDau != null ? ' · ${y.gioBatDau} – ${y.gioKetThuc}' : ''}',
                ),
                _infoRow(Icons.person_outline_rounded, 'Người gửi: ${y.tenNguoiYeuCau ?? '—'}'),
                if (y.ghiChu != null && y.ghiChu!.isNotEmpty)
                  _infoRow(Icons.notes_rounded, y.ghiChu!),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _tuChoi(y),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _dongY(y),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3)),
          ),
        ],
      ),
    );
  }
}