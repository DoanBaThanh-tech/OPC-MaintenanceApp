import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../equipment/data/equipment_logic.dart';
import '../data/maintenance_request_logic.dart';

// ============ TTSX: Quản lý yêu cầu (list + FAB tạo) ============

class QuanLyYeuCauSanXuatScreen extends StatefulWidget {
  const QuanLyYeuCauSanXuatScreen({super.key});

  @override
  State<QuanLyYeuCauSanXuatScreen> createState() => _QuanLyYeuCauSanXuatScreenState();
}

class _QuanLyYeuCauSanXuatScreenState extends State<QuanLyYeuCauSanXuatScreen>
    with SingleTickerProviderStateMixin {
  final _c = QuanLyYeuCauController();
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      _c.doiTab(_tab.index == 0 ? 'Bảo trì' : 'Sửa chữa');
    });
    _c.addListener(() {
      if (mounted) setState(() {});
    });
    _c.tai();
  }

  @override
  void dispose() {
    _tab.dispose();
    _c.dispose();
    super.dispose();
  }

  String _fmtNgay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Color _mauTT(String tt) {
    switch (tt) {
      case 'Đã xác nhận':
      case 'Đã tạo hồ sơ':
        return const Color(0xFF2E7D32);
      case 'Chờ xác nhận':
        return const Color(0xFFED6C02);
      case 'Từ chối':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF546E7A);
    }
  }

  Future<void> _moTao() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TaoYeuCauBaoTriScreen()),
    );
    if (ok == true && mounted) await _c.tai();
  }

  @override
  Widget build(BuildContext context) {
    final isBaoTri = _tab.index == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isBaoTri
          ? FloatingActionButton(
        onPressed: _moTao,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        tooltip: 'Tạo yêu cầu bảo trì',
        child: const Icon(Icons.add_rounded, size: 28),
      )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.primary,
            child: TabBar(
              controller: _tab,
              indicatorColor: Colors.white,
              indicatorWeight: 2.5,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              tabs: const [
                Tab(text: 'Bảo trì'),
                Tab(text: 'Sửa chữa'),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_c.dangTai) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_c.loi != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_c.loi!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
        ),
      );
    }

    if (_c.danhSach.isEmpty) {
      return RefreshIndicator(
        onRefresh: _c.tai,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.description_outlined, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              _tab.index == 1 ? 'Chưa có yêu cầu sửa chữa' : 'Chưa có yêu cầu bảo trì',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tab.index == 1
                  ? 'Phần sửa chữa sẽ được bổ sung sau.'
                  : 'Nhấn nút + góc dưới để tạo yêu cầu mới.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.35),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _c.tai,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
        itemCount: _c.danhSach.length,
        itemBuilder: (context, i) {
          final y = _c.danhSach[i];
          final mau = _mauTT(y.trangThai);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              y.tenThietBi ?? 'Thiết bị #${y.maThietBi}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: mau.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              y.trangThai,
                              style: TextStyle(
                                color: mau,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'YC #${y.maYeuCauBaoTri}  ·  ${y.danhMuc ?? '—'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmtNgay(y.ngayBaoTri)}  ·  ${y.thoiGianDuKien}h  ·  ${y.gioBatDau ?? '—'}–${y.gioKetThuc ?? '—'}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============ Form tạo YC (mở từ nút +) ============

class TaoYeuCauBaoTriScreen extends StatefulWidget {
  const TaoYeuCauBaoTriScreen({super.key});

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
    _c.taiThietBi();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final homNay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final firstInMonth = DateTime(_c.nam, _c.thang, 1);
    final last = DateTime(_c.nam, _c.thang + 1, 0);
    // Ngày tối thiểu: sau hôm nay và trong tháng
    var first = firstInMonth.isAfter(homNay) ? firstInMonth : homNay.add(const Duration(days: 1));
    if (first.isAfter(last)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tháng này không còn ngày hợp lệ (phải sau ngày hôm nay).')),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _c.ngayBaoTri != null && !_c.ngayBaoTri!.isBefore(first) ? _c.ngayBaoTri! : first,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) _c.setNgayBaoTri(picked);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã gửi yêu cầu bảo trì.' : (_c.loi ?? 'Lỗi')),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
    if (ok) Navigator.pop(context, true);
  }

  String _fmtTime(TimeOfDay? t) =>
      t == null ? 'Chọn giờ' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tạo yêu cầu bảo trì'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _c.dangTai
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm thiết bị theo tên...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
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
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _c.cacDanhMuc
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: _c.chonDanhMuc,
              hint: const Text('Chọn danh mục'),
            ),
            const SizedBox(height: 14),
            const Text('Tên thiết bị', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ThietBiModel>(
              value: _c.thietBiChon,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _c.thietBiTheoDanhMuc
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e.tenThietBi, overflow: TextOverflow.ellipsis),
              ))
                  .toList(),
              onChanged: _c.danhMucChon == null ? null : _c.chonThietBi,
              hint: const Text('Chọn thiết bị'),
            ),
          ]),
          const SizedBox(height: 12),
          _card([
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _c.thang,
                    decoration: const InputDecoration(labelText: 'Tháng', border: OutlineInputBorder()),
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
                    decoration: const InputDecoration(labelText: 'Năm', border: OutlineInputBorder()),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ngày bảo trì'),
              subtitle: Text(
                _c.ngayBaoTri == null
                    ? 'Phải sau ngày tạo yêu cầu'
                    : '${_c.ngayBaoTri!.day.toString().padLeft(2, '0')}/${_c.ngayBaoTri!.month.toString().padLeft(2, '0')}/${_c.ngayBaoTri!.year}',
              ),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: _pickDate,
            ),
            if (_c.loiNgay != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_c.loiNgay!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ),
            TextField(
              controller: _c.thoiGianCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                labelText: 'Thời gian dự kiến (giờ)',
                border: const OutlineInputBorder(),
                errorText: _c.loiThoiGian,
                helperText: 'Số dương — hợp lệ mới chọn được giờ',
              ),
              onChanged: _c.onThoiGianChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _c.thoiGianHopLe ? () => _pickTime(batDau: true) : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(_fmtTime(_c.gioBatDau)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _c.thoiGianHopLe ? () => _pickTime(batDau: false) : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(_fmtTime(_c.gioKetThuc)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c.ghiChuCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tuỳ chọn)',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
          if (_c.loi != null) ...[
            const SizedBox(height: 10),
            Text(_c.loi!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _c.dangGui ? null : _gui,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _c.dangGui
                ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Gửi yêu cầu bảo trì'),
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

// ============ TTKT: Xác nhận yêu cầu (chỉ nút Xác nhận) ============

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

  Future<void> _xacNhan(YeuCauBaoTriItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận yêu cầu?'),
        content: Text(
          'YC #${item.maYeuCauBaoTri} · ${item.tenThietBi ?? ""}\n'
              'Sau khi xác nhận có thể lập bảo trì cho thiết bị này.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _c.xacNhan(item.maYeuCauBaoTri);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Đã xác nhận yêu cầu.' : (_c.loi ?? 'Lỗi')),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_c.dangTai) return const Center(child: CircularProgressIndicator());
    if (_c.loi != null && _c.danhSach.isEmpty) {
      return Center(child: Text(_c.loi!));
    }
    if (_c.danhSach.isEmpty) {
      return RefreshIndicator(
        onRefresh: _c.tai,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(Icons.task_alt_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Center(
              child: Text('Không có yêu cầu chờ xác nhận', style: TextStyle(color: Colors.grey.shade600)),
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final y = _c.danhSach[i];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warning.withValues(alpha: 0.14),
                        AppColors.warning.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pending_actions_rounded, color: AppColors.warning, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              y.tenThietBi ?? 'TB #${y.maThietBi}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                            ),
                            Text(
                              'YC #${y.maYeuCauBaoTri} · ${y.danhMuc ?? ''}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Chờ xác nhận',
                          style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày BT: ${y.ngayBaoTri.day.toString().padLeft(2, '0')}/${y.ngayBaoTri.month.toString().padLeft(2, '0')}/${y.ngayBaoTri.year}'
                            ' · ${y.thoiGianDuKien}h · ${y.gioBatDau ?? ''}–${y.gioKetThuc ?? ''}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Người gửi: ${y.tenNguoiYeuCau ?? '—'}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _xacNhan(y),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Xác nhận'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
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