import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../equipment/data/equipment_logic.dart';
import '../data/maintenance_request_logic.dart';

// ============ TTSX: Tạo yêu cầu bảo trì ============

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
    final first = DateTime(_c.nam, _c.thang, 1);
    final last = DateTime(_c.nam, _c.thang + 1, 0);
    final picked = await showDatePicker(
      context: context,
      initialDate: _c.ngayBaoTri ?? first,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      _c.ngayBaoTri = picked;
      _c.notifyListeners();
    }
  }

  Future<void> _pickTime({required bool batDau}) async {
    if (!_c.thoiGianHopLe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập thời gian dự kiến (số > 0) trước khi chọn giờ')),
      );
      return;
    }
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
  }

  String _fmtTime(TimeOfDay? t) =>
      t == null ? 'Chọn giờ' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_c.dangTai) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Tìm thiết bị theo tên...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                .map((e) => DropdownMenuItem(value: e, child: Text(e.tenThietBi, overflow: TextOverflow.ellipsis)))
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
            subtitle: Text(_c.ngayBaoTri == null
                ? 'Chọn ngày trong tháng'
                : '${_c.ngayBaoTri!.day.toString().padLeft(2, '0')}/${_c.ngayBaoTri!.month.toString().padLeft(2, '0')}/${_c.ngayBaoTri!.year}'),
            trailing: const Icon(Icons.calendar_month_rounded),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _c.thoiGianCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: const InputDecoration(
              labelText: 'Thời gian dự kiến (giờ)',
              border: OutlineInputBorder(),
              helperText: 'Chỉ số dương — bắt buộc trước khi chọn giờ',
            ),
            onChanged: (_) => setState(() {}),
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
            decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)', border: OutlineInputBorder()),
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
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Gửi yêu cầu bảo trì'),
        ),
      ],
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

// ============ TTKT: Xác nhận yêu cầu ============

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

  Future<void> _xuLy(YeuCauBaoTriItem item, {required bool xacNhan}) async {
    String? lyDo;
    if (!xacNhan) {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Từ chối yêu cầu'),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Lý do từ chối', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Từ chối'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      lyDo = ctrl.text.trim();
      if (lyDo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập lý do từ chối')));
        return;
      }
    }
    final success = await _c.xuLy(
      item.maYeuCauBaoTri,
      quyetDinh: xacNhan ? 'Xác nhận' : 'Từ chối',
      lyDo: lyDo,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? (xacNhan ? 'Đã xác nhận yêu cầu.' : 'Đã từ chối.') : (_c.loi ?? 'Lỗi')),
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
          children: const [
            SizedBox(height: 120),
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Center(child: Text('Không có yêu cầu chờ xác nhận')),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(y.trangThai, style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('YC #${y.maYeuCauBaoTri} · ${y.danhMuc ?? ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                Text(
                  'Ngày BT: ${y.ngayBaoTri.day.toString().padLeft(2, '0')}/${y.ngayBaoTri.month.toString().padLeft(2, '0')}/${y.ngayBaoTri.year}'
                      ' · ${y.thoiGianDuKien}h · ${y.gioBatDau ?? ''}–${y.gioKetThuc ?? ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text('Người gửi: ${y.tenNguoiYeuCau ?? '—'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _xuLy(y, xacNhan: false),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                        child: const Text('Từ chối'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _xuLy(y, xacNhan: true),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                        child: const Text('Xác nhận'),
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
}