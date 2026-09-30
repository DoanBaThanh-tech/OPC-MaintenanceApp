import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../data/models/work_order_models.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';
import '../data/work_order_validators.dart';
import 'quy_trinh_cong_viec_screen.dart';

/// Trang 1: Quy trình chọn vật tư bảo trì / sửa chữa.
/// - Mỗi bước có thể chọn **nhiều vật tư**.
/// - Số lượng: số nguyên dương (> 0), không thập phân, không ký tự đặc biệt.
/// - Mode cập nhật: load hồ sơ đã lưu, Lưu → PUT cập nhật.
class QuyTrinhThucHienScreen extends StatefulWidget {
  final YeuCauPhanCong yeuCau;

  /// true = mở từ nút "Cập nhật vật tư" trên trang quy trình công việc.
  final bool cheDoCapNhat;

  const QuyTrinhThucHienScreen({
    super.key,
    required this.yeuCau,
    this.cheDoCapNhat = false,
  });

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
  int? _maHoSoVatTu; // có khi đang cập nhật
  late final AnimationController _anim;

  /// Controllers: key = "$soBuoc_$indexDong"
  final Map<String, TextEditingController> _slCtrls = {};
  final Map<String, TextEditingController> _giaCtrls = {};

  bool get _laBaoTri => widget.yeuCau.laBaoTri;

  String _keyDong(int soBuoc, int idx) => '${soBuoc}_$idx';

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
        if (y.maHoSo != null)
          MaterialUsageService.layHoSoTheoCongViec(
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
          )
        else
          Future.value(null),
      ]);
      if (!mounted) return;
      final vatTu = results[0] as List<VatTuOption>;
      var buoc = results[1] as List<BuocQuyTrinh>;
      final hoSoCu = results[2] as HoSoVatTuItem?;

      if (buoc.isEmpty) {
        _loiTai = maTb <= 0
            ? 'Thiếu mã thiết bị — không tải được bước từ database.'
            : 'Chưa có quy trình $loai cho thiết bị này trong database.';
      }

      // Gắn vật tư đã lưu theo bước (hỗ trợ nhiều dòng / bước)
      if (hoSoCu != null && hoSoCu.chiTiet.isNotEmpty) {
        _maHoSoVatTu = hoSoCu.maHoSoVatTu;
        for (final b in buoc) {
          final dong = hoSoCu.chiTiet.where((c) => c.soBuoc == b.soBuoc).toList();
          b.vatTuList = dong
              .map((c) => VatTuDong(
            maVatTu: c.maVatTu,
            tenVatTu: c.tenVatTu,
            soLuong: c.soLuong,
            donGia: c.donGia,
          ))
              .toList();
        }
      }

      _disposeCtrls();
      for (final b in buoc) {
        for (var i = 0; i < b.vatTuList.length; i++) {
          final d = b.vatTuList[i];
          final k = _keyDong(b.soBuoc, i);
          _slCtrls[k] = TextEditingController(text: d.soLuong.toString());
          _giaCtrls[k] = TextEditingController(text: d.donGia.toString());
        }
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

  void _disposeCtrls() {
    for (final c in _slCtrls.values) {
      c.dispose();
    }
    for (final c in _giaCtrls.values) {
      c.dispose();
    }
    _slCtrls.clear();
    _giaCtrls.clear();
  }

  @override
  void dispose() {
    _anim.dispose();
    _disposeCtrls();
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

  /// Ủy quyền validate cho [validateSoLuongVatTu] trong work_order_validators.
  String? _validateSoLuong(String raw, {String? tenVatTu, bool choPhepRong = false}) {
    return validateSoLuongVatTu(
      raw,
      tenVatTu: tenVatTu,
      choPhepRong: choPhepRong,
    ).loi;
  }

  Future<void> _themVatTuVaoBuoc(BuocQuyTrinh b) async {
    final selected = await _showChonVatTuSheet(
      excludeMa: b.vatTuList.map((e) => e.maVatTu).whereType<int>().toSet(),
    );
    if (selected == null) return;
    setState(() {
      final dong = VatTuDong(
        maVatTu: selected.maVatTu,
        tenVatTu: selected.tenVatTu,
        soLuong: 1,
        donGia: selected.donGia,
        donViTinh: selected.donViTinh,
      );
      b.vatTuList.add(dong);
      final idx = b.vatTuList.length - 1;
      final k = _keyDong(b.soBuoc, idx);
      _slCtrls[k] = TextEditingController(text: '1');
      _giaCtrls[k] = TextEditingController(text: selected.donGia.toString());
    });
  }

  Future<void> _doiVatTuDong(BuocQuyTrinh b, int idx) async {
    final selected = await _showChonVatTuSheet(
      excludeMa: b.vatTuList
          .asMap()
          .entries
          .where((e) => e.key != idx)
          .map((e) => e.value.maVatTu)
          .whereType<int>()
          .toSet(),
    );
    if (selected == null) return;
    setState(() {
      final d = b.vatTuList[idx];
      d.maVatTu = selected.maVatTu;
      d.tenVatTu = selected.tenVatTu;
      d.donGia = selected.donGia;
      d.donViTinh = selected.donViTinh;
      final k = _keyDong(b.soBuoc, idx);
      _giaCtrls[k]?.text = selected.donGia.toString();
      if ((_slCtrls[k]?.text ?? '0') == '0' || (_slCtrls[k]?.text ?? '').isEmpty) {
        _slCtrls[k]?.text = '1';
        d.soLuong = 1;
      }
    });
  }

  void _xoaVatTuDong(BuocQuyTrinh b, int idx) {
    setState(() {
      final k = _keyDong(b.soBuoc, idx);
      _slCtrls[k]?.dispose();
      _giaCtrls[k]?.dispose();
      _slCtrls.remove(k);
      _giaCtrls.remove(k);
      b.vatTuList.removeAt(idx);
      // Re-index controllers sau khi xóa
      final remaining = List<VatTuDong>.from(b.vatTuList);
      for (var i = 0; i < remaining.length; i++) {
        final oldK = _keyDong(b.soBuoc, i >= idx ? i + 1 : i);
        final newK = _keyDong(b.soBuoc, i);
        if (oldK != newK) {
          if (_slCtrls.containsKey(oldK)) {
            _slCtrls[newK] = _slCtrls.remove(oldK)!;
          }
          if (_giaCtrls.containsKey(oldK)) {
            _giaCtrls[newK] = _giaCtrls.remove(oldK)!;
          }
        }
      }
    });
  }

  Future<VatTuOption?> _showChonVatTuSheet({Set<int> excludeMa = const {}}) {
    final list = _dsVatTu.where((v) => !excludeMa.contains(v.maVatTu)).toList();
    return showModalBottomSheet<VatTuOption>(
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
                      Icon(Icons.inventory_2_rounded, color: AppColors.primary),
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
                  child: list.isEmpty
                      ? const Center(
                      child: Text('Không còn vật tư khả dụng / kho trống'))
                      : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final v = list[i];
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
  }

  int get tongTien {
    var t = 0;
    for (final b in _buoc) {
      t += b.thanhTien;
    }
    return t;
  }

  bool _syncVaValidate() {
    for (final b in _buoc) {
      for (var i = 0; i < b.vatTuList.length; i++) {
        final d = b.vatTuList[i];
        final k = _keyDong(b.soBuoc, i);
        final rawSl = _slCtrls[k]?.text ?? '';
        final kq = validateSoLuongVatTu(
          rawSl,
          tenVatTu: d.tenVatTu,
          choPhepRong: false,
        );
        if (!kq.hopLe) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Bước ${b.soBuoc}: ${kq.loi ?? 'Số lượng không hợp lệ'}'),
              backgroundColor: AppColors.danger,
            ),
          );
          return false;
        }
        d.soLuong = kq.soLuong!;
        d.donGia = int.tryParse(_giaCtrls[k]?.text ?? '0') ?? d.donGia;
        if (d.donGia < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bước ${b.soBuoc}: đơn giá không được âm'),
              backgroundColor: AppColors.danger,
            ),
          );
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _luuVatTu() async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;
    if (!_syncVaValidate()) return;

    final buocCoVatTu = _buoc
        .where((b) => b.vatTuList.any((d) => d.soLuong > 0 && d.tenVatTu.isNotEmpty))
        .toList();

    final isUpdate = widget.cheDoCapNhat || _maHoSoVatTu != null;

    if (isUpdate && buocCoVatTu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần ít nhất 1 vật tư khi cập nhật hồ sơ.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _dangXuLy = true);
    try {
      if (buocCoVatTu.isNotEmpty) {
        if (isUpdate && _maHoSoVatTu != null) {
          final updated = await MaterialUsageService.capNhatHoSoVatTu(
            maHoSoVatTu: _maHoSoVatTu!,
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
            maThietBi: y.maThietBi ?? 0,
            tenThietBi: y.tenThietBi ?? 'Thiết bị',
            loaiCongViec: _laBaoTri ? 'Bảo trì' : 'Sửa chữa',
            buoc: _buoc,
          );
          _maHoSoVatTu = updated.maHoSoVatTu;
        } else {
          final created = await MaterialUsageService.taoHoSoVatTu(
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
            maThietBi: y.maThietBi ?? 0,
            tenThietBi: y.tenThietBi ?? 'Thiết bị',
            loaiCongViec: _laBaoTri ? 'Bảo trì' : 'Sửa chữa',
            buoc: _buoc,
          );
          if (created != null) _maHoSoVatTu = created.maHoSoVatTu;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate
                ? 'Đã cập nhật số lượng vật tư — hồ sơ Tổ trưởng đã đồng bộ'
                : (buocCoVatTu.isEmpty
                ? 'Không chọn vật tư — chuyển sang quy trình thực hiện'
                : 'Đã lưu hồ sơ vật tư — chuyển sang quy trình thực hiện'),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Mode cập nhật: quay lại trang quy trình công việc
      if (widget.cheDoCapNhat) {
        Navigator.pop(context, true);
        return;
      }

      // Lần đầu: sang trang 2
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
    final title = widget.cheDoCapNhat
        ? (_laBaoTri
        ? 'Cập nhật vật tư bảo trì'
        : 'Cập nhật vật tư sửa chữa')
        : (_laBaoTri
        ? 'Quy trình chọn vật tư bảo trì'
        : 'Quy trình chọn vật tư sửa chữa');

    return PopScope(
      canPop: widget.cheDoCapNhat,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.cheDoCapNhat) {
          Navigator.pop(context);
          return;
        }
        _canhBaoKhongQuayLai();
      },
      child: Scaffold(
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
                    colors: [
                      Color(0xFF0068A9),
                      Color(0xFF0284C7),
                      Color(0xFF0EA5E9)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24)),
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
                      onPressed: widget.cheDoCapNhat
                          ? () => Navigator.pop(context)
                          : _canhBaoKhongQuayLai,
                      icon: Icon(
                        widget.cheDoCapNhat
                            ? Icons.arrow_back_rounded
                            : Icons.lock_outline_rounded,
                        color: Colors.white70,
                      ),
                      tooltip: widget.cheDoCapNhat
                          ? 'Quay lại'
                          : 'Phải hoàn thành quy trình',
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
                        : Text(
                      widget.cheDoCapNhat ? 'Lưu cập nhật' : 'Lưu',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _canhBaoKhongQuayLai() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Không thể quay lại'),
        content: Text(
          _laBaoTri
              ? 'Bạn đã bắt đầu quy trình bảo trì. Hãy chọn vật tư (nếu cần), bấm Lưu rồi hoàn thành các bước trên trang Quy trình bảo trì. Không được quay lại để tránh trùng trạng thái hồ sơ.'
              : 'Bạn đã bắt đầu quy trình sửa chữa. Hãy chọn vật tư (nếu cần), bấm Lưu rồi hoàn thành các bước trên trang Quy trình sửa chữa. Không được quay lại để tránh trùng trạng thái hồ sơ.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
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
            // Danh sách vật tư đã chọn
            for (var i = 0; i < b.vatTuList.length; i++) ...[
              _buildDongVatTu(b, i),
              const SizedBox(height: 8),
            ],
            // Nút thêm vật tư
            OutlinedButton.icon(
              onPressed: (_dangTai || _dsVatTu.isEmpty)
                  ? null
                  : () => _themVatTuVaoBuoc(b),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                b.vatTuList.isEmpty
                    ? 'Thêm vật tư (có thể chọn nhiều)'
                    : 'Thêm vật tư khác',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 42),
              ),
            ),
            if (b.thanhTien > 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('Thành tiền bước: ${_fmtTien(b.thanhTien)}',
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

  Widget _buildDongVatTu(BuocQuyTrinh b, int idx) {
    final d = b.vatTuList[idx];
    final k = _keyDong(b.soBuoc, idx);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _doiVatTuDong(b, idx),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Icon(Icons.category_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d.tenVatTu.isEmpty ? 'Chọn vật tư' : d.tenVatTu,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: d.tenVatTu.isEmpty
                                ? Colors.grey.shade600
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const Icon(Icons.swap_horiz, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _xoaVatTuDong(b, idx),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Xóa vật tư',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _slCtrls[k],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    FilteringTextInputFormatter.allow(soLuongVatTuChoPhepNhap),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Số lượng',
                    hintText: 'Số nguyên > 0',
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    helperText: 'Số nguyên dương, không thập phân',
                    helperStyle: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600),
                    errorText: formValidateSoLuongVatTu(
                      _slCtrls[k]?.text,
                      tenVatTu: d.tenVatTu,
                      choPhepRong: true,
                    ),
                  ),
                  onChanged: (v) {
                    setState(() {
                      final kq = validateSoLuongVatTu(
                        v,
                        tenVatTu: d.tenVatTu,
                        choPhepRong: true,
                      );
                      d.soLuong = kq.soLuong ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _giaCtrls[k],
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
                      d.donGia = int.tryParse(v) ?? 0;
                    });
                  },
                ),
              ),
            ],
          ),
          if (d.thanhTien > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(_fmtTien(d.thanhTien),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: Colors.grey.shade700)),
              ),
            ),
        ],
      ),
    );
  }
}