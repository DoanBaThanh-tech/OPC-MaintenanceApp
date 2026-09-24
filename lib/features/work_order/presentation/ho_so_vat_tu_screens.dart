import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';

/// Danh sách hồ sơ vật tư — Tổ trưởng cơ điện / Giám đốc.
class HoSoVatTuListScreen extends StatefulWidget {
  /// true: Giám đốc chỉ xem hồ sơ đã gửi
  final bool chiXemDaGui;

  const HoSoVatTuListScreen({super.key, this.chiXemDaGui = false});

  @override
  State<HoSoVatTuListScreen> createState() => _HoSoVatTuListScreenState();
}

class _HoSoVatTuListScreenState extends State<HoSoVatTuListScreen> {
  List<HoSoVatTuItem> _list = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final all = await MaterialUsageService.layDanhSachHoSoVatTu();
      setState(() {
        _list = widget.chiXemDaGui
            ? all.where((e) => e.daGuiGiamDoc).toList()
            : all;
        _dangTai = false;
      });
    } catch (e) {
      setState(() {
        _loi = e is ApiException ? e.message : '$e';
        _dangTai = false;
        _list = [];
      });
    }
  }

  String _fmtDt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTien(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₫';
  }

  Color _mauTrangThai(String tt) {
    if (tt.contains('gửi') || tt.contains('GĐ')) return const Color(0xFF2563EB);
    if (tt.contains('xem')) return AppColors.success;
    return const Color(0xFFD97706);
  }

  Future<void> _moChiTiet(HoSoVatTuItem item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HoSoVatTuDetailScreen(
          maHoSoVatTu: item.maHoSoVatTu,
          choPhepGuiGiamDoc: !widget.chiXemDaGui,
        ),
      ),
    );
    if (changed == true) _tai();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chiXemDaGui
                      ? 'Hồ sơ vật tư (Giám đốc)'
                      : 'Hồ sơ vật tư',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.chiXemDaGui
                      ? 'Xem vật tư đã dùng sau bảo trì / sửa chữa'
                      : 'Kiểm tra và gửi Giám đốc xem hồ sơ vật tư',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _dangTai
                ? const Center(child: CircularProgressIndicator())
                : _loi != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48,
                        color:
                        AppColors.danger.withValues(alpha: 0.7)),
                    const SizedBox(height: 12),
                    Text(_loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _tai,
                        child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _tai,
              color: AppColors.primary,
              child: _list.isEmpty
                  ? ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                      height:
                      MediaQuery.of(context).size.height *
                          0.25),
                  Icon(Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có hồ sơ vật tư',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15),
                  ),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    16, 16, 16, 28),
                itemCount: _list.length,
                itemBuilder: (_, i) {
                  final item = _list[i];
                  return _card(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(HoSoVatTuItem item) {
    final mau = _mauTrangThai(item.trangThai);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _moChiTiet(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.tenThietBi,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: mau.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.trangThai,
                        style: TextStyle(
                          color: mau,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      item.loaiCongViec == 'Bảo trì'
                          ? Icons.precision_manufacturing_rounded
                          : Icons.handyman_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.loaiCongViec} · ${_fmtDt(item.ngayThucHien)}',
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Vật tư: ${item.chiTiet.map((c) => c.tenVatTu).where((t) => t.isNotEmpty).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _fmtTien(item.tongTien),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HoSoVatTuDetailScreen extends StatefulWidget {
  final int maHoSoVatTu;
  final bool choPhepGuiGiamDoc;

  const HoSoVatTuDetailScreen({
    super.key,
    required this.maHoSoVatTu,
    this.choPhepGuiGiamDoc = true,
  });

  @override
  State<HoSoVatTuDetailScreen> createState() => _HoSoVatTuDetailScreenState();
}

class _HoSoVatTuDetailScreenState extends State<HoSoVatTuDetailScreen> {
  HoSoVatTuItem? _item;
  bool _dangTai = true;
  bool _dangGui = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final item = await MaterialUsageService.layChiTiet(widget.maHoSoVatTu);
      if (!mounted) return;
      setState(() {
        _item = item;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loi = e is ApiException ? e.message : '$e';
        _dangTai = false;
      });
    }
  }

  String _fmtDt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTien(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₫';
  }

  Future<void> _guiGiamDoc() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Gửi Giám đốc?'),
        content: const Text(
            'Hồ sơ vật tư sẽ được gửi cho Giám đốc để xem và kiểm tra.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _dangGui = true);
    try {
      await MaterialUsageService.guiGiamDoc(widget.maHoSoVatTu);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã gửi hồ sơ vật tư cho Giám đốc'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final item = _item;
    final showGui = widget.choPhepGuiGiamDoc &&
        item != null &&
        item.trangThai == 'Chờ gửi';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, top + 4, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'Chi tiết hồ sơ vật tư',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _dangTai
                ? const Center(child: CircularProgressIndicator())
                : _loi != null
                ? Center(child: Text(_loi!))
                : item == null
                ? const Center(child: Text('Không có dữ liệu'))
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _infoBox([
                  _row('Thiết bị', item.tenThietBi),
                  _row('Loại', item.loaiCongViec),
                  _row('Ngày thực hiện',
                      _fmtDt(item.ngayThucHien)),
                  if (item.tenNhanVien != null)
                    _row('NV kỹ thuật', item.tenNhanVien!),
                  _row('Trạng thái', item.trangThai),
                  _row('Tổng tiền', _fmtTien(item.tongTien)),
                ]),
                const SizedBox(height: 14),
                const Text(
                  'Chi tiết vật tư theo bước',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 10),
                ...item.chiTiet.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bước ${c.soBuoc}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(c.moTaBuoc,
                          style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.35,
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      _row('Vật tư', c.tenVatTu),
                      _row('Số lượng', '${c.soLuong}'),
                      _row('Đơn giá', _fmtTien(c.donGia)),
                      _row('Thành tiền',
                          _fmtTien(c.thanhTien)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          if (showGui)
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              color: Colors.white,
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _dangGui ? null : _guiGiamDoc,
                  icon: _dangGui
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Gửi Giám đốc',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoBox(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}