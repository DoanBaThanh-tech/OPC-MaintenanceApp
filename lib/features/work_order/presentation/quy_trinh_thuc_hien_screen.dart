import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/models/work_order_models.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';
import 'quy_trinh_cong_viec_screen.dart';

/// Trang 1: Quy trình chọn vật tư bảo trì / sửa chữa.
/// Nút "Lưu" → ghi hồ sơ vật tư → chuyển sang trang Quy trình thực hiện.
class QuyTrinhThucHienScreen extends StatefulWidget {
  final YeuCauPhanCong yeuCau;

  const QuyTrinhThucHienScreen({super.key, required this.yeuCau});

  @override
  State<QuyTrinhThucHienScreen> createState() => _QuyTrinhThucHienScreenState();
}

class _QuyTrinhThucHienScreenState extends State<QuyTrinhThucHienScreen>
    with SingleTickerProviderStateMixin {
  List<BuocQuyTrinh> _buoc = [];
  List<VatTuOption> _dsVatTu = [];
  bool _dangTai = true;
  String? _loiTai;
  bool _dangXuLy = false;
  final Map<int, TextEditingController> _slCtrls = {};
  final Map<int, TextEditingController> _giaCtrls = {};
  late final AnimationController _anim;

  bool get _laBaoTri => widget.yeuCau.laBaoTri;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
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
        _loiTai = maTb <= 0
            ? 'Thiếu mã thiết bị — không tải được bước từ database.'
            : 'Chưa có quy trình $loai cho thiết bị này trong database.';
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
    _anim.dispose();
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_rounded,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Text(
                        'Chọn vật tư',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _dsVatTu.isEmpty
                      ? const Center(child: Text('Chưa có vật tư trong kho'))
                      : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _dsVatTu.length,
                    itemBuilder: (_, i) {
                      final v = _dsVatTu[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                          child: Text('${v.maVatTu}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        title: Text(v.tenVatTu,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            'Tồn: ${v.soLuongTonKho} ${v.donViTinh ?? ''} · ${_fmtTien(v.donGia)}'),
                        onTap: () => Navigator.pop(ctx, v),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    setState(() {
      b.maVatTu = selected.maVatTu;
      b.tenVatTu = selected.tenVatTu;
      b.donGia = selected.donGia;
      _giaCtrls[b.soBuoc]?.text = selected.donGia.toString();
      if ((_slCtrls[b.soBuoc]?.text ?? '0') == '0') {
        _slCtrls[b.soBuoc]?.text = '1';
        b.soLuong = 1;
      }
    });
  }

  int get tongTien {
    var t = 0;
    for (final b in _buoc) {
      t += b.thanhTien;
    }
    return t;
  }

  Future<void> _luuVatTu() async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;

    // Sync qty/price from controllers
    for (final b in _buoc) {
      b.soLuong = int.tryParse(_slCtrls[b.soBuoc]?.text ?? '0') ?? 0;
      b.donGia = int.tryParse(_giaCtrls[b.soBuoc]?.text ?? '0') ?? b.donGia;
    }

    final buocCoVatTu = _buoc
        .where((b) => b.soLuong > 0 && b.tenVatTu.isNotEmpty)
        .toList();

    setState(() => _dangXuLy = true);
    try {
      if (buocCoVatTu.isNotEmpty) {
        await MaterialUsageService.taoHoSoVatTu(
          maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
          maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
          maThietBi: y.maThietBi ?? 0,
          tenThietBi: y.tenThietBi ?? 'Thiết bị',
          loaiCongViec: _laBaoTri ? 'Bảo trì' : 'Sửa chữa',
          buoc: buocCoVatTu,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(buocCoVatTu.isEmpty
              ? 'Không chọn vật tư — chuyển sang quy trình thực hiện'
              : 'Đã lưu hồ sơ vật tư — chuyển sang quy trình thực hiện'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Trang 2: Quy trình bảo trì / sửa chữa (kết quả từng bước + Hoàn thành)
      final done = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, a, __) => QuyTrinhCongViecScreen(yeuCau: y),
          transitionsBuilder: (_, a, __, child) {
            final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: c,
              child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(0.06, 0), end: Offset.zero)
                    .animate(c),
                child: child,
              ),
            );
          },
        ),
      );
      if (done == true && mounted) {
        Navigator.pop(context, true);
      }
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
    final top = MediaQuery.paddingOf(context).top;
    final title = _laBaoTri
        ? 'Quy trình chọn vật tư bảo trì'
        : 'Quy trình chọn vật tư sửa chữa';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FB),
      body: Column(
        children: [
          FadeTransition(
            opacity: _anim,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8, top + 6, 16, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0068A9), Color(0xFF0284C7), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 17)),
                        const SizedBox(height: 4),
                        Text(
                          widget.yeuCau.tenThietBi ?? 'Thiết bị',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_dangTai) const LinearProgressIndicator(minHeight: 2),
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
                    const Icon(Icons.info_outline,
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
              itemBuilder: (_, i) => _buildBuocCard(_buoc[i], i),
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
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _dangXuLy || _buoc.isEmpty ? null : _luuVatTu,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _dangXuLy
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Text('Lưu',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuocCard(BuocQuyTrinh b, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 80),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF0EA5E9)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${b.soBuoc}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(b.moTa,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, height: 1.35)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: (_dangTai || _dsVatTu.isEmpty)
                  ? null
                  : () => _chonVatTu(b),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b.tenVatTu.isEmpty
                            ? 'Chọn vật tư (tuỳ chọn)'
                            : b.tenVatTu,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: b.tenVatTu.isEmpty
                              ? Colors.grey.shade600
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _slCtrls[b.soBuoc],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Số lượng',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) {
                      setState(() {
                        b.soLuong = int.tryParse(v) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _giaCtrls[b.soBuoc],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Đơn giá',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (v) {
                      setState(() {
                        b.donGia = int.tryParse(v) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (b.thanhTien > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Thành tiền: ${_fmtTien(b.thanhTien)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}