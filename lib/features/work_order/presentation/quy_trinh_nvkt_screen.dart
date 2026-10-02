import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/models/work_order_models.dart';
import '../data/models/material_usage_models.dart';
import '../data/services/material_usage_service.dart';
import '../data/services/work_order_service.dart';
import '../data/work_order_validators.dart';
import '../data/quy_trinh_nvkt_logic.dart';

/// Trang quy trình BT/SC — NVKT tự tạo bước + vật tư (đơn giá chỉ đọc) + nội dung CV.
/// Xong → Chờ xác nhận Xưởng. Có thể cập nhật lại khi Xưởng từ chối.
class QuyTrinhNvktScreen extends StatefulWidget {
  final YeuCauPhanCong yeuCau;

  const QuyTrinhNvktScreen({super.key, required this.yeuCau});

  @override
  State<QuyTrinhNvktScreen> createState() => _QuyTrinhNvktScreenState();
}

class _QuyTrinhNvktScreenState extends State<QuyTrinhNvktScreen>
    with TickerProviderStateMixin {
  static const _blue = Color(0xFF0068A9);
  static const _blueMid = Color(0xFF0284C7);
  static const _blueSoft = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF0F7FC);

  final List<_BuocState> _buoc = [];
  List<VatTuOption> _dsVatTu = [];
  final _noiDungCtrl = TextEditingController();
  bool _dangTai = true;
  bool _dangXuLy = false;
  String? _loi;
  int? _maHoSoVatTu;
  String? _tenToi;
  Timer? _pollTimer;

  late final AnimationController _headerAnim;
  late final AnimationController _pulseAnim;

  bool get _laBaoTri => widget.yeuCau.laBaoTri;
  bool get _cheDoCapNhat => widget.yeuCau.biTuChoi;

  bool _coTheSuaVatTu(_BuocState b) => QuyTrinhNvktRules.coTheSuaVatTu(
    daChon: b.daChon,
    daXong: b.daXong,
    khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
    cheDoCapNhat: _cheDoCapNhat,
    dangXuLy: _dangXuLy,
  );

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _tai();
    // Không poll realtime — reload trang là thấy bước người khác đã làm
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _headerAnim.dispose();
    _pulseAnim.dispose();
    _noiDungCtrl.dispose();
    for (final b in _buoc) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      _tenToi = await TokenStorage.getHoTen();
      final y = widget.yeuCau;
      final results = await Future.wait([
        MaterialUsageService.layDanhSachVatTu(),
        if (y.maHoSo != null)
          MaterialUsageService.layHoSoTheoCongViec(
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
          )
        else
          Future.value(null),
      ]);
      if (!mounted) return;
      _dsVatTu = results[0] as List<VatTuOption>;
      final hoSoCu = results[1] as HoSoVatTuItem?;

      for (final b in _buoc) {
        b.dispose();
      }
      _buoc.clear();

      // Luôn nạp mẫu quy trình thiết bị trước, rồi áp tiến độ đã lưu
      final maTb = y.maThietBi ?? 0;
      if (maTb > 0) {
        final loai = _laBaoTri ? 'Bảo trì' : 'Sửa chữa';
        final mau = await MaterialUsageService.layQuyTrinhThietBi(
          maThietBi: maTb,
          loaiCongViec: loai,
        );
        for (final b in mau) {
          _buoc.add(_BuocState(soBuoc: b.soBuoc, moTa: b.moTa));
        }
      }

      // Hồ sơ vật tư đã gửi (sau hoàn thành) — ưu tiên khôi phục
      if (hoSoCu != null && hoSoCu.chiTiet.isNotEmpty) {
        _maHoSoVatTu = hoSoCu.maHoSoVatTu;
        final byBuoc = <int, List<ChiTietVatTuSuDung>>{};
        for (final c in hoSoCu.chiTiet) {
          byBuoc.putIfAbsent(c.soBuoc, () => []).add(c);
        }
        for (final b in _buoc) {
          final dong = byBuoc[b.soBuoc];
          if (dong == null || dong.isEmpty) continue;
          b.daChon = true;
          b.daXong = true;
          b.moRong = false;
          if (dong.first.moTaBuoc.isNotEmpty) {
            b.moTaCtrl.text = dong.first.moTaBuoc;
          }
          for (final c in dong) {
            if (c.tenVatTu.isEmpty || c.soLuong <= 0) continue;
            b.vatTu.add(_VatTuDongState(
              maVatTu: c.maVatTu,
              tenVatTu: c.tenVatTu,
              soLuong: c.soLuong,
              donGia: c.donGia,
            ));
          }
        }
      }

      // Tiến độ bước đã lưu (back app / crash) + khóa bước người khác
      await _dongBoTienDo(silent: true);

      if (_buoc.isEmpty) {
        _loi = 'Chưa có quy trình ${_laBaoTri ? "bảo trì" : "sửa chữa"} '
            'cho thiết bị này trong hệ thống.';
      }
    } catch (e) {
      _loi = e is ApiException ? e.message : '$e';
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  /// Đồng bộ tiến độ từ server (lưu bước + khóa realtime).
  Future<void> _dongBoTienDo({bool silent = false}) async {
    final y = widget.yeuCau;
    if (y.maHoSo == null || _buoc.isEmpty) return;
    try {
      final list = await WorkOrderService.layTienDoBuoc(
        maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
        maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
      );
      if (!mounted) return;
      final tenToi = (_tenToi ?? '').trim().toLowerCase();
      for (final row in list) {
        final soBuocRaw = row['soBuoc'] ?? row['SoBuoc'];
        final soBuoc = soBuocRaw is num
            ? soBuocRaw.toInt()
            : int.tryParse('$soBuocRaw');
        if (soBuoc == null) continue;
        _BuocState? b;
        for (final x in _buoc) {
          if (x.soBuoc == soBuoc) {
            b = x;
            break;
          }
        }
        if (b == null) continue;
        final tenNv =
            (row['tenNhanVien'] ?? row['TenNhanVien'])?.toString() ?? '';
        final tt = (row['trangThai'] ?? row['TrangThai'])?.toString() ?? '';
        final laCuaToi =
            tenToi.isNotEmpty && tenNv.trim().toLowerCase() == tenToi;
        b.tenNguoiGiu = tenNv;
        final ap = QuyTrinhNvktRules.apDungTienDo(
          trangThai: tt,
          laCuaToi: laCuaToi,
          tenNhanVien: tenNv,
        );
        // Chỉ áp khi DaXong (khóa) hoặc DangLam của chính mình — DangLam người khác không khóa
        if (tt == 'DaXong' || (tt == 'DangLam' && laCuaToi)) {
          b.daChon = ap.daChon;
          b.daXong = ap.daXong;
          b.khoaBoiNguoiKhac = ap.khoaBoiNguoiKhac;
          b.moRong = ap.moRong;
          if (ap.tenHienThi != null && ap.tenHienThi!.isNotEmpty) {
            b.tenNguoiGiu = ap.tenHienThi;
          }
        }
        if (tt == 'DaXong') {
          b.tenNguoiGiu = tenNv;
          final moTa = (row['moTaBuoc'] ?? row['MoTaBuoc'])?.toString();
          if (moTa != null && moTa.isNotEmpty) {
            b.moTaCtrl.text = moTa;
          }
          final jsonVt = (row['jsonVatTu'] ?? row['JsonVatTu'])?.toString();
          if (jsonVt != null && jsonVt.isNotEmpty && b.vatTu.isEmpty) {
            try {
              final arr = jsonDecode(jsonVt);
              if (arr is List) {
                for (final item in arr) {
                  if (item is! Map) continue;
                  final m = Map<String, dynamic>.from(item);
                  final ten = m['tenVatTu']?.toString() ?? '';
                  final sl = (m['soLuong'] as num?)?.toInt() ?? 0;
                  if (ten.isEmpty || sl <= 0) continue;
                  b.vatTu.add(_VatTuDongState(
                    maVatTu: (m['maVatTu'] as num?)?.toInt(),
                    tenVatTu: ten,
                    soLuong: sl,
                    donGia: (m['donGia'] as num?)?.toInt() ?? 0,
                  ));
                }
              }
            } catch (_) {}
          }
        }
      }
      if (!silent && mounted) setState(() {});
    } catch (_) {
      // Không chặn UI nếu poll lỗi
    }
  }

  Future<bool> _claimBuoc(_BuocState b) async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return false;
    try {
      await WorkOrderService.luuTienDoBuoc(
        maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
        maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
        soBuoc: b.soBuoc,
        moTaBuoc: b.moTaCtrl.text.trim(),
        trangThai: 'DangLam',
      );
      b.khoaBoiNguoiKhac = false;
      b.tenNguoiGiu = _tenToi;
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _luuBuocDaXong(_BuocState b) async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;

    // Ràng buộc: phải chọn vật tư trước khi Xong
    final loiVatTu = <String?>[];
    for (final d in b.vatTu) {
      final kq = validateSoLuongVatTu(
        d.slCtrl.text,
        tenVatTu: d.tenVatTu,
        choPhepRong: false,
      );
      loiVatTu.add(kq.hopLe ? null : (kq.loi ?? 'Số lượng không hợp lệ'));
      if (kq.hopLe) d.soLuong = kq.soLuong!;
    }
    final loiTruocXong = QuyTrinhNvktRules.kiemTraTruocKhiXong(
      soDongVatTu: b.vatTu.length,
      loiSoLuongTungDong: loiVatTu,
    );
    if (loiTruocXong != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loiTruocXong),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }
    final jsonVt = jsonEncode(b.vatTu
        .where((d) => d.tenVatTu.isNotEmpty && d.soLuong > 0)
        .map((d) => {
      'maVatTu': d.maVatTu,
      'tenVatTu': d.tenVatTu,
      'soLuong': d.soLuong,
      'donGia': d.donGia,
    })
        .toList());
    try {
      await WorkOrderService.luuTienDoBuoc(
        maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
        maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
        soBuoc: b.soBuoc,
        moTaBuoc: b.moTaCtrl.text.trim().isEmpty
            ? 'Bước ${b.soBuoc}'
            : b.moTaCtrl.text.trim(),
        trangThai: 'DaXong',
        jsonVatTu: jsonVt,
      );
      setState(() {
        b.daXong = true;
        b.moRong = false;
        b.khoaBoiNguoiKhac = false;
        b.tenNguoiGiu = _tenToi;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã xong bước ${b.soBuoc}'
                  '${_tenToi != null && _tenToi!.isNotEmpty ? " · $_tenToi" : ""}'
                  ' — NV khác reload sẽ thấy.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _themBuoc() {
    setState(() {
      final next = _buoc.isEmpty
          ? 1
          : (_buoc.map((e) => e.soBuoc).reduce((a, b) => a > b ? a : b) + 1);
      _buoc.add(_BuocState(soBuoc: next, moTa: ''));
    });
  }

  void _xoaBuoc(int index) {
    setState(() {
      _buoc[index].dispose();
      _buoc.removeAt(index);
      for (var i = 0; i < _buoc.length; i++) {
        _buoc[i].soBuoc = i + 1;
      }
    });
  }

  Future<void> _themVatTu(int buocIdx) async {
    final b = _buoc[buocIdx];
    if (!_coTheSuaVatTu(b)) return;
    // Trong cùng bước: ẩn vật tư đã chọn — tăng số lượng thay vì chọn lại.
    // Sang bước khác: danh sách hiện đủ lại (exclude chỉ theo bước hiện tại).
    final daChon = b.vatTu
        .map((e) => e.maVatTu)
        .whereType<int>()
        .toSet();
    final vt = await _chonVatTu(excludeMa: daChon);
    if (vt == null) return;
    setState(() {
      b.vatTu.add(_VatTuDongState(
        maVatTu: vt.maVatTu,
        tenVatTu: vt.tenVatTu,
        soLuong: 1,
        donGia: vt.donGia,
      ));
    });
  }

  Future<VatTuOption?> _chonVatTu({Set<int> excludeMa = const {}}) async {
    if (_dsVatTu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có danh sách vật tư')),
      );
      return null;
    }
    final conLai = _dsVatTu.where((e) => !excludeMa.contains(e.maVatTu)).toList();
    if (conLai.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã chọn hết vật tư trong bước này. '
                'Tăng số lượng trên dòng đã có, hoặc chuyển bước khác để chọn lại.',
          ),
        ),
      );
      return null;
    }
    return showModalBottomSheet<VatTuOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final filter = TextEditingController();
        var list = List<VatTuOption>.from(conLai);
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Container(
              height: MediaQuery.sizeOf(ctx).height * 0.72,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_blue, _blueSoft],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.inventory_2_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chọn vật tư',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              if (excludeMa.isNotEmpty)
                                Text(
                                  'Đã ẩn ${excludeMa.length} vật tư đã chọn trong bước này — chỉnh số lượng trên dòng có sẵn',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade600,
                                    height: 1.25,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: filter,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên hoặc mã…',
                        prefixIcon:
                        const Icon(Icons.search_rounded, color: _blue),
                        filled: true,
                        fillColor: const Color(0xFFF0F9FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) {
                        final q = v.trim().toLowerCase();
                        setModal(() {
                          list = conLai
                              .where((e) =>
                          e.tenVatTu.toLowerCase().contains(q) ||
                              e.maVatTu.toString().contains(q))
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Không còn vật tư phù hợp.\n'
                              'Tăng số lượng trên dòng đã chọn trong bước này.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade600, height: 1.35),
                        ),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration:
                          Duration(milliseconds: 220 + (i % 8) * 30),
                          curve: Curves.easeOutCubic,
                          builder: (context, t, child) => Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - t)),
                              child: child,
                            ),
                          ),
                          child: Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side:
                              BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor:
                                _blue.withValues(alpha: 0.12),
                                child: Text(
                                  '${e.maVatTu}',
                                  style: const TextStyle(
                                      color: _blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              title: Text(e.tenVatTu,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                'Đơn giá: ${_fmtTien(e.donGia)}'
                                    '${e.donViTinh != null ? ' · ${e.donViTinh}' : ''}',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12.5),
                              ),
                              trailing: const Icon(
                                  Icons.add_circle_rounded,
                                  color: _blue),
                              onTap: () => Navigator.pop(ctx, e),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  /// Tổng tiền mọi vật tư đã chọn trên các bước (logic file).
  int _tinhTongTien() {
    final dong = <({int soLuong, int donGia})>[];
    for (final b in _buoc) {
      for (final d in b.vatTu) {
        final sl = int.tryParse(d.slCtrl.text.trim()) ?? d.soLuong;
        dong.add((soLuong: sl, donGia: d.donGia));
      }
    }
    return QuyTrinhNvktRules.tongTienVatTu(dong);
  }

  Future<void> _xong() async {
    final y = widget.yeuCau;
    if (y.maHoSo == null) return;

    // Chỉ gửi các bước đã tích chọn và đã bấm Xong (không bắt buộc đủ mọi bước)
    final buocGui = _buoc.where((b) => b.daChon && b.daXong).toList();
    if (buocGui.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hãy tích chọn ít nhất 1 bước, chọn vật tư (nếu cần), bấm Xong từng bước rồi hoàn thành quy trình.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    for (final b in buocGui) {
      for (final d in b.vatTu) {
        final kq = validateSoLuongVatTu(
          d.slCtrl.text,
          tenVatTu: d.tenVatTu,
          choPhepRong: false,
        );
        if (!kq.hopLe) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(kq.loi ?? 'Số lượng không hợp lệ'),
              backgroundColor: AppColors.danger,
            ),
          );
          return;
        }
        d.soLuong = kq.soLuong!;
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send_rounded, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _cheDoCapNhat
                    ? 'Gửi lại quy trình?'
                    : 'Hoàn thành quy trình?',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          _cheDoCapNhat
              ? 'Quy trình đã chỉnh sẽ được gửi lại Xưởng để xác nhận.'
              : 'Gửi ${buocGui.length} bước đã hoàn thành (kèm vật tư) về Xưởng xác nhận. Không bắt buộc làm đủ mọi bước.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hoàn thành quy trình'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _dangXuLy = true);
    try {
      final buocApi = <BuocQuyTrinh>[];
      final buffer = StringBuffer();
      for (final b in buocGui) {
        final moTa = b.moTaCtrl.text.trim().isEmpty
            ? 'Bước ${b.soBuoc}'
            : b.moTaCtrl.text.trim();
        final buoc = BuocQuyTrinh(soBuoc: b.soBuoc, moTa: moTa);
        for (final d in b.vatTu) {
          if (d.tenVatTu.isEmpty || d.soLuong <= 0) continue;
          buoc.vatTuList.add(VatTuDong(
            maVatTu: d.maVatTu,
            tenVatTu: d.tenVatTu,
            soLuong: d.soLuong,
            donGia: d.donGia,
          ));
        }
        buocApi.add(buoc);
        buffer.writeln('Bước ${b.soBuoc}: $moTa');
        for (final d in buoc.vatTuList) {
          buffer.writeln('  - ${d.tenVatTu} x ${d.soLuong}');
        }
      }
      final noiDung = _noiDungCtrl.text.trim();
      if (noiDung.isNotEmpty) {
        buffer.writeln('Nội dung công việc: $noiDung');
      }

      final coVatTu = buocApi
          .any((b) => b.vatTuList.any((d) => d.soLuong > 0 && d.tenVatTu.isNotEmpty));
      if (coVatTu) {
        if (_maHoSoVatTu != null) {
          await MaterialUsageService.capNhatHoSoVatTu(
            maHoSoVatTu: _maHoSoVatTu!,
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
            maThietBi: y.maThietBi ?? 0,
            tenThietBi: y.tenThietBi ?? '',
            loaiCongViec: _laBaoTri ? 'Bảo trì' : 'Sửa chữa',
            buoc: buocApi,
          );
        } else {
          final created = await MaterialUsageService.taoHoSoVatTu(
            maHoSoBaoTri: _laBaoTri ? y.maHoSo : null,
            maHoSoSuaChua: _laBaoTri ? null : y.maHoSo,
            maThietBi: y.maThietBi ?? 0,
            tenThietBi: y.tenThietBi ?? '',
            loaiCongViec: _laBaoTri ? 'Bảo trì' : 'Sửa chữa',
            buoc: buocApi,
          );
          _maHoSoVatTu = created?.maHoSoVatTu;
        }
      }

      if (y.maPhanCong != null) {
        try {
          await WorkOrderService.ghiNhanKetQua(
            maPhanCong: y.maPhanCong!,
            maNhanVienGhiNhan: 0,
            ghiChu: buffer.toString().trim(),
            soLieuGhiNhan:
            noiDung.isNotEmpty ? noiDung : buffer.toString().trim(),
          );
        } catch (_) {}
      }

      if (_laBaoTri) {
        await WorkOrderService.nhanVienHoanThanhBaoTri(y.maHoSo!);
      } else {
        await WorkOrderService.nhanVienHoanThanhSuaChua(y.maHoSo!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cheDoCapNhat
              ? 'Đã gửi lại — chờ Xưởng xác nhận'
              : 'Đã gửi — hồ sơ Chờ xác nhận (Xưởng)'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final title = _cheDoCapNhat
        ? 'Cập nhật quy trình'
        : (_laBaoTri ? 'Quy trình bảo trì' : 'Quy trình sửa chữa');
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ===== HEADER =====
          FadeTransition(
            opacity: CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.15),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: _headerAnim, curve: Curves.easeOutCubic)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(8, top + 6, 16, 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_blue, _blueMid, _blueSoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) {
                            final s = 0.92 + 0.08 * _pulseAnim.value;
                            return Transform.scale(
                              scale: s,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  '${_buoc.length} bước',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8, top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.precision_manufacturing_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.yeuCau.tenThietBi ?? 'Thiết bị',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_cheDoCapNhat)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 10, right: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Xưởng đã từ chối — chỉnh bước / vật tư rồi gửi lại',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ===== BODY =====
          Expanded(
            child: _dangTai
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                        color: _blue, strokeWidth: 3),
                  ),
                  SizedBox(height: 14),
                  Text('Đang tải quy trình…',
                      style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
                : _loi != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(_loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _tai,
                      style: FilledButton.styleFrom(
                          backgroundColor: _blue),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
                : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                // Hint card
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - t)),
                      child: child,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _blue.withValues(alpha: 0.08),
                          _blueSoft.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _blue.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _blue.withValues(alpha: 0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.tips_and_updates_rounded,
                              color: _blue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tự thêm bước & vật tư. Đơn giá lấy từ hệ thống (không sửa). '
                                'Không bắt buộc làm đủ mọi bước khi bấm Xong.',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Steps
                ...List.generate(
                  _buoc.length,
                      (i) => _buildBuocCard(i),
                ),

                const SizedBox(height: 4),
                // Bước lấy từ quy trình thiết bị — không thêm thủ công
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _blue.withValues(alpha: 0.15)),
                  ),
                  child: const Text(
                    'Tích chọn bước cần làm → chọn vật tư (đã chọn sẽ ẩn trong bước) → bấm Xong từng bước. Không bắt buộc đủ mọi bước.',
                    style: TextStyle(fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 22),
                const Text(
                  'Nội dung công việc',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _noiDungCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                      'Mô tả công việc đã làm / ghi chú gửi Xưởng…',
                      hintStyle:
                      TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== BOTTOM: Tổng tiền + Hoàn thành quy trình =====
          if (!_dangTai && _loi == null)
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded,
                            color: Color(0xFF059669), size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tổng tiền vật tư',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                        Text(
                          _fmtTien(_tinhTongTien()),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [_blue, _blueMid, _blueSoft],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _dangXuLy ? null : _xong,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _dangXuLy
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white),
                            )
                                : Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  _cheDoCapNhat
                                      ? 'Lưu & gửi lại Xưởng'
                                      : 'Hoàn thành quy trình',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _buildBuocCard(int index) {
    final b = _buoc[index];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0F2FE)),
          boxShadow: [
            BoxShadow(
              color: _blue.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _blue.withValues(alpha: 0.12),
                    _blueSoft.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: b.daChon,
                    activeColor: _blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: !QuyTrinhNvktRules.coTheDoiCheckbox(
                      daXong: b.daXong,
                      khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                      cheDoCapNhat: _cheDoCapNhat,
                      dangXuLy: _dangXuLy,
                    )
                        ? null
                        : (v) async {
                      // Chỉ tích chọn local — không claim DangLam (tránh khóa sớm).
                      // Khóa chỉ khi bấm Xong (DaXong trên server).
                      if (v == true) {
                        // Nếu bước đã DaXong bởi người khác → API/sync sẽ khóa
                        await _dongBoTienDo(silent: true);
                        if (b.khoaBoiNguoiKhac) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  QuyTrinhNvktRules.goiYChuaChonBuoc(
                                    khoaBoiNguoiKhac: true,
                                    daXong: true,
                                    tenNguoiGiu: b.tenNguoiGiu,
                                  ),
                                ),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                          return;
                        }
                        setState(() {
                          b.daChon = true;
                          b.moRong = true;
                          b.tenNguoiGiu = _tenToi;
                        });
                      } else {
                        if (!QuyTrinhNvktRules.coTheBoTich(
                          daXong: b.daXong,
                          cheDoCapNhat: _cheDoCapNhat,
                        )) {
                          return;
                        }
                        setState(() {
                          b.daChon = false;
                          b.moRong = false;
                        });
                      }
                    },
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: b.daXong
                            ? [AppColors.success, const Color(0xFF34D399)]
                            : const [_blue, _blueSoft],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: b.daXong
                        ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18)
                        : Text(
                      '${b.soBuoc}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      QuyTrinhNvktRules.tieuDeBuoc(
                        soBuoc: b.soBuoc,
                        daXong: b.daXong,
                        dangLam: b.daChon && !b.daXong,
                        tenNguoiThucHien: b.tenNguoiGiu,
                      ),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                  if (b.vatTu.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${b.vatTu.length} VT',
                        style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    b.moTaCtrl.text.trim().isEmpty
                        ? 'Bước ${b.soBuoc}'
                        : b.moTaCtrl.text.trim(),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (b.daChon) ...[
                    const SizedBox(height: 12),
                    ...List.generate(b.vatTu.length, (j) {
                      final d = b.vatTu[j];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.inventory_2_rounded,
                                    size: 18, color: _blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    d.tenVatTu,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 13.5),
                                  ),
                                ),
                                if (_coTheSuaVatTu(b))
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => setState(() {
                                      d.dispose();
                                      b.vatTu.removeAt(j);
                                    }),
                                    icon:
                                    const Icon(Icons.close_rounded, size: 18),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: d.slCtrl,
                                    enabled: _coTheSuaVatTu(b),
                                    readOnly: !_coTheSuaVatTu(b),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      FilteringTextInputFormatter.allow(
                                        soLuongVatTuChoPhepNhap,
                                      ),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Số lượng',
                                      hintText: 'Số nguyên > 0',
                                      errorText: _coTheSuaVatTu(b)
                                          ? formValidateSoLuongVatTu(
                                        d.slCtrl.text,
                                        tenVatTu: d.tenVatTu,
                                        choPhepRong: true,
                                      )
                                          : null,
                                      isDense: true,
                                      filled: true,
                                      fillColor: _coTheSuaVatTu(b)
                                          ? Colors.white
                                          : const Color(0xFFF1F5F9),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                    ),
                                    onChanged: !_coTheSuaVatTu(b)
                                        ? null
                                        : (v) {
                                      final kq = validateSoLuongVatTu(
                                        v,
                                        tenVatTu: d.tenVatTu,
                                        choPhepRong: true,
                                      );
                                      d.soLuong = kq.soLuong ?? 0;
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: 'Đơn giá',
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                    ),
                                    child: Text(
                                      _fmtTien(d.donGia),
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_coTheSuaVatTu(b))
                      TextButton.icon(
                        onPressed: () => _themVatTu(index),
                        icon: const Icon(Icons.add_box_outlined,
                            size: 20, color: _blue),
                        label: const Text(
                          'Thêm vật tư',
                          style: TextStyle(
                              color: _blue, fontWeight: FontWeight.w700),
                        ),
                      ),
                    if (QuyTrinhNvktRules.ghiChuBuocDaXong(
                      daXong: b.daXong,
                      khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                      cheDoCapNhat: _cheDoCapNhat,
                      tenNguoiGiu: b.tenNguoiGiu,
                    ) !=
                        null) ...[
                      const SizedBox(height: 6),
                      Text(
                        QuyTrinhNvktRules.ghiChuBuocDaXong(
                          daXong: b.daXong,
                          khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                          cheDoCapNhat: _cheDoCapNhat,
                          tenNguoiGiu: b.tenNguoiGiu,
                        )!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (!b.khoaBoiNguoiKhac)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: !QuyTrinhNvktRules.coTheBamXong(
                            daXong: b.daXong,
                            khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                            cheDoCapNhat: _cheDoCapNhat,
                            dangXuLy: _dangXuLy,
                          )
                              ? null
                              : () => _luuBuocDaXong(b),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                            b.daXong ? AppColors.success : _blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            b.daXong
                                ? Icons.check_circle_rounded
                                : Icons.done_all_rounded,
                            size: 18,
                          ),
                          label: Text(
                            QuyTrinhNvktRules.nhanNutXong(
                              daXong: b.daXong,
                              cheDoCapNhat: _cheDoCapNhat,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        QuyTrinhNvktRules.goiYChuaChonBuoc(
                          khoaBoiNguoiKhac: b.khoaBoiNguoiKhac,
                          daXong: b.daXong,
                          tenNguoiGiu: b.tenNguoiGiu,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
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
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, this.radius = 12});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const dash = 6.0;
    const gap = 4.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = dist + dash;
        canvas.drawPath(
          metric.extractPath(dist, next > metric.length ? metric.length : next),
          paint,
        );
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BuocState {
  int soBuoc;
  final TextEditingController moTaCtrl;
  final List<_VatTuDongState> vatTu;
  /// NVKT tích chọn bước sẽ thực hiện
  bool daChon;
  /// Đã bấm Xong trong bước
  bool daXong;
  /// Mở rộng chọn vật tư
  bool moRong;
  /// Người khác đang giữ / đã xong bước này
  bool khoaBoiNguoiKhac;
  String? tenNguoiGiu;

  _BuocState({required this.soBuoc, required String moTa})
      : moTaCtrl = TextEditingController(text: moTa),
        vatTu = [],
        daChon = false,
        daXong = false,
        moRong = false,
        khoaBoiNguoiKhac = false;

  void dispose() {
    moTaCtrl.dispose();
    for (final v in vatTu) {
      v.dispose();
    }
  }
}

class _VatTuDongState {
  final int? maVatTu;
  final String tenVatTu;
  int soLuong;
  final int donGia;
  final TextEditingController slCtrl;

  _VatTuDongState({
    this.maVatTu,
    required this.tenVatTu,
    required this.soLuong,
    required this.donGia,
  }) : slCtrl = TextEditingController(text: soLuong.toString());

  void dispose() => slCtrl.dispose();
}