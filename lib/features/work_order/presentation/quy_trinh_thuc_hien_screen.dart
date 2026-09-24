import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/models/work_order_models.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/work_order_service.dart';
import '../data/services/material_usage_service.dart';

/// Trang quy trình từng bước bảo trì / sửa chữa (tối đa 4 bước).
class QuyTrinhThucHienScreen extends StatefulWidget {
  final YeuCauPhanCong yeuCau;

  const QuyTrinhThucHienScreen({super.key, required this.yeuCau});

  @override
  State<QuyTrinhThucHienScreen> createState() => _QuyTrinhThucHienScreenState();
}

class _QuyTrinhThucHienScreenState extends State<QuyTrinhThucHienScreen> {
  List<BuocQuyTrinh> _buoc = [];
  List<VatTuOption> _dsVatTu = [];
  bool _dangTai = true;
  String? _loiTai;
  bool _dangXuLy = false;
  final Map<int, TextEditingController> _slCtrls = {};
  final Map<int, TextEditingController> _giaCtrls = {};

  bool get _laBaoTri => widget.yeuCau.laBaoTri;

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  Future<void> _taiDuLieu() async {
    setState(() {
      _dangTai = true;
      _loiTai = null;
    });
    try {
      final y = widget.yeuCau;
      final loai = _laBaoTri ? 'Bảo trì' : 'Sửa chữa';
      final maTb = y.maThietBi ?? 0;
      final results = await Future.wait([
        MaterialUsageService.layDanhSachVatTu(),
        if (maTb > 0)
          MaterialUsageService.layQuyTrinhThietBi(
            maThietBi: maTb,
            loaiCongViec: loai,
          )
        else
          Future.value(<BuocQuyTrinh>[]),
      ]);
      if (!mounted) return;
      final vatTu = results[0] as List<VatTuOption>;
      var buoc = results[1] as List<BuocQuyTrinh>;
      if (buoc.isEmpty) {
        // API chưa có quy trình cho thiết bị này
        _loiTai = maTb <= 0
            ? 'Thiếu mã thiết bị — không tải được quy trình từ database.'
            : 'Chưa có quy trình $loai cho thiết bị này trong database. Hãy chạy script InsertVatTuVaQuyTrinh.sql.';
      }
      for (final c in _slCtrls.values) {
        c.dispose();
      }
      for (final c in _giaCtrls.values) {
        c.dispose();
      }
      _slCtrls.clear();
      _giaCtrls.clear();
      for (final b in buoc) {
        _slCtrls[b.soBuoc] = TextEditingController(text: '0');
        _giaCtrls[b.soBuoc] = TextEditingController(text: '0');
      }
      setState(() {
        _dsVatTu = vatTu;
        _buoc = buoc;
        _dangTai = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loiTai = e.toString();
        _dangTai = false;
        _buoc = [];
        _dsVatTu = [];
      });
    }
  }

  @override
  void dispose() {
    for (final c in _slCtrls.values) {
      c.dispose();
    }
    for (final c in _giaCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmtTien(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf ₫';
  }

  Future<void> _chonVatTu(BuocQuyTrinh b) async {
    final selected = await showModalBottomSheet<VatTuOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (_, scroll) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chọn vật tư',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    itemCount: _dsVatTu.length,
                    itemBuilder: (_, i) {
                      final v = _dsVatTu[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                          child: Icon(Icons.inventory_2_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                        title: Text(v.tenVatTu,
                            style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${v.donViTinh ?? '—'} · Tồn: ${v.soLuongTonKho}'
                              '${v.donGia > 0 ? ' · ${_fmtTien(v.donGia)}' : ''}',
                        ),
                        onTap: () => Navigator.pop(ctx, v),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected == null) return;
    setState(() {
      b.maVatTu = selected.maVatTu;
      b.tenVatTu = selected.tenVatTu;
      b.donGia = selected.donGia;
      _giaCtrls[b.soBuoc]?.text =
      selected.donGia > 0 ? selected.donGia.toString() : '0';
    });
  }

  bool _validate() {
    for (final b in _buoc) {
      final slText = _slCtrls[b.soBuoc]?.text.trim() ?? '0';
      final giaText = _giaCtrls[b.soBuoc]?.text.trim() ?? '0';
      if (slText.isEmpty || !RegExp(r'^\d+$').hasMatch(slText)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Bước ${b.soBuoc}: số lượng chỉ được nhập số nguyên không âm.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return false;
      }
      if (giaText.isEmpty || !RegExp(r'^\d+$').hasMatch(giaText)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Bước ${b.soBuoc}: giá tiền chỉ được nhập số nguyên không âm.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return false;
      }
      final sl = int.parse(slText);
      final gia = int.parse(giaText);
      if (sl < 0 || gia < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Số lượng và giá không được âm.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return false;
      }
      // Nếu có số lượng > 0 thì phải chọn vật tư
      if (sl > 0 && (b.tenVatTu.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bước ${b.soBuoc}: vui lòng chọn vật tư khi có số lượng.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return false;
      }
      b.soLuong = sl;
      b.donGia = gia;
    }
    return true;
  }

  Future<void> _hoanThanh() async {
    if (!_validate()) return;
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_laBaoTri ? 'Hoàn thành bảo trì?' : 'Hoàn thành sửa chữa?'),
        content: const Text(
          'Xác nhận đã hoàn thành toàn bộ quy trình. Hồ sơ, phân công và thiết bị sẽ được cập nhật trạng thái. Vật tư đã dùng sẽ ghi vào Hồ sơ vật tư.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _dangXuLy = true);
    try {
      // 1) Đồng bộ trạng thái hồ sơ / phân công / thiết bị
      if (_laBaoTri) {
        await WorkOrderService.nhanVienHoanThanhBaoTri(y.maHoSo!);
      } else {
        await WorkOrderService.nhanVienHoanThanhSuaChua(y.maHoSo!);
      }

      // 2) Ghi hồ sơ vật tư (các bước có vật tư)
      final buocCoVatTu = _buoc
          .where((b) => b.soLuong > 0 && b.tenVatTu.isNotEmpty)
          .toList();
      if (buocCoVatTu.isNotEmpty) {
        try {
          await MaterialUsageService.taoHoSoVatTu(
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
            maThietBi: y.maThietBi ?? 0,
            tenThietBi: y.tenThietBi ?? 'Thiết bị',
            loaiCongViec: _laBaoTri ? 'Bảo trì' : 'Sửa chữa',
            buoc: buocCoVatTu.isEmpty ? _buoc : buocCoVatTu,
          );
        } catch (e) {
          // Không chặn hoàn thành nếu API hồ sơ VT chưa sẵn sàng
          debugPrint('Ghi hồ sơ vật tư: $e');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Đã hoàn thành — hồ sơ, thiết bị và vật tư đã cập nhật'),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _dangXuLy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final y = widget.yeuCau;
    final top = MediaQuery.paddingOf(context).top;
    final tongTien =
    _buoc.fold<int>(0, (s, b) {
      final sl = int.tryParse(_slCtrls[b.soBuoc]?.text ?? '0') ?? 0;
      final gia = int.tryParse(_giaCtrls[b.soBuoc]?.text ?? '0') ?? 0;
      return s + sl * gia;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, top + 4, 16, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _laBaoTri
                    ? [AppColors.primary, AppColors.primaryDark]
                    : const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _laBaoTri
                            ? 'Quy trình bảo trì'
                            : 'Quy trình sửa chữa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        y.tenThietBi ?? 'HS #${y.maHoSo ?? '—'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_dangTai)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _dangTai
                ? const Center(child: CircularProgressIndicator())
                : _loiTai != null && _buoc.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(_loiTai!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: _taiDuLieu,
                        child: const Text('Thử lại')),
                  ],
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _buoc.length,
              itemBuilder: (_, i) => _buildBuocCard(_buoc[i]),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tổng tiền vật tư',
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600)),
                    Text(_fmtTien(tongTien),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _dangXuLy ? null : _hoanThanh,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _dangXuLy
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Hoàn thành',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuocCard(BuocQuyTrinh b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${b.soBuoc}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Text('Bước ${b.soBuoc}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            b.moTa,
            style: TextStyle(
                color: Colors.grey.shade800, height: 1.4, fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Vật tư
          InkWell(
            onTap: (_dangTai || _dsVatTu.isEmpty) ? null : () => _chonVatTu(b),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.category_rounded,
                      size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b.tenVatTu.isEmpty ? 'Chọn vật tư (tùy chọn)' : b.tenVatTu,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: b.tenVatTu.isEmpty
                            ? Colors.grey.shade500
                            : Colors.grey.shade900,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade500),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _numField(
                  label: 'Số lượng',
                  controller: _slCtrls[b.soBuoc]!,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numField(
                  label: 'Giá tiền (₫)',
                  controller: _giaCtrls[b.soBuoc]!,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Thành tiền: ${_fmtTien((int.tryParse(_slCtrls[b.soBuoc]?.text ?? '0') ?? 0) * (int.tryParse(_giaCtrls[b.soBuoc]?.text ?? '0') ?? 0))}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}