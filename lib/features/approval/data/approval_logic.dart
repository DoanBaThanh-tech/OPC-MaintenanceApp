import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../work_order/data/services/material_usage_service.dart';
import '../../work_order/data/services/work_order_service.dart';

// ============================================================
// MODEL
// ============================================================

/// Một dòng vật tư trong bước (GĐ đối chiếu hồ sơ vật tư).
class VatTuBuocDuyet {
  final String tenVatTu;
  final int soLuong;
  final int donGia;

  const VatTuBuocDuyet({
    required this.tenVatTu,
    required this.soLuong,
    this.donGia = 0,
  });

  int get thanhTien => soLuong * donGia;
}

/// Bước quy trình trên hồ sơ duyệt (GĐ xem đủ bước chọn + chưa chọn).
class BuocQuyTrinhDuyet {
  final int soBuoc;
  final String moTa;
  final String trangThai;
  final String? tenNhanVien;
  /// null = suy từ trangThai; true/false = gộp từ mẫu thiết bị.
  final bool? daChonFlag;
  final List<VatTuBuocDuyet> vatTu;

  const BuocQuyTrinhDuyet({
    required this.soBuoc,
    required this.moTa,
    required this.trangThai,
    this.tenNhanVien,
    this.daChonFlag,
    this.vatTu = const [],
  });

  bool get daThucHien {
    final t = trangThai.toLowerCase();
    return t.contains('hoàn thành') ||
        t.contains('đã thực hiện') ||
        t == 'dathuchien' ||
        t == 'done';
  }

  bool get daChon {
    if (daChonFlag != null) return daChonFlag!;
    final t = trangThai.toLowerCase();
    return daThucHien ||
        t.contains('chọn') ||
        t == 'duocchon' ||
        t == 'được chọn' ||
        t.isNotEmpty;
  }

  /// Nhãn trạng thái dễ đọc cho giám đốc.
  String get nhanTrangThai {
    if (!daChon) return 'Không chọn';
    final t = trangThai.trim();
    if (t.isEmpty) return 'Đã chọn — chưa làm';
    final low = t.toLowerCase();
    if (low.contains('hoàn thành') ||
        low == 'dathuchien' ||
        low.contains('đã thực hiện')) {
      return 'Đã thực hiện';
    }
    if (low.contains('đang')) return 'Đang thực hiện';
    if (low.contains('chọn') || low == 'duocchon') return 'Đã chọn — chưa làm';
    if (low.contains('bỏ') || low.contains('không')) return 'Không chọn';
    return t;
  }

  factory BuocQuyTrinhDuyet.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    return BuocQuyTrinhDuyet(
      soBuoc: n(j['soBuoc'] ?? j['SoBuoc']),
      moTa: (j['moTaBuoc'] ?? j['MoTaBuoc'] ?? j['moTa'] ?? j['MoTa'] ?? '')
          .toString(),
      trangThai: (j['trangThai'] ?? j['TrangThai'] ?? '').toString(),
      tenNhanVien: (j['tenNhanVien'] ?? j['TenNhanVien'])?.toString(),
      daChonFlag: true, // bước từ hồ sơ = đã được tổ trưởng chọn
      vatTu: const [],
    );
  }
}

class HoSoBaoTriDuyet {
  final int maHoSoBaoTri;
  final int? maThietBi;
  final String tenThietBi;
  final String? tenNguoiLap;
  final String? noiDungCongViec;
  final String? thoiGianDuKien;
  final String? gioBatDauDuKien;
  final String? gioKetThucDuKien;
  final DateTime? ngayDuKienBaoTri;
  final DateTime ngayTao;
  final String trangThai;
  final String? lyDoTuChoi;
  final String? rowVersion;
  final int nam;
  final bool namTuKeHoach;
  final List<BuocQuyTrinhDuyet> danhSachBuocQuyTrinh;

  HoSoBaoTriDuyet({
    required this.maHoSoBaoTri,
    this.maThietBi,
    required this.tenThietBi,
    this.tenNguoiLap,
    this.noiDungCongViec,
    this.thoiGianDuKien,
    this.gioBatDauDuKien,
    this.gioKetThucDuKien,
    this.ngayDuKienBaoTri,
    required this.ngayTao,
    required this.trangThai,
    this.lyDoTuChoi,
    this.rowVersion,
    required this.nam,
    required this.namTuKeHoach,
    this.danhSachBuocQuyTrinh = const [],
  });

  /// Giám đốc chỉ thấy hồ sơ khi Xưởng đã gửi (Chờ GĐ duyệt).
  /// «Chờ duyệt» = đang ở Xưởng, chưa gửi GĐ — không hiện bên Giám đốc.
  bool get choDuyet => trangThai == 'Chờ GĐ duyệt';
  bool get daDuyet => trangThai == 'Đã duyệt';
  bool get dangThucHien =>
      trangThai == 'Đang thực hiện' || trangThai == 'Chờ xác nhận';
  bool get daHoanThanh => trangThai == 'Đã hoàn thành';
  bool get biTuChoi => trangThai == 'Từ chối';

  factory HoSoBaoTriDuyet.fromJson(Map<String, dynamic> j) {
    final rawBuoc = j['danhSachBuocQuyTrinh'] ?? j['DanhSachBuocQuyTrinh'];
    final buoc = <BuocQuyTrinhDuyet>[];
    if (rawBuoc is List) {
      for (final e in rawBuoc) {
        if (e is Map) {
          buoc.add(BuocQuyTrinhDuyet.fromJson(Map<String, dynamic>.from(e)));
        }
      }
      buoc.sort((a, b) => a.soBuoc.compareTo(b.soBuoc));
    }
    return HoSoBaoTriDuyet(
      maHoSoBaoTri: (j['maHoSoBaoTri'] as num?)?.toInt() ?? 0,
      maThietBi: (j['maThietBi'] as num?)?.toInt() ??
          (j['MaThietBi'] as num?)?.toInt(),
      tenThietBi: j['tenThietBi']?.toString() ?? '',
      tenNguoiLap: j['tenNhanVienTao']?.toString(),
      noiDungCongViec: j['noiDungCongViec']?.toString(),
      thoiGianDuKien: j['thoiGianDuKien']?.toString(),
      gioBatDauDuKien: j['gioBatDauDuKien']?.toString(),
      gioKetThucDuKien: j['gioKetThucDuKien']?.toString(),
      ngayDuKienBaoTri: j['ngayDuKienBaoTri'] != null
          ? DateTime.tryParse(j['ngayDuKienBaoTri'].toString())
          : null,
      ngayTao: DateTime.parse(j['ngayTao'].toString()),
      trangThai: j['trangThai']?.toString() ?? '',
      lyDoTuChoi: j['lyDoTuChoi']?.toString(),
      rowVersion: j['rowVersion']?.toString(),
      nam: (j['nam'] as num?)?.toInt() ?? DateTime.now().year,
      namTuKeHoach: j['namTuKeHoach'] == true,
      danhSachBuocQuyTrinh: buoc,
    );
  }
}

class LichSuPheDuyetItem {
  final int maPheDuyet;
  final String loai;
  final int? maHoSo;
  final String? tenThietBi;
  final String? tenNguoiLap;
  final String? noiDung;
  final String? tenNguoiDuyet;
  final String quyetDinh;
  final String trangThaiHoSo;
  final String? lyDo;
  final DateTime ngayDuyet;
  final int nam;

  LichSuPheDuyetItem({
    required this.maPheDuyet,
    required this.loai,
    this.maHoSo,
    this.tenThietBi,
    this.tenNguoiLap,
    this.noiDung,
    this.tenNguoiDuyet,
    required this.quyetDinh,
    required this.trangThaiHoSo,
    this.lyDo,
    required this.ngayDuyet,
    required this.nam,
  });

  bool get daDuyet => trangThaiHoSo == 'Đã duyệt' || quyetDinh == 'Duyệt';
  bool get tuChoi => trangThaiHoSo == 'Từ chối' || quyetDinh == 'Từ chối';

  factory LichSuPheDuyetItem.fromJson(Map<String, dynamic> j) {
    DateTime? asDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    final ngay = asDate(j['ngayDuyet']) ?? DateTime.now();
    return LichSuPheDuyetItem(
      maPheDuyet: (j['maPheDuyet'] as num?)?.toInt() ?? 0,
      loai: j['loai']?.toString() ?? 'Bảo trì',
      maHoSo: (j['maHoSo'] as num?)?.toInt(),
      tenThietBi: j['tenThietBi']?.toString(),
      tenNguoiLap: j['tenNguoiLap']?.toString(),
      noiDung: j['noiDung']?.toString(),
      tenNguoiDuyet: j['tenNguoiDuyet']?.toString(),
      quyetDinh: j['quyetDinh']?.toString() ?? '',
      trangThaiHoSo: j['trangThaiHoSo']?.toString() ?? '',
      lyDo: j['lyDo']?.toString(),
      ngayDuyet: ngay,
      nam: (j['nam'] as num?)?.toInt() ?? ngay.year,
    );
  }
}

// ============================================================
// SERVICE
// ============================================================

class ApprovalService {
  static Future<List<HoSoBaoTriDuyet>> layDanhSachBaoTri({String? trangThai}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/bao-tri',
      query: trangThai != null ? {'trangThai': trangThai} : null,
    );
    return data
        .map((e) => HoSoBaoTriDuyet.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<HoSoBaoTriDuyet> layChiTietBaoTri(int id) async {
    final data = await ApiClient.instance
        .get<Map<String, dynamic>>('${ApiConstants.workOrder}/bao-tri/$id');
    return HoSoBaoTriDuyet.fromJson(data);
  }

  static Future<void> duyetBaoTri({
    required int maHoSoBaoTri,
    required String quyetDinh,
    String? lyDo,
    required String rowVersion,
  }) async {
    await ApiClient.instance.put<Map<String, dynamic>>(
      '${ApiConstants.workOrder}/bao-tri/$maHoSoBaoTri/duyet',
      {
        'quyetDinh': quyetDinh,
        'lyDo': lyDo,
        'rowVersion': rowVersion,
      },
    );
  }

  static Future<List<LichSuPheDuyetItem>> layLichSuPheDuyet({
    String? loai,
    int? nam,
  }) async {
    final query = <String, dynamic>{};
    if (loai != null) query['loai'] = loai;
    if (nam != null) query['nam'] = nam;
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/lich-su-phe-duyet',
      query: query.isEmpty ? null : query,
    );
    return data
        .map((e) =>
        LichSuPheDuyetItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<int>> layNamCoLichSu({String? loai}) async {
    final data = await ApiClient.instance.get<List<dynamic>>(
      '${ApiConstants.workOrder}/lich-su-phe-duyet/nam',
      query: loai != null ? {'loai': loai} : null,
    );
    return data.map((e) => (e as num).toInt()).toList();
  }
}

// ============================================================
// CONTROLLERS
// ============================================================

class ApprovalBaoTriListController extends ChangeNotifier {
  List<HoSoBaoTriDuyet> _tatCa = [];
  bool dangTai = true;
  String? loi;
  int? namLoc;

  /// Toàn bộ hồ sơ GĐ theo dõi (từ chờ duyệt → hoàn thành), có thể lọc năm.
  List<HoSoBaoTriDuyet> get danhSach {
    final base =
    namLoc == null ? _tatCa : _tatCa.where((h) => h.nam == namLoc).toList();
    // Ưu tiên: chờ duyệt → đang làm → đã duyệt → hoàn thành → từ chối
    int rank(HoSoBaoTriDuyet h) {
      if (h.choDuyet) return 0;
      if (h.dangThucHien) return 1;
      if (h.daDuyet) return 2;
      if (h.daHoanThanh) return 3;
      if (h.biTuChoi) return 4;
      return 5;
    }

    final list = List<HoSoBaoTriDuyet>.from(base);
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return b.ngayTao.compareTo(a.ngayTao);
    });
    return list;
  }

  List<HoSoBaoTriDuyet> get choDuyet =>
      danhSach.where((h) => h.choDuyet).toList();
  List<HoSoBaoTriDuyet> get dangTheoDoi => danhSach
      .where((h) => h.daDuyet || h.dangThucHien || h.daHoanThanh || h.biTuChoi)
      .toList();

  List<int> get cacNamCoDuLieu {
    final nams = _tatCa.map((h) => h.nam).toSet().toList();
    nams.sort((a, b) => b.compareTo(a));
    return nams;
  }

  Future<void> taiDanhSachChoDuyet() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      // Không lọc mất hồ sơ đã duyệt — GĐ theo dõi đến khi hoàn thành
      final all = await ApprovalService.layDanhSachBaoTri();
      _tatCa = all
          .where((h) =>
      h.choDuyet ||
          h.daDuyet ||
          h.dangThucHien ||
          h.daHoanThanh ||
          h.biTuChoi)
          .toList();
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void datNamLoc(int? nam) {
    namLoc = nam;
    notifyListeners();
  }
}

class ApprovalBaoTriDetailController extends ChangeNotifier {
  final int maHoSoBaoTri;
  ApprovalBaoTriDetailController(this.maHoSoBaoTri);

  HoSoBaoTriDuyet? hoSo;
  /// Đủ bước mẫu BT (kể cả bước tổ trưởng không chọn).
  List<BuocQuyTrinhDuyet> dsBuocDayDu = [];
  bool dangTai = true;
  bool dangXuLy = false;
  String? loi;

  Future<void> taiChiTiet() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      hoSo = await ApprovalService.layChiTietBaoTri(maHoSoBaoTri);
      await _gopBuocDayDu();
    } catch (e) {
      loi = 'Lỗi tải dữ liệu: $e';
      dsBuocDayDu = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  /// Gộp quy trình mẫu thiết bị + bước đã chọn + vật tư (khi hoàn thành).
  Future<void> _gopBuocDayDu() async {
    final hs = hoSo;
    if (hs == null) {
      dsBuocDayDu = [];
      return;
    }
    final selected = <int, BuocQuyTrinhDuyet>{
      for (final b in hs.danhSachBuocQuyTrinh) b.soBuoc: b,
    };
    final vtTheoBuoc = <int, List<VatTuBuocDuyet>>{};

    List<VatTuBuocDuyet> parseJsonVt(String? raw) {
      if (raw == null || raw.trim().isEmpty) return const [];
      try {
        final arr = jsonDecode(raw);
        if (arr is! List) return const [];
        final out = <VatTuBuocDuyet>[];
        for (final item in arr) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final ten = (m['tenVatTu'] ?? m['TenVatTu'] ?? '').toString().trim();
          final sl = (m['soLuong'] as num?)?.toInt() ?? 0;
          final dg = (m['donGia'] as num?)?.toInt() ?? 0;
          if (ten.isEmpty || sl <= 0) continue;
          out.add(VatTuBuocDuyet(tenVatTu: ten, soLuong: sl, donGia: dg));
        }
        return out;
      } catch (_) {
        return const [];
      }
    }

    // Tiến độ bước + JsonVatTu
    try {
      final tienDo = await WorkOrderService.layTienDoBuoc(
        maHoSoBaoTri: hs.maHoSoBaoTri,
      );
      for (final m in tienDo) {
        final so = (m['soBuoc'] as num?)?.toInt() ??
            (m['SoBuoc'] as num?)?.toInt() ??
            0;
        if (so <= 0) continue;
        final moTa = (m['moTaBuoc'] ?? m['MoTaBuoc'] ?? m['moTa'] ?? '')
            .toString();
        final tt = (m['trangThai'] ?? m['TrangThai'] ?? '').toString();
        final ten = (m['tenNhanVien'] ?? m['TenNhanVien'])?.toString();
        final jsonVt = (m['jsonVatTu'] ?? m['JsonVatTu'])?.toString();
        final vt = parseJsonVt(jsonVt);
        if (vt.isNotEmpty) vtTheoBuoc[so] = vt;
        selected[so] = BuocQuyTrinhDuyet(
          soBuoc: so,
          moTa: moTa.isNotEmpty ? moTa : (selected[so]?.moTa ?? ''),
          trangThai: tt.isNotEmpty ? tt : (selected[so]?.trangThai ?? ''),
          tenNhanVien: ten ?? selected[so]?.tenNhanVien,
          daChonFlag: true,
          vatTu: vt.isNotEmpty ? vt : (selected[so]?.vatTu ?? const []),
        );
      }
    } catch (_) {}

    // Hồ sơ vật tư theo công việc (đối chiếu GĐ) — ưu tiên nếu có
    try {
      final hsVt = await MaterialUsageService.layHoSoTheoCongViec(
        maHoSoBaoTri: hs.maHoSoBaoTri,
      );
      if (hsVt != null) {
        final fromHs = <int, List<VatTuBuocDuyet>>{};
        for (final c in hsVt.chiTiet) {
          if (c.tenVatTu.trim().isEmpty || c.soLuong <= 0) continue;
          fromHs.putIfAbsent(c.soBuoc, () => []).add(VatTuBuocDuyet(
            tenVatTu: c.tenVatTu,
            soLuong: c.soLuong,
            donGia: c.donGia,
          ));
        }
        for (final e in fromHs.entries) {
          vtTheoBuoc[e.key] = e.value;
          final old = selected[e.key];
          if (old != null) {
            selected[e.key] = BuocQuyTrinhDuyet(
              soBuoc: old.soBuoc,
              moTa: old.moTa,
              trangThai: old.trangThai,
              tenNhanVien: old.tenNhanVien,
              daChonFlag: true,
              vatTu: e.value,
            );
          } else {
            selected[e.key] = BuocQuyTrinhDuyet(
              soBuoc: e.key,
              moTa: '',
              trangThai: 'DaXong',
              daChonFlag: true,
              vatTu: e.value,
            );
          }
        }
      }
    } catch (_) {}

    List<BuocQuyTrinhDuyet> mau = [];
    final maTb = hs.maThietBi ?? 0;
    if (maTb > 0) {
      try {
        final ds = await MaterialUsageService.layQuyTrinhThietBi(
          maThietBi: maTb,
          loaiCongViec: 'Bảo trì',
        );
        mau = ds
            .map((b) => BuocQuyTrinhDuyet(
          soBuoc: b.soBuoc,
          moTa: b.moTa,
          trangThai: '',
          daChonFlag: false,
        ))
            .toList();
      } catch (_) {}
    }

    if (mau.isEmpty) {
      dsBuocDayDu = selected.values.map((b) {
        final vt = vtTheoBuoc[b.soBuoc] ?? b.vatTu;
        return BuocQuyTrinhDuyet(
          soBuoc: b.soBuoc,
          moTa: b.moTa,
          trangThai: b.trangThai,
          tenNhanVien: b.tenNhanVien,
          daChonFlag: b.daChonFlag ?? true,
          vatTu: vt,
        );
      }).toList()
        ..sort((a, b) => a.soBuoc.compareTo(b.soBuoc));
      return;
    }

    final out = <BuocQuyTrinhDuyet>[];
    final used = <int>{};
    for (final m in mau) {
      final s = selected[m.soBuoc];
      used.add(m.soBuoc);
      final vt = vtTheoBuoc[m.soBuoc] ?? s?.vatTu ?? const [];
      if (s != null) {
        out.add(BuocQuyTrinhDuyet(
          soBuoc: m.soBuoc,
          moTa: s.moTa.trim().isNotEmpty ? s.moTa : m.moTa,
          trangThai: s.trangThai,
          tenNhanVien: s.tenNhanVien,
          daChonFlag: true,
          vatTu: vt,
        ));
      } else {
        out.add(BuocQuyTrinhDuyet(
          soBuoc: m.soBuoc,
          moTa: m.moTa,
          trangThai: '',
          daChonFlag: false,
          vatTu: vt,
        ));
      }
    }
    for (final e in selected.entries) {
      if (!used.contains(e.key)) {
        final vt = vtTheoBuoc[e.key] ?? e.value.vatTu;
        out.add(BuocQuyTrinhDuyet(
          soBuoc: e.value.soBuoc,
          moTa: e.value.moTa,
          trangThai: e.value.trangThai,
          tenNhanVien: e.value.tenNhanVien,
          daChonFlag: e.value.daChonFlag ?? true,
          vatTu: vt,
        ));
      }
    }
    out.sort((a, b) => a.soBuoc.compareTo(b.soBuoc));
    dsBuocDayDu = out;
  }

  Future<bool> xuLy({required String quyetDinh, String? lyDo}) async {
    if (hoSo?.rowVersion == null) {
      loi = 'Thiếu dữ liệu đồng bộ, vui lòng tải lại hồ sơ.';
      notifyListeners();
      return false;
    }
    if (quyetDinh == 'Từ chối' && (lyDo == null || lyDo.trim().isEmpty)) {
      loi = 'Vui lòng nhập lý do từ chối.';
      notifyListeners();
      return false;
    }
    dangXuLy = true;
    loi = null;
    notifyListeners();
    try {
      await ApprovalService.duyetBaoTri(
        maHoSoBaoTri: maHoSoBaoTri,
        quyetDinh: quyetDinh,
        lyDo: lyDo,
        rowVersion: hoSo!.rowVersion!,
      );
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } finally {
      dangXuLy = false;
      notifyListeners();
    }
  }
}

class LichSuPheDuyetController extends ChangeNotifier {
  List<LichSuPheDuyetItem> danhSach = [];
  List<int> cacNam = [];
  bool dangTai = true;
  String? loi;
  String tabLoai = 'Bảo trì';
  int? namLoc;

  Future<void> tai() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        ApprovalService.layLichSuPheDuyet(loai: tabLoai, nam: namLoc),
        ApprovalService.layNamCoLichSu(loai: tabLoai),
      ]);
      danhSach = results[0] as List<LichSuPheDuyetItem>;
      cacNam = results[1] as List<int>;
    } catch (e) {
      loi = 'Không tải được lịch sử: $e';
      danhSach = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void doiTab(String loai) {
    if (tabLoai == loai) return;
    tabLoai = loai;
    namLoc = null;
    tai();
  }

  void datNam(int? nam) {
    namLoc = nam;
    tai();
  }
}